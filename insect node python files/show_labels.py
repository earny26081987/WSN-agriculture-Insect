from picamera2.devices import IMX500
imx500 = IMX500("/usr/share/imx500-models/imx500_network_ssd_mobilenetv2_fpnlite_320x320_pp.rpk")
intr = imx500.network_intrinsics
labels = intr.labels if intr else None
if labels:
    for i, name in enumerate(labels):
        print(i, name)
else:
    print("no labels embedded")
