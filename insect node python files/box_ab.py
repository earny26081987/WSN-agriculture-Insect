import time, numpy as np
from PIL import Image, ImageDraw
from picamera2 import Picamera2
from picamera2.devices import IMX500
from picamera2.devices.imx500 import NetworkIntrinsics

imx500 = IMX500("/home/ern/models/network.rpk")
intr = imx500.network_intrinsics or NetworkIntrinsics()
intr.task = "object detection"; intr.labels = ["insect"]; intr.update_with_defaults()
print("preserve_aspect_ratio =", getattr(intr, "preserve_aspect_ratio", "unset"))

p = Picamera2(imx500.camera_num)
p.start(p.create_preview_configuration(buffer_count=8), show_preview=False)
time.sleep(2)

b = s = None
for attempt in range(40):                      # wait for a frame with detections
    md = p.capture_metadata(); fr = p.capture_array()
    out = imx500.get_outputs(md)
    if out is None:
        time.sleep(0.3); continue
    bb = np.array(out[0], float); ss = np.array(out[1], float)
    while bb.ndim > 2: bb = bb[0]
    while ss.ndim > 1: ss = ss[0]
    n = min(len(bb), len(ss)); bb, ss = bb[:n], ss[:n]
    k = ss >= 0.30
    if k.sum() > 0:
        b, s = bb[k], ss[k]; break
    time.sleep(0.3)

if b is None:
    p.stop(); raise SystemExit("no detections >= 0.30 in 40 frames — put an insect in view")

if fr.ndim == 3 and fr.shape[2] == 4: fr = fr[:, :, :3]
if np.max(np.abs(b)) <= 1.5: b = b * 640.0

img = Image.fromarray(np.ascontiguousarray(fr.astype(np.uint8)))
W, H = img.width, img.height
print("frame %dx%d, %d detections (attempt %d)" % (W, H, len(b), attempt+1))
for r, sc in zip(b, s): print("  %.2f  %s" % (sc, np.round(r, 1)))

d = ImageDraw.Draw(img)
sc_ = min(640.0/W, 640.0/H); px = (640-W*sc_)/2; py = (640-H*sc_)/2
for r in b:
    x0, y0, x1, y1 = r
    d.rectangle([(x0-px)/sc_, (y0-py)/sc_, (x1-px)/sc_, (y1-py)/sc_],
                outline=(255, 0, 0), width=3)                    # RED  letterbox
    d.rectangle([x0*W/640.0, y0*H/640.0, x1*W/640.0, y1*H/640.0],
                outline=(0, 220, 0), width=3)                    # GREEN stretch
d.text((8, 8), "RED = letterbox   GREEN = stretch", fill=(0, 0, 0))
img.save("/home/ern/captures_node/box_ab.jpg", quality=92)
p.stop(); print("wrote /home/ern/captures_node/box_ab.jpg")
