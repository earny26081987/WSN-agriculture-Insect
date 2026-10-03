from picamera2 import Picamera2
from picamera2.devices import IMX500
import numpy as np, time

imx500 = IMX500("/home/ern/models/network.rpk")
picam2 = Picamera2(imx500.camera_num)
picam2.start(picam2.create_preview_configuration(
    controls={"FrameDurationLimits": (200000, 200000)}, buffer_count=8), show_preview=False)

for i in range(5):
    outputs = imx500.get_outputs(picam2.capture_metadata())
    if outputs is None:
        print("no output"); time.sleep(0.2); continue
    scores = np.array(outputs[1])
    print(f"frame {i}: min={scores.min():.4f} max={scores.max():.4f} "
          f"mean={scores.mean():.4f}  first10={np.round(scores[:10],3)}")
    time.sleep(0.2)

picam2.stop()
