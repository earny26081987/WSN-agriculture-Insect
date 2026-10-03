#!/usr/bin/env python3
import time, sys
from datetime import datetime
from smbus2 import SMBus, i2c_msg

ADDR, INTERVAL = 0x23, 10

bus = SMBus(1)
bus.write_byte(ADDR, 0x01); time.sleep(0.05)   # power on
bus.write_byte(ADDR, 0x07); time.sleep(0.05)   # reset
bus.write_byte(ADDR, 0x10); time.sleep(0.20)   # continuous high-res

print("BH1750 at 0x%02X, every %ds — Ctrl-C to stop\n" % (ADDR, INTERVAL))
try:
    while True:
        rd = i2c_msg.read(ADDR, 2)
        bus.i2c_rdwr(rd)
        d = list(rd)
        lux = ((d[0] << 8) | d[1]) / 1.2
        print("%s  %9.1f lx" % (datetime.now().strftime("%H:%M:%S"), lux))
        time.sleep(INTERVAL)
except KeyboardInterrupt:
    bus.write_byte(ADDR, 0x00)
    print("\nstopped")
