#!/usr/bin/env python3
"""Capture tool for the Bland-Altman counting-agreement study (insect node).

Captures one sample every 15 minutes by default, records the detector's count
at several confidence thresholds from a single inference pass, and draws
bounding boxes on a marked copy of each frame.

Standalone: it opens the IMX500 and the lux sensor itself, so insect_node.py
must be stopped while this runs. No LoRa involved.

    python3 bland_altman_capture.py --test     ONE frame, then exit — do this
                                               first, to check boxes land right
    python3 bland_altman_capture.py            30 samples, 15 minutes apart
    python3 bland_altman_capture.py --manual   press Enter for each sample
    python3 bland_altman_capture.py --interval 300 --samples 48

Run the real campaign under tmux so a dropped session does not kill it:

    tmux new -s ba
    python3 bland_altman_capture.py
    (Ctrl-B then D detaches; tmux attach -t ba comes back)

BOX COORDINATES ARE SELF-CALIBRATING. Different IMX500 model packages return
detection boxes in different conventions: normalised or in 640-pixel inference
space, and corner-ordered (y0,x0,y1,x1) or (x0,y0,x1,y1). On the first frame
this script tries every combination, keeps whichever yields the most boxes that
are actually valid — positive area, inside the frame, not absurdly large — and
reports which convention won. It then uses that one for the rest of the run.

WHAT IT WRITES PER SAMPLE

    frame_0001_clean.jpg    what the sensor saw: no boxes, no numbers
    frame_0001_marked.jpg   boxes colour-banded by confidence, with a legend
                            and the per-threshold counts in the strip
    counts.csv              counts at every threshold, lux, blank manual_count

WHY THE CLEAN IMAGE EXISTS. You count from it. If you count from a picture that
already carries the machine's boxes, your count is anchored to the machine's
answer and the agreement analysis flatters itself. Nothing on the clean frame,
or in its filename, reveals what the detector decided.

AFTERWARDS
    1. cd captures_ba && python3 -m http.server 8000   then count the
       *_clean.jpg frames by eye from a laptop
    2. fill the manual_count column in counts.csv
    3. compare thresholds:
         python3 bland_altman.py counts.csv --column count_0.30
         python3 bland_altman.py counts.csv --column count_0.40
         python3 bland_altman.py counts.csv --column count_0.50

The script resumes: run it again and it continues the frame numbering.
"""
import argparse
import csv
import os
import sys
import time
from datetime import datetime, timedelta

import numpy as np

# ----------------------------- configuration -----------------------------
MODEL          = "/home/ern/models/network.rpk"
OUT_DIR        = "/home/ern/captures_ba"

INTERVAL_S     = 900           # 15 minutes between captures
SAMPLES        = 30

THRESHOLDS     = [0.30, 0.40, 0.50]
PRIMARY        = 0.40          # the deployed node's threshold

LUX_ADDR       = 0x23
LUX_BUS        = 1
JPEG_QUALITY   = 92
MIN_FREE_MB    = 500
WARMUP_S       = 2.0
STRIP_H        = 58
SWAP_RB        = True          # picamera2 hands back BGR despite "RGB888"

BAND_HIGH = (230, 40, 40)      # score >= top threshold
BAND_MID  = (205, 60, 220)     # between the top two
BAND_LOW  = (40, 185, 235)     # between the bottom two
BOX_WIDTH = 6
# -------------------------------------------------------------------------

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    sys.exit("Pillow missing:  sudo apt install -y python3-pil")

try:
    from picamera2 import Picamera2
    from picamera2.devices import IMX500
except ImportError:
    sys.exit("picamera2 missing:  sudo apt install -y python3-picamera2")

try:
    from smbus2 import SMBus, i2c_msg
    _HAVE_I2C = True
except ImportError:
    _HAVE_I2C = False


def col(t):
    return "count_%.2f" % t


def band_colour(score, thresholds):
    ts = sorted(thresholds)
    if score >= ts[-1]:
        return BAND_HIGH
    if len(ts) >= 2 and score >= ts[-2]:
        return BAND_MID
    return BAND_LOW


class Lux:
    def __init__(self, bus=LUX_BUS, addr=LUX_ADDR):
        self.addr = addr
        self.bus = None
        if not _HAVE_I2C:
            print("smbus2 not installed — lux will be blank")
            return
        try:
            self.bus = SMBus(bus)
            self.bus.write_byte(addr, 0x01); time.sleep(0.05)
            self.bus.write_byte(addr, 0x10); time.sleep(0.20)
        except Exception as exc:
            print("lux sensor unavailable (%s)" % exc)
            self.bus = None

    def read(self):
        if self.bus is None:
            return None
        try:
            rd = i2c_msg.read(self.addr, 2)
            self.bus.i2c_rdwr(rd)
            d = list(rd)
            return ((d[0] << 8) | d[1]) / 1.2
        except Exception:
            return None

    def close(self):
        if self.bus is not None:
            try:
                self.bus.write_byte(self.addr, 0x00)
                self.bus.close()
            except Exception:
                pass


# ---------------------- detection and box conversion ----------------------
def raw_outputs(imx500, metadata):
    """Return (boxes_raw Nx4, scores N) with any batch dimension removed."""
    try:
        outputs = imx500.get_outputs(metadata, add_batch=True)
    except TypeError:
        outputs = imx500.get_outputs(metadata)
    if outputs is None or len(outputs) < 2:
        return None, None

    b = np.array(outputs[0], dtype=float)
    s = np.array(outputs[1], dtype=float)
    while b.ndim > 2:
        b = b[0]
    while s.ndim > 1:
        s = s[0]
    if b.ndim == 1 and b.size == 4:
        b = b.reshape(1, 4)
    if b.ndim != 2 or b.shape[-1] != 4 or s.size == 0:
        return None, None
    n = min(len(b), len(s))
    return b[:n], s[:n]


def _valid(box, w, h):
    x0, y0, x1, y1 = box
    if not (x1 > x0 and y1 > y0):
        return False
    if x1 < 0 or y1 < 0 or x0 > w or y0 > h:
        return False
    if (x1 - x0) * (y1 - y0) > 0.5 * w * h:
        return False
    return True


def _manual(raw, w, h, order, scale):
    """Scale raw values to frame pixels under one ordering assumption."""
    out = []
    for r in raw:
        a = np.asarray(r, dtype=float)
        if order == "yxyx":
            y0, x0, y1, x1 = a
        else:
            x0, y0, x1, y1 = a
        if scale in ("norm", "input", "letterbox"):
            # the frame is STRETCHED to fill the 640x640 input (no letterbox),
            # verified on hardware 29 Jul: preserve_aspect_ratio is not set
            if max(abs(x0), abs(y0), abs(x1), abs(y1)) > 1.5:
                x0, y0, x1, y1 = (x0/640.0, y0/640.0, x1/640.0, y1/640.0)
            out.append((x0 * w, y0 * h, x1 * w, y1 * h))
        else:
            out.append((x0, y0, x1, y1))
    return out


def _helper(imx500, picam2, metadata, raw):
    """picamera2's own mapping; expects (y0,x0,y1,x1)."""
    out = []
    for r in raw:
        x, y, bw, bh = imx500.convert_inference_coords(
            np.asarray(r, dtype=float), metadata, picam2)
        out.append((float(x), float(y), float(x + bw), float(y + bh)))
    return out


class BoxMapper:
    """Works out once how this model encodes boxes, then applies it.

    Auto-detection reliably distinguishes normalised from 640-pixel values,
    because their magnitudes differ by orders of magnitude. It CANNOT always
    distinguish corner order: for detections near the middle of the frame,
    (y0,x0,y1,x1) and (x0,y0,x1,y1) both yield boxes that sit inside the frame
    with sensible areas. Boxes will simply be in the wrong places. That is what
    --test is for: look at the frame, and if the boxes are displaced, force the
    other order with --order xyxy.
    """

    def __init__(self, force_order=None):
        self.method = None
        self.force_order = force_order if force_order in ("yxyx", "xyxy") else None

    def _candidates(self, imx500, picam2, metadata, raw, w, h):
        cands = []
        if self.force_order is None:
            try:
                cands.append(("picamera2 convert_inference_coords",
                              _helper(imx500, picam2, metadata, raw)))
            except Exception:
                pass
        mx = float(np.max(np.abs(raw))) if raw.size else 0.0
        scales = ["norm"] if mx <= 1.5 else ["input", "pixel"]
        orders = (self.force_order,) if self.force_order else ("yxyx", "xyxy")
        for scale in scales:
            for order in orders:
                try:
                    cands.append(("manual %s/%s" % (order, scale),
                                  _manual(raw, w, h, order, scale)))
                except Exception:
                    pass
        return cands

    def convert(self, imx500, picam2, metadata, raw, w, h, verbose=False):
        cands = self._candidates(imx500, picam2, metadata, raw, w, h)
        if not cands:
            return []

        if self.method is not None:
            for name, boxes in cands:
                if name == self.method:
                    return boxes

        best_name, best_boxes, best_score = None, [], -1
        for name, boxes in cands:
            good = sum(1 for b in boxes if _valid(b, w, h))
            if verbose:
                print("    %-38s %d/%d boxes valid" % (name, good, len(boxes)))
            if good > best_score:
                best_name, best_boxes, best_score = name, boxes, good

        if best_score > 0:
            self.method = best_name
            if verbose:
                print("    -> using: %s" % best_name)
        elif verbose:
            print("    -> no encoding produced valid boxes")
        return best_boxes


# ----------------------------- drawing -----------------------------

def stretch_boxes(raw, w, h):
    """Map model boxes to frame pixels.

    The frame is STRETCHED to fill the 640x640 network input (no letterbox),
    verified on hardware 29 Jul by drawing both candidates. Boxes are xyxy.
    """
    if len(raw) == 0:
        return []
    a = np.asarray(raw, dtype=float)
    if np.max(np.abs(a)) > 1.5:        # 0-640 space -> normalise first
        a = a / 640.0
    return [(float(x0) * w, float(y0) * h, float(x1) * w, float(y1) * h)
            for x0, y0, x1, y1 in a]

def free_mb(path):
    try:
        st = os.statvfs(path)
        return (st.f_bavail * st.f_frsize) / (1024 * 1024)
    except Exception:
        return float("inf")


def _font(size):
    try:
        return ImageFont.truetype(
            "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", size)
    except Exception:
        return ImageFont.load_default()


def draw_boxes(img, boxes, scores, thresholds):
    out = img.copy()
    draw = ImageDraw.Draw(out)
    drawn = 0
    for i, box in enumerate(boxes):
        x0, y0, x1, y1 = box
        x0 = max(0, min(x0, img.width - 1)); x1 = max(0, min(x1, img.width - 1))
        y0 = max(0, min(y0, img.height - 1)); y1 = max(0, min(y1, img.height - 1))
        if x1 <= x0 or y1 <= y0:
            continue
        c = band_colour(scores[i], thresholds) if i < len(scores) else BAND_HIGH
        draw.rectangle([x0, y0, x1, y1], outline=c, width=BOX_WIDTH)
        if i < len(scores):
            draw.text((x0 + 3, max(0, y0 - 13)), "%.2f" % scores[i], fill=c)
        drawn += 1
    return out, drawn


def with_strip(img, line1, legend):
    out = Image.new("RGB", (img.width, img.height + STRIP_H), (24, 24, 24))
    out.paste(img, (0, 0))
    draw = ImageDraw.Draw(out)
    f, fs = _font(19), _font(16)
    draw.text((10, img.height + 6), line1, fill=(235, 235, 235), font=f)
    x, y = 10, img.height + 33
    for colour, text in legend:
        draw.rectangle([x, y + 4, x + 14, y + 16], fill=colour)
        draw.text((x + 20, y), text, fill=(200, 200, 200), font=fs)
        try:
            x += 22 + int(fs.getlength(text)) + 22
        except Exception:
            x += 22 + 9 * len(text) + 22
    return out


def wait(seconds, next_index, last_index):
    due = datetime.now() + timedelta(seconds=seconds)
    if not sys.stdout.isatty():
        print("  next sample (%d of %d) due %s"
              % (next_index, last_index, due.strftime("%H:%M:%S")), flush=True)
        time.sleep(seconds)
        return
    end = time.time() + seconds
    while True:
        left = end - time.time()
        if left <= 0:
            break
        m, s = divmod(int(left), 60)
        print("\r  next sample %d of %d in %02d:%02d (due %s)   "
              % (next_index, last_index, m, s, due.strftime("%H:%M:%S")),
              end="", flush=True)
        time.sleep(min(1.0, left))
    print("\r" + " " * 64 + "\r", end="", flush=True)


# ----------------------------- main -----------------------------
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--test", action="store_true",
                    help="capture ONE frame with diagnostics, then exit")
    ap.add_argument("--interval", type=float, default=INTERVAL_S)
    ap.add_argument("--samples", type=int, default=SAMPLES)
    ap.add_argument("--manual", action="store_true")
    ap.add_argument("--thresholds",
                    default=",".join("%.2f" % t for t in THRESHOLDS))
    ap.add_argument("--out", default=OUT_DIR)
    ap.add_argument("--no-swap", action="store_true",
                    help="disable the red/blue channel swap")
    ap.add_argument("--order", choices=["auto", "yxyx", "xyxy"], default="xyxy",
                    help="force the box corner order if auto-detection picks "
                         "wrong (check with --test first)")
    args = ap.parse_args()

    swap = SWAP_RB and not args.no_swap
    thresholds = sorted(float(t) for t in args.thresholds.split(","))
    floor = min(thresholds)
    primary = PRIMARY if PRIMARY in thresholds else thresholds[0]

    os.makedirs(args.out, exist_ok=True)
    csv_path = os.path.join(args.out, "counts.csv")
    new_csv = not os.path.exists(csv_path)

    start_index = 1
    if not new_csv:
        try:
            with open(csv_path) as fh:
                start_index = len(list(csv.DictReader(fh))) + 1
            print("resuming — %d samples already recorded" % (start_index - 1))
        except Exception:
            pass

    space = free_mb(args.out)
    print("free space: %.0f MB" % space)
    if space < MIN_FREE_MB and not args.test:
        sys.exit("less than %d MB free" % MIN_FREE_MB)

    lux = Lux()
    print("loading model onto the IMX500 (20-30 s)...")
    imx500 = IMX500(MODEL)
    picam2 = Picamera2(imx500.camera_num)
    picam2.start(picam2.create_preview_configuration(
        main={"format": "RGB888", "size": (2028, 1520)}, buffer_count=4), show_preview=False)
    time.sleep(WARMUP_S)

    mapper = BoxMapper(None if args.order == "auto" else args.order)
    print("\nmodel: %s" % MODEL)
    print("thresholds: %s   primary %.2f   swap R/B: %s   box order: %s"
          % (", ".join("%.2f" % t for t in thresholds), primary, swap, args.order))

    if args.test:
        n_samples, mode = 1, "TEST"
    else:
        n_samples = args.samples
        mode = "MANUAL" if args.manual else "TIMED"
        if mode == "TIMED":
            total = args.interval * (args.samples - 1)
            print("TIMED — %d samples every %.0f min, about %.1f h, done near %s"
                  % (args.samples, args.interval / 60.0, total / 3600.0,
                     (datetime.now() + timedelta(seconds=total)).strftime("%H:%M")))
    print("mode: %s\n" % mode)

    header = (["frame_id", "timestamp", "node_count", "max_conf", "lux"]
              + [col(t) for t in thresholds] + ["manual_count"])
    fh = writer = None
    if not args.test:
        fh = open(csv_path, "a", newline="")
        writer = csv.writer(fh)
        if new_csv:
            writer.writerow(header)
            fh.flush()

    taken = 0
    try:
        while taken < n_samples:
            idx = start_index + taken
            if args.manual and not args.test:
                try:
                    input("sample %02d — set the scene, then press Enter: " % idx)
                except EOFError:
                    break
            elif taken > 0:
                wait(args.interval, idx, start_index + n_samples - 1)

            metadata = picam2.capture_metadata()
            frame = picam2.capture_array()
            lx = lux.read()

            if frame.ndim == 3 and frame.shape[2] == 4:
                frame = frame[:, :, :3]
            if swap:
                frame = frame[:, :, ::-1]
            img = Image.fromarray(np.ascontiguousarray(frame.astype(np.uint8)))
            w, h = img.width, img.height

            raw, scores = raw_outputs(imx500, metadata)
            if raw is None:
                print("  no inference output on this frame")
                counts = {t: 0 for t in thresholds}
                boxes, sel_scores, drawn = [], np.array([]), 0
                max_conf = 0.0
            else:
                keep = scores >= floor
                sel_raw, sel_scores = raw[keep], scores[keep]
                counts = {t: int((scores >= t).sum()) for t in thresholds}
                max_conf = float(scores.max()) if scores.size else 0.0
                verbose = args.test or (mapper.method is None)
                if verbose:
                    print("  detections >= %.2f: %d   (peak confidence %.3f)"
                          % (floor, len(sel_raw), max_conf))
                boxes = stretch_boxes(sel_raw, w, h)
                drawn = 0

            stamp = datetime.now()
            fid = "frame_%04d" % (idx if not args.test else 0)
            if args.test:
                fid = "frame_TEST"

            img.save(os.path.join(args.out, fid + "_clean.jpg"), quality=JPEG_QUALITY)

            marked, drawn = draw_boxes(img, boxes, sel_scores, thresholds)
            line1 = "%s   %s   lux %s   peak %.2f   %s" % (
                fid, stamp.strftime("%Y-%m-%d %H:%M:%S"),
                ("%.0f" % lx) if lx is not None else "n/a", max_conf,
                "  ".join("n(%.2f)=%d" % (t, counts[t]) for t in thresholds))
            legend = []
            if len(thresholds) >= 2:
                legend.append((BAND_LOW, "%.2f-%.2f" % (thresholds[0], thresholds[1])))
            if len(thresholds) >= 3:
                legend.append((BAND_MID, "%.2f-%.2f" % (thresholds[-2], thresholds[-1])))
            legend.append((BAND_HIGH, ">= %.2f" % thresholds[-1]))
            with_strip(marked, line1, legend).save(
                os.path.join(args.out, fid + "_marked.jpg"), quality=JPEG_QUALITY)

            if writer:
                writer.writerow([fid, stamp.isoformat(timespec="seconds"),
                                 counts[primary], "%.3f" % max_conf,
                                 ("%.1f" % lx) if lx is not None else ""]
                                + [counts[t] for t in thresholds] + [""])
                fh.flush()

            taken += 1
            print("[%s] %s  %s  peak %.2f  lux %-6s  boxes drawn %d  (%d of %d)"
                  % (stamp.strftime("%H:%M:%S"), fid,
                     " ".join("%.2f:%d" % (t, counts[t]) for t in thresholds),
                     max_conf, ("%.0f" % lx) if lx is not None else "n/a",
                     drawn, taken, n_samples), flush=True)

            if args.test:
                print("\nframe size: %d x %d px" % (w, h))
                print("wrote %s/frame_TEST_marked.jpg" % args.out)
                print("view it. If the boxes sit on insects, run without --test.")
                print("If they are displaced, retry with:  --order xyxy")

    except KeyboardInterrupt:
        print("\ninterrupted")
    finally:
        if fh:
            fh.close()
        picam2.stop()
        lux.close()

    if not args.test:
        print("\n%d samples in %s" % (taken, args.out))
        print("count the *_clean.jpg frames, fill manual_count, then:")
        for t in thresholds:
            print("  python3 bland_altman.py %s --column %s" % (csv_path, col(t)))


if __name__ == "__main__":
    main()
