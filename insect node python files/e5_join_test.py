import serial, time
APP_KEY = "00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00"   # withheld: paste the device's AppKey from ChirpStack
DEV_EUI = "2C F7 F1 20 50 20 01 9B"
APP_EUI = "00 00 00 00 00 00 00 00"
ser = serial.Serial("/dev/serial0", 9600, timeout=1)
def cmd(at, wait=0.5):
    ser.reset_input_buffer()
    ser.write((at + "\r\n").encode())
    time.sleep(wait)
    r = ser.read(ser.in_waiting or 1).decode(errors="ignore")
    print(">", at, "->", r.strip().replace("\r\n", " | "))
    return r
def join(timeout=30):
    cmd("AT+JOIN", wait=0.2)
    end = time.time() + timeout; buf = ""
    while time.time() < end:
        buf += ser.read(ser.in_waiting or 1).decode(errors="ignore")
        if "joined" in buf.lower(): print("JOINED"); return True
        if "failed" in buf.lower(): print("Join failed"); return False
        time.sleep(0.3)
    print("Join timed out"); return False
def send_hex(h, wait=6):
    ser.reset_input_buffer()
    ser.write(('AT+MSGHEX="%s"\r\n' % h).encode())
    end = time.time() + wait; buf = ""
    while time.time() < end:
        buf += ser.read(ser.in_waiting or 1).decode(errors="ignore")
        if "Done" in buf or "ERROR" in buf: break
        time.sleep(0.2)
    print("MSGHEX ->", buf.strip().replace("\r\n", " | "))
print("Configuring...")
cmd("AT")
cmd("AT+MODE=LWOTAA"); cmd("AT+DR=AU915"); cmd("AT+ADR=OFF"); cmd("AT+DR=5"); cmd("AT+CH=NUM,8-15")
cmd('AT+ID=DevEui,"%s"' % DEV_EUI); cmd('AT+ID=AppEui,"%s"' % APP_EUI); cmd('AT+KEY=APPKEY,"%s"' % APP_KEY)
print("Joining...")
if join():
    send_hex("01 02 03 04")
    print("Done - check ChirpStack")
else:
    print("Did not join - check DevEUI/AppKey match ChirpStack")
ser.close()
