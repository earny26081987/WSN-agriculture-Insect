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
APP_KEY      = "00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00"   # withheld: paste the device's AppKey from ChirpStack

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

print("Starting insect-count loop, uplink every %ds" % SEND_INTERVAL_S)
while True:
    count, max_conf = read_insects()
    lux = read_lux()
    payload = build_payload(count, max_conf, lux)
    print("insects=%d  max_conf=%.2f  lux=%d  payload=%s" % (count, max_conf, lux, payload))
    lora_send(payload)
    time.sleep(SEND_INTERVAL_S)

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
