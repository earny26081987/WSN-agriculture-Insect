import serial, time
ser = serial.Serial("/dev/serial0", 9600, timeout=1)
def cmd(at, wait=0.5):
    ser.reset_input_buffer()
    ser.write((at + "\r\n").encode())
    time.sleep(wait)
    r = ser.read(ser.in_waiting or 1).decode(errors="ignore")
    print(">", at, "->", r.strip().replace("\r\n", " | "))
    return r
print("Testing LoRa-E5 on /dev/serial0...")
if "OK" in cmd("AT"):
    print("SUCCESS: LoRa-E5 responding")
    cmd("AT+ID=DevEui")
else:
    print("No reply - check TX/RX crossover and serial config")
ser.close()
