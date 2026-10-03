#!/usr/bin/env python3
# Insect-detection LoRaWAN node
# Platform : Raspberry Pi Zero 2 W (CPython, Linux) + Sony IMX500 AI Camera
# Radio    : Makerverse LoRa-E5 breakout (AT commands) on the Pi hardware UART
# Network  : AU915 sub-band 2, SF7, OTAA  (same settings that joined the env node)
#
# Each cycle: wakes the (warm) IMX500, captures a short burst of frames, counts
# insect detections above a confidence threshold on-sensor, takes the MEDIAN
# across the burst (robust to per-frame jitter), and uplinks the count as a
# 3-byte payload. No image ever leaves the sensor.
#
# ---- PREREQUISITES (one-time, on the Pi) --------------------------------
#   * Hardware UART working (loopback pin8<->pin10 echoes) and login shell off:
#       sudo raspi-config -> Interface Options -> Serial Port
#         login shell over serial? NO ;  serial hardware enabled? YES
#   * pip install pyserial     (picamera2 ships with imx500-all)
#   * LoRa-E5 wired: VIN->5V(pin2), GND->pin6,
#     breakout TX->Pi RXD(pin10), breakout RX->Pi TXD(pin8). ANTENNA fitted.
#   * network.rpk present at MODEL_PATH.
#
# ---- ChirpStack: register this as its OWN device -------------------------
#   DevEUI below is ASSIGNED (not the factory value) and is set onto the module
#   at startup. Register this exact DevEUI in ChirpStack with a NEW AppKey, its
#   own device profile, and the 3-byte insect codec (bottom of this file).
# -------------------------------------------------------------------------

import time
import csv
import json
import os
import statistics
import serial
import numpy as np
import smbus2
from picamera2 import Picamera2
from picamera2.devices import IMX500
from picamera2.devices.imx500 import NetworkIntrinsics

# ----------------- configuration -----------------
MODEL_PATH   = "/home/ern/models/network.rpk"
LABEL        = "insect"                       # single class
LUX_I2C_BUS  = 1
LUX_I2C_ADDR = 0x23

# LoRaWAN identity (AU915 SB2). MUST match the device you create in ChirpStack.
DEV_EUI      = "70 B3 D5 7E D0 07 78 01"      # assigned DevEUI (unique, != env node)
APP_EUI      = "00 00 00 00 00 00 00 00"
APP_KEY      = "22 88 E1 86 8E 00 85 B6 07 DA 23 A8 C0 E2 9A 04"   # <-- PASTE ChirpStack AppKey

BAND         = "AU915"
CHANNELS     = "8-15"                         # sub-band 2
SERIAL_PORT  = "/dev/serial0"
SERIAL_BAUD  = 9600

# detection + cadence
CONF_THRESHOLD    = 0.40      # tune against a blank scene (should read ~0)
BURST_FRAMES      = 10        # frames per reading; median smooths jitter
SEND_INTERVAL_S   = 900       # 15 min (use 1800 for 30 min)
FRAME_DURATION_US = 200000    # 5 fps during a burst (1e6 / fps)

# ----------------- LoRa-E5 driver (pyserial) -----------------
lora = serial.Serial(SERIAL_PORT, SERIAL_BAUD, timeout=1)

def at(cmd, wait_s=0.5):
    lora.reset_input_buffer()
    lora.write((cmd + "\r\n").encode())
    time.sleep(wait_s)
    resp = lora.read(lora.in_waiting or 1).decode("utf-8", "ignore")
    time.sleep(0.05)
    if lora.in_waiting:
        resp += lora.read(lora.in_waiting).decode("utf-8", "ignore")
    txt = resp.strip()
    print(">", cmd, "->", txt.replace("\r\n", " | "))
    return txt

def lora_setup():
    if "OK" not in at("AT"):
        print("WARNING: LoRa-E5 not responding on", SERIAL_PORT)
    at("AT+MODE=LWOTAA")
    at("AT+DR=" + BAND)
    at("AT+ADR=OFF")
    at("AT+DR=5")                       # SF7
    at("AT+CH=NUM," + CHANNELS)
    at('AT+ID=DevEui,"%s"' % DEV_EUI)   # ASSIGN the DevEUI onto the module
    at('AT+ID=AppEui,"%s"' % APP_EUI)
    at('AT+KEY=APPKEY,"%s"' % APP_KEY)
    # read back to confirm it took
    got = at("AT+ID=DevEui")
    print("\n*** DevEUI now on module (must match ChirpStack): %s ***\n" % got)

def lora_join(timeout_s=30):
    at("AT+JOIN", wait_s=0.2)
    end = time.time() + timeout_s
    buf = ""
    while time.time() < end:
        if lora.in_waiting:
            buf += lora.read(lora.in_waiting).decode("utf-8", "ignore")
            low = buf.lower()
            if "joined" in low:
                print("JOINED"); return True
            if "failed" in low:
                print("join failed"); return False
        time.sleep(0.2)
    print("join timeout"); return False

def lora_send(hexstr):
    at('AT+MSGHEX="%s"' % hexstr, wait_s=6)

# ----------------- IMX500 camera (kept warm across cycles) -----------------
print("Loading model onto IMX500 (first load ~20-30 s)...")
imx500 = IMX500(MODEL_PATH)
intrinsics = imx500.network_intrinsics or NetworkIntrinsics()
intrinsics.task = "object detection"
intrinsics.labels = [LABEL]
intrinsics.update_with_defaults()

picam2 = Picamera2(imx500.camera_num)
picam2.start(picam2.create_preview_configuration(
    controls={"FrameDurationLimits": (FRAME_DURATION_US, FRAME_DURATION_US)},
    buffer_count=8), show_preview=False)
time.sleep(2)   # let the sensor settle after model upload

def frame_count():
    """Count detections above CONF_THRESHOLD in one frame. Returns (count, max_conf)."""
    outputs = imx500.get_outputs(picam2.capture_metadata())
    if outputs is None:
        return 0, 0.0
    scores = np.array(outputs[1])            # (300,) score per slot
    count = int((scores > CONF_THRESHOLD).sum())
    max_conf = float(scores.max()) if scores.size else 0.0
    return count, max_conf

def read_insects():
    """Median count over a burst, plus the peak confidence seen."""
    counts, confs = [], []
    for _ in range(BURST_FRAMES):
        c, mc = frame_count()
        counts.append(c); confs.append(mc)
        time.sleep(0.05)
    return int(statistics.median(counts)), (max(confs) if confs else 0.0)

# ----------------- BH1750 lux sensor (I2C) -----------------
try:
    _lux_bus = smbus2.SMBus(LUX_I2C_BUS)
    _lux_bus.write_byte(LUX_I2C_ADDR, 0x01)   # BH1750 power on
    time.sleep(0.05)
    _lux_bus.write_byte(LUX_I2C_ADDR, 0x10)   # continuous high-res mode
    time.sleep(0.2)                            # first conversion settle
except Exception as e:
    print("WARNING: lux I2C init failed:", e)
    _lux_bus = None

def read_lux():
    if _lux_bus is None:
        return 0
    try:
        d = _lux_bus.read_i2c_block_data(LUX_I2C_ADDR, 0x10, 2)
        raw = (d[0] << 8) | d[1]
        return min(int(raw / 1.2), 65535)
    except Exception as e:
        print("lux read error:", e)
        return 0


# ----------------- annotated frame saving (box test copy) -----------------
SAVE_DIR   = "/home/ern/captures_node/run_" + time.strftime("%Y%m%d_%H%M")
THRESHOLDS = [0.30, 0.40, 0.50]   # all three shown in one image, colour-banded
SAVE_FLOOR = min(THRESHOLDS)      # draw everything at or above the lowest

def boxes_from(outputs, w, h, floor=SAVE_FLOOR):
    """Detections as (score, (x0,y0,x1,y1)) in FRAME pixels.

    The frame is STRETCHED to fill the 640x640 network input (verified on
    hardware 29 Jul), so boxes scale straight back with no padding term.
    """
    if outputs is None:
        return []
    raw = np.array(outputs[0], dtype=float)
    sc  = np.array(outputs[1], dtype=float)
    while raw.ndim > 2: raw = raw[0]
    while sc.ndim > 1:  sc = sc[0]
    if raw.ndim != 2 or raw.shape[-1] != 4:
        return []
    n = min(len(raw), len(sc))
    raw, sc = raw[:n], sc[:n]
    keep = sc >= floor
    raw, sc = raw[keep], sc[keep]
    if not len(raw):
        return []
    # the frame is STRETCHED to fill the 640x640 input (no letterbox),
    # verified on hardware 29 Jul: preserve_aspect_ratio is not set
    if np.max(np.abs(raw)) > 1.5:
        raw = raw / 640.0
    return [(float(v), (x0*w, y0*h, x1*w, y1*h))
            for (x0, y0, x1, y1), v in zip(raw, sc)]

def _font(size):
    from PIL import ImageFont
    try:
        return ImageFont.truetype(
            "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", size)
    except Exception:
        return ImageFont.load_default()

def _read_lux():
    """Use the node's own lux reader if it has one, else read the BH1750."""
    for name in ("read_lux", "lux_read", "get_lux", "read_light"):
        fn = globals().get(name)
        if callable(fn):
            try:
                return float(fn())
            except Exception:
                pass
    try:
        from smbus2 import SMBus, i2c_msg
        bus = SMBus(1)
        try:
            bus.write_byte(0x23, 0x01); time.sleep(0.05)
            bus.write_byte(0x23, 0x10); time.sleep(0.20)
            rd = i2c_msg.read(0x23, 2)
            bus.i2c_rdwr(rd)
            b = list(rd)
            return ((b[0] << 8) | b[1]) / 1.2
        finally:
            bus.close()
    except Exception:
        return None

def save_annotated(tag, count=None, max_conf=None):
    import os
    from PIL import Image, ImageDraw
    os.makedirs(SAVE_DIR, exist_ok=True)

    md = picam2.capture_metadata()
    fr = picam2.capture_array()
    if fr.ndim == 3 and fr.shape[2] == 4:
        fr = fr[:, :, :3]
    img = Image.fromarray(np.ascontiguousarray(fr.astype(np.uint8)))
    W, H = img.width, img.height

    # clean copy first: no boxes, no strip, nothing in the filename that
    # reveals what the detector decided — this is what you count from
    clean_path = "%s/%s_clean.jpg" % (SAVE_DIR, tag)
    img.save(clean_path, quality=92)

    dets = boxes_from(imx500.get_outputs(md), W, H)
    lux = _read_lux()
    ts = sorted(THRESHOLDS)
    counts = {t: sum(1 for sc_, _ in dets if sc_ >= t) for t in ts}
    peak = max([sc_ for sc_, _ in dets], default=0.0)
    if count is None:
        count = counts.get(CONF_THRESHOLD, counts[ts[0]])
    if max_conf is None:
        max_conf = peak

    # one colour per threshold band, so a single image shows what each cutoff
    # keeps: red survives every threshold, cyan only the lowest
    BANDS = [(40, 185, 235), (205, 60, 220), (230, 40, 40)]

    def _band(score):
        if score >= ts[-1]:
            return BANDS[2]
        if len(ts) >= 2 and score >= ts[-2]:
            return BANDS[1]
        return BANDS[0]

    scale = max(1.0, W / 640.0)
    strip = int(62 * scale)
    out = Image.new("RGB", (W, H + strip), (24, 24, 24))
    out.paste(img, (0, 0))
    d = ImageDraw.Draw(out)

    lw = max(2, int(round(W / 320.0)))
    fbox = _font(max(13, int(round(W / 55.0))))
    for score, (x0, y0, x1, y1) in dets:
        c = _band(score)
        d.rectangle([x0, y0, x1, y1], outline=c, width=lw)
        d.text((x0 + lw + 2, max(0, y0 - fbox.size - 2)),
               "%.2f" % score, fill=c, font=fbox)

    f1 = _font(int(18 * scale))
    f2 = _font(int(14 * scale))
    line = "%s   lux %s   %s   peak %.2f   sent %d   %dx%d" % (
        time.strftime("%Y-%m-%d %H:%M:%S"),
        ("%.0f" % lux) if lux is not None else "n/a",
        "  ".join("n(%.2f)=%d" % (t, counts[t]) for t in ts),
        peak, count, W, H)
    d.text((int(9 * scale), H + int(5 * scale)), line,
           fill=(235, 235, 235), font=f1)

    labels = []
    for k, t in enumerate(ts):
        hi = ts[k + 1] if k + 1 < len(ts) else None
        labels.append((BANDS[min(k, 2)],
                       ("%.2f-%.2f" % (t, hi)) if hi else (">= %.2f" % t)))
    x, y = int(9 * scale), H + int(34 * scale)
    for colour, text in labels:
        d.rectangle([x, y + int(4 * scale), x + int(13 * scale),
                     y + int(15 * scale)], fill=colour)
        d.text((x + int(18 * scale), y), text, fill=(200, 200, 200), font=f2)
        try:
            x += int(18 * scale) + int(f2.getlength(text)) + int(24 * scale)
        except Exception:
            x += int(18 * scale) + int(8 * scale) * len(text) + int(24 * scale)

    # raw detections alongside the image, so any suppression scheme can be
    # applied offline later without re-running the campaign
    try:
        with open("%s/%s_boxes.json" % (SAVE_DIR, tag), "w") as _jf:
            json.dump({"frame": tag, "w": W, "h": H, "lux": lux,
                       "detections": [{"score": round(sc_, 4),
                                       "box": [round(v, 1) for v in bx]}
                                      for sc_, bx in dets]}, _jf)
    except Exception as _e:
        print("  box log failed:", _e)

    path = "%s/%s_marked.jpg" % (SAVE_DIR, tag)
    out.save(path, quality=90)
    print("  saved %s_{clean,marked}.jpg  (%s, peak %.2f, lux %s)"
          % (tag, " ".join("%.2f:%d" % (t, counts[t]) for t in ts), peak,
             ("%.0f" % lux) if lux is not None else "n/a"))
    return counts

# ----------------- payload builder -----------------
def build_payload(count, max_conf, lux):
    # 5 bytes: [0..1] count u16 | [2] conf*100 | [3..4] lux u16
    c  = max(0, min(count, 0xFFFF))
    mc = max(0, min(int(round(max_conf * 100)), 255))
    lx = max(0, min(int(lux), 0xFFFF))
    b = bytes([(c >> 8) & 0xFF, c & 0xFF, mc, (lx >> 8) & 0xFF, lx & 0xFF])
    return "".join("%02X" % x for x in b)

# ----------------- main -----------------
print("Configuring LoRa-E5...")
lora_setup()
if not lora_join():
    print("Could not join; will still count and retry sends in loop")

# ----------------- campaign -----------------
CAMPAIGN_SAMPLES = 56                       # 56 x 15 min = 14 hours
CSV_PATH = SAVE_DIR + "/counts.csv"

os.makedirs(SAVE_DIR, exist_ok=True)
_new_csv = not os.path.exists(CSV_PATH)
_done = 0
if not _new_csv:
    try:
        with open(CSV_PATH) as _fh:
            _done = len(list(csv.DictReader(_fh)))
        print("resuming — %d samples already in counts.csv" % _done)
    except Exception:
        pass

_HEADER = (["frame_id", "timestamp", "node_count", "max_conf", "lux"]
           + ["count_%.2f" % t for t in sorted(THRESHOLDS)]
           + ["manual_count"])
if not _new_csv:
    try:
        with open(CSV_PATH) as _fh:
            _old_hdr = next(csv.reader(_fh))
        if _old_hdr != _HEADER:
            CSV_PATH = SAVE_DIR + "/counts_v2.csv"
            _new_csv = not os.path.exists(CSV_PATH)
            _done = 0
            print("existing counts.csv has an older column set — "
                  "writing to counts_v2.csv instead")
    except Exception:
        pass

_csv = open(CSV_PATH, "a", newline="")
_w = csv.writer(_csv)
if _new_csv:
    _w.writerow(_HEADER)
    _csv.flush()

_total_h = CAMPAIGN_SAMPLES * SEND_INTERVAL_S / 3600.0
_end = time.time() + CAMPAIGN_SAMPLES * SEND_INTERVAL_S
print("\nCAMPAIGN: %d samples, one every %d s (%.1f hours)"
      % (CAMPAIGN_SAMPLES, SEND_INTERVAL_S, _total_h))
print("finishes near %s" % time.strftime("%H:%M on %d %b", time.localtime(_end)))
print("images to %s, rows to counts.csv" % SAVE_DIR)
print("Ctrl-C to stop early; the CSV is flushed after every sample.\n")

try:
    for _i in range(CAMPAIGN_SAMPLES):
        tag = time.strftime("%Y%m%d_%H%M%S")
        count, max_conf = read_insects()
        lux = read_lux()
        payload = build_payload(count, max_conf, lux)
        print("[%d of %d] insects=%d  max_conf=%.2f  lux=%d  payload=%s"
              % (_done + _i + 1, _done + CAMPAIGN_SAMPLES,
                 count, max_conf, lux, payload))
        lora_send(payload)

        frame_counts = None
        try:
            frame_counts = save_annotated(tag, count, max_conf)
        except Exception as exc:
            print("  save_annotated failed:", exc)

        if frame_counts is not None:
            _w.writerow([tag, time.strftime("%Y-%m-%dT%H:%M:%S"),
                         count, "%.3f" % max_conf, lux]
                        + [frame_counts[t] for t in sorted(THRESHOLDS)] + [""])
            _csv.flush()

        if _i < CAMPAIGN_SAMPLES - 1:
            nxt = time.time() + SEND_INTERVAL_S
            print("  next at %s\n" % time.strftime("%H:%M:%S", time.localtime(nxt)))
            time.sleep(SEND_INTERVAL_S)
except KeyboardInterrupt:
    print("\ninterrupted")
finally:
    _csv.close()
    print("\ncounts.csv is in %s" % SAVE_DIR)
    print("count the *_clean.jpg frames, fill manual_count, then:")
    print("  python3 bland_altman.py %s" % CSV_PATH)

# ============================================================================
# MATCHING ChirpStack codec (Device Profile -> Codec -> JavaScript functions):
#
# function decodeUplink(input) {
#   var b = input.bytes;
#   if (b.length < 3) { return { data: {}, errors: ["expected 3 bytes"] }; }
#   var insect_count = (b[0] * 256) + b[1];   // uint16, plain arithmetic
#   var max_conf = b[2] / 100.0;              // 0.00 - 1.00
#   return { data: { insect_count: insect_count, max_conf: max_conf } };
# }
# function encodeDownlink(input) { return { bytes: [] }; }
# ============================================================================
