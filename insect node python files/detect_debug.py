#!/usr/bin/env python3
import sys, time
import numpy as np
from picamera2 import Picamera2
from picamera2.devices import IMX500

MODEL = "/home/ern/models/network.rpk"

print("loading model (20-30 s)...")
imx500 = IMX500(MODEL)
picam2 = Picamera2(imx500.camera_num)
picam2.start(picam2.create_preview_configuration(
    main={"format": "RGB888"}, buffer_count=6), show_preview=False)
time.sleep(2)

try:
    print("inference input size:", imx500.get_input_size())
except Exception as e:
    print("get_input_size:", e)

for n in range(3):
    print("\n" + "="*60)
    print("FRAME", n+1)
    md = picam2.capture_metadata()
    fr = picam2.capture_array()
    print("  array shape", fr.shape, fr.dtype)

    out = imx500.get_outputs(md)
    if out is None:
        print("  get_outputs() = None"); time.sleep(1); continue

    print("  %d tensors:" % len(out))
    for i, o in enumerate(out):
        a = np.array(o)
        r = "min=%.4f max=%.4f" % (a.min(), a.max()) if a.size else "empty"
        print("    [%d] shape=%s dtype=%s %s" % (i, a.shape, a.dtype, r))

    boxes = np.array(out[0])
    sc = np.array(out[1]) if len(out) > 1 else np.array([])
    if not sc.size:
        print("  no scores"); time.sleep(1); continue

    print("  scores n=%d max=%.3f  >=0.3:%d >=0.4:%d >=0.5:%d"
          % (sc.size, sc.max(), (sc>=.3).sum(), (sc>=.4).sum(), (sc>=.5).sum()))
    print("  top5:", ", ".join("%.3f" % s for s in np.sort(sc)[::-1][:5]))

    k = np.where(sc >= 0.30)[0]
    if not k.size:
        print("  nothing above 0.30"); time.sleep(1); continue

    for i in k[:3]:
        print("    score %.3f raw=%s" % (sc[i], np.round(np.asarray(boxes[i]),4)))

    b = boxes[int(k[0])]
    try:
        print("  convert_inference_coords ->", imx500.convert_inference_coords(b, md, picam2))
    except Exception as e:
        print("  convert_inference_coords FAILED:", type(e).__name__, e)

    h, w = fr.shape[0], fr.shape[1]
    a = np.asarray(b, dtype=float)
    if a.size == 4:
        print("  frame %dx%d px" % (w, h))
        print("  if (y0,x0,y1,x1) norm -> (%.0f,%.0f,%.0f,%.0f)"
              % (a[1]*w, a[0]*h, a[3]*w, a[2]*h))
        print("  if (x0,y0,x1,y1) norm -> (%.0f,%.0f,%.0f,%.0f)"
              % (a[0]*w, a[1]*h, a[2]*w, a[3]*h))
        print("  if already pixels     -> (%.0f,%.0f,%.0f,%.0f)"
              % (a[0], a[1], a[2], a[3]))
    time.sleep(1)

picam2.stop()
print("\ndone")
