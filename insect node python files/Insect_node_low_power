#!/usr/bin/env python3
# Insect-detection LoRaWAN node  --  LOW-POWER REVISION
# Platform : Raspberry Pi Zero 2 W (CPython, Linux) + Sony IMX500 AI Camera
# Radio    : Makerverse LoRa-E5 breakout (AT commands) on the Pi hardware UART
# Network  : AU915 sub-band 2, SF7, OTAA  (same settings that joined the env node)
#
# Each cycle: starts the IMX500, captures a short burst of frames, counts
# insect detections above a confidence threshold on-sensor, takes the MEDIAN
# across the burst (robust to per-frame jitter), STOPS the camera, and uplinks
# the count as a 5-byte payload (count u16 | conf*100 u8 | lux u16).
# No image ever leaves the sensor.
#


import time
import csv
import json
import os
import statistics
import subprocess
import serial
import numpy as np
import smbus2
from smbus2 import i2c_msg
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

# [power] duty-cycle settings
NIGHT_LUX_FLOOR   = 10        # below this the trap cannot be read (Sec. 4.6): no capture
NIGHT_INTERVAL_S  = 3600      # heartbeat cadence while dark
CAMERA_SETTLE_S   = 3.0       # AE/AWB settle after each camera start (15 frames at 5 fps)
NETWORK_WAIT_S    = 90        # max wait for the IMX500 network to produce output after start
LORA_SLEEP        = True      # AT+LOWPOWER between uplinks (session is kept on the module)
WIFI_MANAGE       = False     # True: Wi-Fi only inside WIFI_WINDOW  (see prerequisites!)
WIFI_WINDOW       = (9, 10)   # local hours [start, end) with Wi-Fi up for SSH
WIFI_GRACE_S      = 300       # Wi-Fi stays up this long after launch regardless

# ----------------- LoRa-E5 driver (pyserial) -----------------
lora = serial.Serial(SERIAL_PORT, SERIAL_BAUD, timeout=1)
_joined = False

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
    global _joined
    at("AT+JOIN", wait_s=0.2)
    end = time.time() + timeout_s
    buf = ""
    while time.time() < end:
        if lora.in_waiting:
            buf += lora.read(lora.in_waiting).decode("utf-8", "ignore")
            low = buf.lower()
            if "joined" in low:
                print("JOINED"); _joined = True; return True
            if "failed" in low:
                print("join failed"); _joined = False; return False
        time.sleep(0.2)
    print("join timeout"); _joined = False; return False

def lora_wake():
    """[power] Any UART traffic wakes the E5 from AT+LOWPOWER; 4x 0xFF is the documented sequence."""
    global LORA_SLEEP
    if not LORA_SLEEP:
        return
    lora.write(b"\xff\xff\xff\xff")
    time.sleep(0.05)
    for _ in range(3):
        if "OK" in at("AT", wait_s=0.3):
            return
        time.sleep(0.2)
    print("WARNING: LoRa-E5 did not acknowledge wake-up; disabling module sleep")
    LORA_SLEEP = False

def lora_sleep():
    """[power] Put the E5 to sleep until the next uplink. The LoRaWAN session survives."""
    global LORA_SLEEP
    if not LORA_SLEEP:
        return
    r = at("AT+LOWPOWER", wait_s=0.3)
    if "SLEEP" not in r.upper():
        print("WARNING: AT+LOWPOWER not acknowledged; disabling module sleep")
        LORA_SLEEP = False

def lora_send(hexstr):
    global _joined
    lora_wake()
    if not _joined:
        lora_join(timeout_s=20)          # [power] retry here rather than sending unjoined
    if _joined:
        at('AT+MSGHEX="%s"' % hexstr, wait_s=6)
    else:
        print("  not joined - uplink skipped (record still saved)")
    lora_sleep()

# ----------------- IMX500 camera (model loaded once; streamed only per burst) -----------------
print("Loading model onto IMX500 (first load ~20-30 s)...")
imx500 = IMX500(MODEL_PATH)
intrinsics = imx500.network_intrinsics or NetworkIntrinsics()
intrinsics.task = "object detection"
intrinsics.labels = [LABEL]
intrinsics.update_with_defaults()

picam2 = Picamera2(imx500.camera_num)
picam2.configure(picam2.create_preview_configuration(
    controls={"FrameDurationLimits": (FRAME_DURATION_US, FRAME_DURATION_US)},
    buffer_count=8))

def camera_on():
    """[power] Start streaming for one burst. If the sensor powered down after the
    previous stop, the driver re-uploads the network here; wait until it answers."""
    picam2.start(show_preview=False)
    end = time.time() + NETWORK_WAIT_S
    while time.time() < end:
        if imx500.get_outputs(picam2.capture_metadata()) is not None:
            break
    else:
        print("WARNING: no network output within %d s of start" % NETWORK_WAIT_S)
    time.sleep(CAMERA_SETTLE_S)          # exposure settles before the burst

def camera_off():
    """[power] Stop streaming: sensor and its inference engine idle until the next burst.
    If a current measurement shows the sensor still drawing, use picam2.close()
    here and re-create picam2 in camera_on() instead."""
    picam2.stop()

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

def grab_record_frame():
    """One request -> the frame AND the metadata (tensor) of that same frame."""
    req = picam2.capture_request()
    try:
        md = req.get_metadata()
        fr = req.make_array("main")
    finally:
        req.release()
    return fr, md

# ----------------- BH1750 lux sensor (I2C, one-shot) -----------------
try:
    _lux_bus = smbus2.SMBus(LUX_I2C_BUS)
    _lux_bus.write_byte(LUX_I2C_ADDR, 0x01)   # power on (sanity check that it answers)
    time.sleep(0.05)
except Exception as e:
    print("WARNING: lux I2C init failed:", e)
    _lux_bus = None

def read_lux():
    """[power] One-time high-resolution measurement; the BH1750 powers itself
    down afterwards instead of converting continuously."""
    if _lux_bus is None:
        return 0
    try:
        _lux_bus.write_byte(LUX_I2C_ADDR, 0x01)   # power on
        _lux_bus.write_byte(LUX_I2C_ADDR, 0x20)   # one-time H-res mode
        time.sleep(0.18)                           # max conversion time
        rd = i2c_msg.read(LUX_I2C_ADDR, 2)
        _lux_bus.i2c_rdwr(rd)
        b = list(rd)
        return min(int(((b[0] << 8) | b[1]) / 1.2), 65535)
    except Exception as e:
        print("lux read error:", e)
        return 0

# ----------------- Wi-Fi window (optional) -----------------
_launch_t = time.time()
_wifi_up = None

def manage_wifi():
    """[power] Keep Wi-Fi blocked except during WIFI_WINDOW (and the launch grace period)."""
    global _wifi_up
    if not WIFI_MANAGE:
        return
    h = time.localtime().tm_hour
    want_up = (WIFI_WINDOW[0] <= h < WIFI_WINDOW[1]) or (time.time() - _launch_t < WIFI_GRACE_S)
    if want_up != _wifi_up:
        subprocess.run(["sudo", "rfkill", "unblock" if want_up else "block", "wifi"], check=False)
        _wifi_up = want_up
        print("  wifi", "up" if want_up else "down")

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

def save_annotated(tag, fr, md, count, max_conf, lux):
    """Write <tag>_clean.jpg, <tag>_marked.jpg and <tag>_boxes.json from the
    frame/metadata pair captured during the burst (camera is already off)."""
    from PIL import Image, ImageDraw
    os.makedirs(SAVE_DIR, exist_ok=True)

    if fr.ndim == 3 and fr.shape[2] == 4:
        fr = fr[:, :, :3]
    img = Image.fromarray(np.ascontiguousarray(fr.astype(np.uint8)))
    W, H = img.width, img.height

    # clean copy first: no boxes, no strip, nothing in the filename that
    # reveals what the detector decided - this is what you count from
    clean_path = "%s/%s_clean.jpg" % (SAVE_DIR, tag)
    img.save(clean_path, quality=92)

    dets = boxes_from(imx500.get_outputs(md), W, H)
    ts = sorted(THRESHOLDS)
    counts = {t: sum(1 for sc_, _ in dets if sc_ >= t) for t in ts}
    peak = max([sc_ for sc_, _ in dets], default=0.0)

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
    line = "%s   lux %d   %s   peak %.2f   sent %d   %dx%d" % (
        time.strftime("%Y-%m-%d %H:%M:%S"), lux,
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
    print("  saved %s_{clean,marked}.jpg  (%s, peak %.2f, lux %d)"
          % (tag, " ".join("%.2f:%d" % (t, counts[t]) for t in ts), peak, lux))
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
    print("Could not join; will retry at each cycle")
lora_sleep()

# ----------------- campaign -----------------
CAMPAIGN_SAMPLES = 56                       # 56 x 15 min = 14 hours of wall-clock duration
CSV_PATH = SAVE_DIR + "/counts.csv"

os.makedirs(SAVE_DIR, exist_ok=True)
_new_csv = not os.path.exists(CSV_PATH)
_done = 0
if not _new_csv:
    try:
        with open(CSV_PATH) as _fh:
            _done = len(list(csv.DictReader(_fh)))
        print("resuming - %d samples already in counts.csv" % _done)
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
            print("existing counts.csv has an older column set - "
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
print("\nCAMPAIGN: %.1f hours, one sample every %d s in daylight, heartbeat every %d s in the dark"
      % (_total_h, SEND_INTERVAL_S, NIGHT_INTERVAL_S))
print("finishes near %s" % time.strftime("%H:%M on %d %b", time.localtime(_end)))
print("images to %s, rows to counts.csv" % SAVE_DIR)
print("Ctrl-C to stop early; the CSV is flushed after every sample.\n")

_n = 0
_next = time.time()                          # [power] absolute schedule, no drift
try:
    while _next < _end:
        manage_wifi()
        tag = time.strftime("%Y%m%d_%H%M%S")
        lux = read_lux()                     # [power] light first: decides whether to capture

        if lux < NIGHT_LUX_FLOOR:
            # [power] dark: the trap cannot be read; camera stays off, hourly heartbeat
            payload = build_payload(0, 0.0, lux)
            print("[night %s] lux=%d  heartbeat payload=%s" % (tag, lux, payload))
            lora_send(payload)
            _w.writerow([tag, time.strftime("%Y-%m-%dT%H:%M:%S"), 0, "0.000", lux]
                        + [""] * len(THRESHOLDS) + [""])
            _csv.flush()
            _next += NIGHT_INTERVAL_S
        else:
            camera_on()
            try:
                count, max_conf = read_insects()
                fr, md = grab_record_frame()
            finally:
                camera_off()                 # [power] sensor off before the slow CPU work

            payload = build_payload(count, max_conf, lux)
            _n += 1
            print("[%d] %s  insects=%d  max_conf=%.2f  lux=%d  payload=%s"
                  % (_done + _n, tag, count, max_conf, lux, payload))
            lora_send(payload)

            frame_counts = None
            try:
                frame_counts = save_annotated(tag, fr, md, count, max_conf, lux)
            except Exception as exc:
                print("  save_annotated failed:", exc)

            _w.writerow([tag, time.strftime("%Y-%m-%dT%H:%M:%S"),
                         count, "%.3f" % max_conf, lux]
                        + ([frame_counts[t] for t in sorted(THRESHOLDS)]
                           if frame_counts is not None else [""] * len(THRESHOLDS))
                        + [""])
            _csv.flush()
            _next += SEND_INTERVAL_S

        delay = _next - time.time()
        if delay > 0 and _next < _end:
            print("  next at %s\n" % time.strftime("%H:%M:%S", time.localtime(_next)))
            time.sleep(delay)                # CPU idles here; nothing lower is available
except KeyboardInterrupt:
    print("\ninterrupted")
finally:
    try:
        picam2.stop()
    except Exception:
        pass
    _csv.close()
    print("\ncounts.csv is in %s" % SAVE_DIR)
    print("count the *_clean.jpg frames, fill manual_count, then:")
    print("  python3 bland_altman.py %s" % CSV_PATH)

# ============================================================================
# MATCHING ChirpStack codec (Device Profile -> Codec -> JavaScript functions):
#
# function decodeUplink(input) {
#   var b = input.bytes;
#   if (b.length < 5) { return { data: {}, errors: ["expected 5 bytes"] }; }
#   var insect_count = (b[0] * 256) + b[1];   // uint16
#   var max_conf = b[2] / 100.0;              // 0.00 - 1.00
#   var lux = (b[3] * 256) + b[4];            // uint16, lux
#   return { data: { insect_count: insect_count, max_conf: max_conf, lux: lux } };
# }
# function encodeDownlink(input) { return { bytes: [] }; }
# ============================================================================
