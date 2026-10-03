import time, serial
from collections import Counter
from picamera2 import Picamera2
from picamera2.devices import IMX500

APP_KEY = "E2 9A D7 09 CD 90 93 05 DF C2 32 6B F5 DC 3E 92"
DEV_EUI = "2C F7 F1 20 50 20 01 9B"
APP_EUI = "00 00 00 00 00 00 00 00"
BAND = "AU915"; CHANNELS = "8-15"; SEND_INTERVAL_S = 60; THRESHOLD = 0.45
MODEL = "/usr/share/imx500-models/imx500_network_ssd_mobilenetv2_fpnlite_320x320_pp.rpk"
PAYLOAD_CLASSES = [0, 2, 7, 17, 16]   # person, car, truck, dog, cat

ser = serial.Serial("/dev/serial0", 9600, timeout=1)
def at(cmd, wait=0.5):
    ser.reset_input_buffer(); ser.write((cmd + "\r\n").encode()); time.sleep(wait)
    r = ser.read(ser.in_waiting or 1).decode(errors="ignore")
    print(">", cmd, "->", r.strip().replace("\r\n", " | ")); return r
def lora_setup():
    if "OK" not in at("AT"): raise SystemExit("LoRa-E5 not responding")
    at("AT+MODE=LWOTAA"); at("AT+DR=" + BAND); at("AT+ADR=OFF")
    at("AT+DR=5"); at("AT+CH=NUM," + CHANNELS)
    at('AT+ID=DevEui,"%s"' % DEV_EUI); at('AT+ID=AppEui,"%s"' % APP_EUI)
    at('AT+KEY=APPKEY,"%s"' % APP_KEY)
def lora_join(timeout=30):
    at("AT+JOIN", wait=0.2); end = time.time() + timeout; buf = ""
    while time.time() < end:
        buf += ser.read(ser.in_waiting or 1).decode(errors="ignore")
        if "joined" in buf.lower(): print("JOINED"); return True
        if "failed" in buf.lower(): print("join failed"); return False
        time.sleep(0.3)
    print("join timeout"); return False
def lora_send_hex(h, wait=6):
    ser.reset_input_buffer(); ser.write(('AT+MSGHEX="%s"\r\n' % h).encode())
    end = time.time() + wait; buf = ""
    while time.time() < end:
        buf += ser.read(ser.in_waiting or 1).decode(errors="ignore")
        if "Done" in buf or "ERROR" in buf: break
        time.sleep(0.2)
    print("MSGHEX ->", buf.strip().replace("\r\n", " | "))
def build_payload(counts):
    out = [min(counts.get(c, 0), 255) for c in PAYLOAD_CLASSES]; out.append(1)
    return "".join("%02X" % b for b in out)

print("Loading IMX500 model...")
imx500 = IMX500(MODEL)
picam2 = Picamera2(imx500.camera_num)
picam2.start(picam2.create_preview_configuration(buffer_count=4), show_preview=False)
time.sleep(2)
def read_counts():
    md = picam2.capture_metadata(); outs = imx500.get_outputs(md, add_batch=True)
    counts = Counter()
    if outs is None: return counts
    scores, classes = outs[1][0], outs[2][0]
    for score, cls in zip(scores, classes):
        if score > THRESHOLD: counts[int(cls)] += 1
    return counts

lora_setup()
if not lora_join(): raise SystemExit("could not join network")
print("Detecting + uplinking every %ds" % SEND_INTERVAL_S)
while True:
    counts = read_counts(); payload = build_payload(counts)
    summary = ", ".join("%d:%d" % (c, counts.get(c, 0)) for c in PAYLOAD_CLASSES)
    print("counts [%s] -> %s" % (summary, payload))
    lora_send_hex(payload); time.sleep(SEND_INTERVAL_S)
