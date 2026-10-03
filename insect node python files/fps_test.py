from picamera2 import Picamera2
from picamera2.devices import IMX500
import time

imx500 = IMX500("/home/ern/models/network.rpk")
picam2 = Picamera2(imx500.camera_num)

config = picam2.create_preview_configuration(
    controls={"FrameDurationLimits": (200000, 200000)},   # 5 fps
    buffer_count=8
)
picam2.start(config, show_preview=False)

print("Camera started at 5 fps. Reading 20 frames...")
for i in range(20):
    metadata = picam2.capture_metadata()
    outputs = imx500.get_outputs(metadata)
    n = 0 if outputs is None else len(outputs[0])   # rough detection count
    print(f"frame {i}: outputs={'none' if outputs is None else 'present'}  count~{n}")
    time.sleep(0.1)

picam2.stop()
print("done")
