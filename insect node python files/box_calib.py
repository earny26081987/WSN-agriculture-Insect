#!/usr/bin/env python3
import time
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from picamera2 import Picamera2
from picamera2.devices import IMX500

MODEL = "/home/ern/models/network.rpk"
W, H = 2028, 1520
FLOOR = 0.30

imx500 = IMX500(MODEL)
p = Picamera2(imx500.camera_num)
p.start(p.create_preview_configuration(
    main={"format": "RGB888", "size": (W, H)}, buffer_count=4), show_preview=False)
time.sleep(2)

md = p.capture_metadata()
fr = p.capture_array()[:, :, ::-1]
out = imx500.get_outputs(md, add_batch=True)
b = np.array(out[0]); s = np.array(out[1])
while b.ndim > 2: b = b[0]
while s.ndim > 1: s = s[0]
k = s >= FLOOR
b, s = b[k], s[k]

print("frame:", fr.shape)
print("ScalerCrop:", md.get("ScalerCrop"))
try: print("input size:", imx500.get_input_size())
except Exception as e: print("input size:", e)
print("raw boxes (first 3):")
for r, sc in list(zip(b, s))[:3]:
    print("   %.3f  %s" % (sc, np.round(r, 4)))

img = Image.fromarray(np.ascontiguousarray(fr.astype(np.uint8)))
d = ImageDraw.Draw(img)
f = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 34)

# letterbox parameters: 640x640 square fed from a 4:3 frame
sc_ = 640.0 / W
ph = (640 - H * sc_) / 2.0

def A(r):
    x, y, w_, h_ = imx500.convert_inference_coords(r, md, p)
    return (x, y, x + w_, y + h_)
def B(r): return (r[1]*W, r[0]*H, r[3]*W, r[2]*H)
def C(r): return (r[0]*W, r[1]*H, r[2]*W, r[3]*H)
def D(r): return (r[1]*W, (r[0]*640-ph)/sc_, r[3]*W, (r[2]*640-ph)/sc_)
def E(r): return (r[0]*W, (r[1]*640-ph)/sc_, r[2]*W, (r[3]*640-ph)/sc_)

cands = [("RED  convert_inference_coords", A, (255,0,0)),
         ("BLUE yxyx normalised", B, (0,80,255)),
         ("PINK xyxy normalised", C, (255,0,255)),
         ("GREEN yxyx + letterbox", D, (0,140,0)),
         ("BLACK xyxy + letterbox", E, (0,0,0))]

for name, fn, col in cands:
    try:
        for r in b:
            x0,y0,x1,y1 = fn(np.asarray(r, float))
            d.rectangle([x0,y0,x1,y1], outline=col, width=7)
    except Exception as ex:
        print("skip", name, ex)

y = 10
for name, _, col in cands:
    d.rectangle([10, y, 46, y+30], fill=col)
    d.text((56, y), name, fill=(0,0,0), font=f)
    y += 44

img.save("/home/ern/captures_ba/box_calib.jpg", quality=92)
p.stop()
print("\nwrote /home/ern/captures_ba/box_calib.jpg")
