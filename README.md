# WSN-agriculture-Insect

Companion repository for the ENP4111 dissertation *A low-cost LoRaWAN smart-agriculture sensor
network with on-sensor insect counting* (University of Southern Queensland, 2026). It holds the
node programs, payload codecs, server and gateway configuration, dashboard definitions and
network records of the two-node prototype described in the dissertation: an environmental
node (Raspberry Pi Pico 2, MicroPython) and an insect-detection node (Raspberry Pi Zero 2 W with
a Sony IMX500 AI Camera running a YOLO11n detector on the sensor), both uplinking over AU915
sub-band 2 LoRaWAN to a self-hosted ChirpStack / InfluxDB / Grafana stack on a Raspberry Pi 5
gateway.

Appendix A of the dissertation reproduces the codecs and the redacted server configuration and
maps every artefact to this repository (Table A.1). The layout below mirrors that table.

## Layout

| Path | Contents |
|---|---|
| `insect node python files/insect_node_boxtest.py` | Insect node program as run in the counting campaigns: LoRa-E5 AT driver, warm IMX500 pipeline, burst-median counting, BH1750 illuminance, five-byte payload, and the per-sample logging routine (clean frame, marked frame, detections JSON, `counts.csv` row). |
| `insect node python files/insect_node.py` | The same node without the logging routine. |
| `insect node python files/bland_altman_capture.py` | Stand-alone capture tool for the counting-agreement study (no radio). |
| `insect node python files/*_test.py`, `box_*.py`, `detect_debug.py`, `score_check.py`, `show_labels.py` | Bench tests used during commissioning. |
| `Torch_model.pt` | Trained YOLO11n weights (`exp-2(2).pt` is an identical copy). |
| `Quantised_IMXmodel.zip` | IMX500 export of the detector: `model_imx.onnx`, `dnnParams.xml`, `packerOut.zip`, memory report. |
| `insects(6).ndjson` | Export of the training dataset (687 images, 5,172 boxes, 549 train / 138 val) from the Ultralytics Platform. |
| `chirpstack codec/` | ChirpStack JavaScript decoders for the 15-byte environmental and 5-byte insect payloads. |
| `chirpstack_export/config/` | `chirpstack.toml` and region files, `chirpstack-gateway-bridge.toml`, `mosquitto.conf`, `influxdb.conf`, `grafana.ini`, as deployed. |
| `chirpstack_export/chirpstack_db.sql` | Dump of the ChirpStack database (device profiles, devices, gateway, integration). |
| `global_conf.json` | SX1302 HAL packet-forwarder configuration of the Waveshare SX1303 HAT (AU915 sub-band 2). |
| `Grafana Dashboards/` | Grafana exports of the environmental-node, insect-node and network-reliability dashboards. |
| `aug25_link.csv`, `sept_link.csv` | `device_uplink` exports (time in ns, DevEUI, RSSI, SNR, frame counter) for 25 August 2026 06:00–19:20 and for 8 September 06:08 to 10 September 06:20 (Perth time). |

Root-level copies of some node files and dashboards duplicate the ones in the folders.

## Credentials and location data

No secret is kept in this repository. The LoRaWAN application keys in the node programs are
placeholders (`00 00 … 00`) to be replaced with the key generated in ChirpStack for each device;
the database dump has its device keys, session state, user password hash and integration
password removed; the PostgreSQL password and API secret in `chirpstack.toml` are `REDACTED`;
and the packet forwarder's reference coordinates are zeroed. Keys that appeared in earlier
commits of this repository have been retired.

## Reproducing the network

1. Gateway host: install ChirpStack 4.18, the gateway bridge, Mosquitto, InfluxDB 1.8 and Grafana;
   copy `chirpstack_export/config/` into `/etc/`, set the two redacted values, and run the
   packet forwarder with `global_conf.json` (gateway EUI as registered on the server).
2. Server objects: see Table A.4 of the dissertation (or restore `chirpstack_db.sql` and re-enter
   the device keys). Both devices use OTAA, Class A, LoRaWAN 1.0.2 / RP revision A, DR5 fixed.
3. Insect node: Raspberry Pi OS 64-bit with `imx500-all`, `pyserial`, `smbus2`, Pillow; place the
   packaged network at the `MODEL_PATH` of the program, paste the AppKey, run
   `insect_node_boxtest.py` under `tmux`.
4. Dashboards: add an InfluxDB (InfluxQL) data source for database `chirpstack` and import the
   JSON files.

## Citation

B. Earnshaw, "WSN-agriculture-Insect: node programs, payload codecs, server and gateway
configuration, dashboard definitions and network records of a two-node LoRaWAN
smart-agriculture sensor network," GitHub repository, 2026.
https://github.com/earny26081987/WSN-agriculture-Insect

## Licence

Code is released under the MIT License (see `LICENSE`). Data files, dashboard definitions,
configuration and the trained models are released under the Creative Commons Attribution 4.0
International licence (CC BY 4.0).
