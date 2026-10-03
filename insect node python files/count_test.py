from picamera2 import Picamera2
from picamera2.devices import IMX500
import numpy as np
import time

CONF = 0.4   # your confidence threshold

imx500 = IMX500("/home/ern/models/network.rpk")
picam2 = Picamera2(imx500.camera_num)
picam2.start(picam2.create_preview_configuration(
    controls={"FrameDurationLimits": (200000, 200000)},   # 5 fps
    buffer_count=8), show_preview=False)

print("Reading 20 frames...")
for i in range(20):
    metadata = picam2.capture_metadata()
    outputs = imx500.get_outputs(metadata)
    if outputs is None:
        print(f"frame {i}: no output")
        time.sleep(0.1); continue

    # inspect shapes once so we know the real layout
    if i == 0:
        for j, o in enumerate(outputs):
            print(f"  output[{j}] shape={np.array(o).shape}")

    boxes  = np.array(outputs[0])     # (300,4)
    scores = np.array(outputs[1])     # (300,)
    count = int((scores > CONF).sum())
    print(f"frame {i}: insects above {CONF} = {count}")
    time.sleep(0.1)

picam2.stop()
print("done")
