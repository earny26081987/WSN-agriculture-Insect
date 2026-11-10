# Full LoRaWAN sensor node for Raspberry Pi Pico 2 (RP2350, MicroPython)
# LOW-POWER REVISION - software changes only, wiring unchanged.
#
# Sensors: SHT30 (temp/humidity), capacitive soil moisture, NEO-6M GPS,
#          A02YYUW waterproof ultrasonic distance.
# Radio:   Seeed LoRa-E5 (AT commands), AU915 sub-band 2, SF7, OTAA.
#
# What changed (all marked [power]):
#   * machine.lightsleep() between samples instead of time.sleep()
#   * LoRa-E5 sleeps (AT+LOWPOWER) between uplinks; woken with 0xFF bytes;
#     the LoRaWAN session is kept, so no re-join
#   * cadence 15 min instead of ~16 s
#   * uplink waits for the E5's "Done" instead of a fixed 6 s
#   * NEO-6M put into software backup mode (UBX-RXM-PMREQ) after one fix;
#     fix sent once on FPort 2 at boot and refreshed daily; the routine
#     payload no longer carries lat/lon (15 -> 7 bytes)
#   * optional lower TX power (TX_POWER_DBM) - links measured well above
#     the sensitivity floor in Sec. 4.3
#
# Still drawing between samples (no software control): soil probe (~5 mA)
# and A02YYUW (~8 mA). These set the sleeping floor.
#
# Payloads:
#   FPort 1, 7 bytes (every cycle):
#     [0..1]  temp     int16  degC * 100 (signed)
#     [2..3]  humidity uint16 % * 100
#     [4]     soil     uint8  percent
#     [5..6]  distance uint16 mm   (A02YYUW)
#   FPort 2, 8 bytes (at boot and once a day):
#     [0..3]  latitude  int32 deg * 1e6 (signed)
#     [4..7]  longitude int32 deg * 1e6 (signed)
#
# Pin map (RP2350) - unchanged:
#   LoRa-E5  : UART1  GP4(TX,pin6),  GP5(RX,pin7),  VCC 3V3
#   NEO-6M   : UART0  GP0(TX,pin1),  GP1(RX,pin2),  VCC VBUS(5V), TX/RX crossed
#   SHT30    : I2C1   GP2(SDA,pin4), GP3(SCL,pin5), addr 0x44, VCC 3V3
#   Soil     : ADC0   GP26(pin31),   VCC 3V3
#   A02YYUW  : PIO RX GP16(pin21) <- sensor White(TX); VCC 3V3, Yellow n/c
#
# DEVELOPMENT NOTE: lightsleep drops the USB REPL. Set DEBUG = True while
# working in Thonny (uses time.sleep and a short interval), False to deploy.

import time
import machine
import rp2
from machine import Pin, UART, I2C, ADC

# ----------------- configuration -----------------
APP_KEY  = "E2 9A D7 09 CD 90 93 05 DF C2 32 6B F5 DC 3E 92"   # sensor node AppKey
DEV_EUI  = "70 B3 D5 7E D0 07 78 CC"
APP_EUI  = "00 00 00 00 00 00 00 00"
BAND     = "AU915"
CHANNELS = "8-15"

DEBUG           = True        # True: time.sleep + 30 s cadence, REPL stays alive
SEND_INTERVAL_S = 30 if DEBUG else 900        # [power] 15 min in deployment
FIX_EVERY       = 96           # [power] refresh the GPS fix every N cycles (daily at 15 min)
FIX_TIMEOUT_S   = 90           # allow a cold start
TX_POWER_DBM    = None         # [power] e.g. 14 to cut TX current; None = module default
LORA_SLEEP      = True         # [power] AT+LOWPOWER between uplinks
GPS_BACKUP      = True         # [power] UBX-RXM-PMREQ backup mode between fixes

# soil calibration (raw read_u16): dry air = high, submerged = low
SOIL_AIR   = 45000
SOIL_WATER = 2000

def zzz(seconds):
    """[power] Sleep the MCU. lightsleep stops the clocks and keeps RAM."""
    if DEBUG:
        time.sleep(seconds)
    else:
        machine.lightsleep(int(seconds * 1000))

# ----------------- LoRa-E5 (UART1) -----------------
lora = UART(1, baudrate=9600, tx=Pin(4), rx=Pin(5))
_joined = False

def at(cmd, wait_ms=500):
    while lora.any():
        lora.read()                          # drop stale output
    lora.write(cmd + "\r\n")
    time.sleep_ms(wait_ms)
    resp = b""
    while lora.any():
        resp += lora.read()
    txt = resp.decode("utf-8", "ignore").strip()
    print(">", cmd, "->", txt.replace("\r\n", " | "))
    return txt

def lora_setup():
    if "OK" not in at("AT"):
        print("WARNING: LoRa-E5 not responding")
    at("AT+MODE=LWOTAA")
    at("AT+DR=" + BAND)
    at("AT+ADR=OFF")
    at("AT+DR=5")                       # SF7
    at("AT+CH=NUM," + CHANNELS)
    at('AT+ID=DevEui,"%s"' % DEV_EUI)
    at('AT+ID=AppEui,"%s"' % APP_EUI)
    at('AT+KEY=APPKEY,"%s"' % APP_KEY)
    if TX_POWER_DBM is not None:
        at("AT+POWER=%d" % TX_POWER_DBM)   # [power] optional lower TX power

def lora_join(timeout_s=30):
    global _joined
    at("AT+JOIN", wait_ms=200)
    end = time.ticks_add(time.ticks_ms(), timeout_s * 1000)
    buf = ""
    while time.ticks_diff(end, time.ticks_ms()) > 0:
        if lora.any():
            buf += lora.read().decode("utf-8", "ignore")
            if "joined" in buf.lower():
                print("JOINED"); _joined = True; return True
            if "failed" in buf.lower():
                print("join failed"); _joined = False; return False
        time.sleep_ms(200)
    print("join timeout"); _joined = False; return False

def lora_wake():
    """[power] Any UART traffic wakes the E5; 4 x 0xFF is the documented sequence."""
    global LORA_SLEEP
    if not LORA_SLEEP:
        return
    lora.write(b"\xff\xff\xff\xff")
    time.sleep_ms(50)
    for _ in range(3):
        if "OK" in at("AT", 300):
            return
        time.sleep_ms(200)
    print("WARNING: E5 did not wake; disabling module sleep")
    LORA_SLEEP = False

def lora_sleep():
    """[power] Sleep the E5 until the next uplink; the join/session survives."""
    global LORA_SLEEP
    if not LORA_SLEEP:
        return
    if "SLEEP" not in at("AT+LOWPOWER", 300).upper():
        print("WARNING: AT+LOWPOWER not acknowledged; disabling module sleep")
        LORA_SLEEP = False

def lora_send(hexstr, port=1, timeout_ms=8000):
    """[power] Wake, send, wait only until the module reports Done, sleep."""
    global _joined
    lora_wake()
    if not _joined:
        lora_join(timeout_s=20)
    if _joined:
        at("AT+PORT=%d" % port, 200)
        while lora.any():
            lora.read()
        lora.write('AT+MSGHEX="%s"\r\n' % hexstr)
        end = time.ticks_add(time.ticks_ms(), timeout_ms)
        buf = b""
        while time.ticks_diff(end, time.ticks_ms()) > 0:
            if lora.any():
                buf += lora.read()
                if b"Done" in buf:
                    break
                if b"Please join" in buf or b"not joined" in buf.lower():
                    _joined = False
                    break
            time.sleep_ms(50)
        print("> AT+MSGHEX ->", buf.decode("utf-8", "ignore").strip().replace("\r\n", " | "))
    else:
        print("not joined - uplink skipped")
    lora_sleep()

# ----------------- SHT30 (I2C1) -----------------
i2c = I2C(1, sda=Pin(2), scl=Pin(3), freq=100000)
SHT30_ADDR = 0x44

def read_sht30():
    try:
        i2c.writeto(SHT30_ADDR, b'\x2C\x06')   # high-repeatability single shot
        time.sleep_ms(20)
        d = i2c.readfrom(SHT30_ADDR, 6)
        t_raw = (d[0] << 8) | d[1]
        h_raw = (d[3] << 8) | d[4]
        temp = -45 + (175 * t_raw / 65535.0)
        hum  = 100 * h_raw / 65535.0
        return temp, hum
    except Exception as e:
        print("SHT30 error:", e)
        return 0.0, 0.0

# ----------------- soil moisture (ADC0 / GP26) -----------------
soil = ADC(Pin(26))

def read_soil_pct():
    raw = soil.read_u16()
    pct = (SOIL_AIR - raw) * 100 / (SOIL_AIR - SOIL_WATER)
    if pct < 0: pct = 0
    if pct > 100: pct = 100
    return int(pct)

# ----------------- NEO-6M GPS (UART0) -----------------
gps = UART(0, baudrate=9600, tx=Pin(0), rx=Pin(1))

# UBX-RXM-PMREQ: duration 0 (indefinite), flags bit1 = backup mode.
_UBX_PMREQ_BACKUP = bytes([0xB5, 0x62, 0x02, 0x41, 0x08, 0x00,
                           0x00, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x4D, 0x3B])

def gps_backup():
    """[power] Receiver core off; RAM/RTC kept, so the next start is warm.
    Verify on the bench: NMEA output should stop within a second."""
    if GPS_BACKUP:
        gps.write(_UBX_PMREQ_BACKUP)
        time.sleep_ms(200)
        while gps.any():
            gps.read()

def gps_wake():
    """[power] Traffic on the receiver's RX line wakes it from backup mode.
    If your board does not resume NMEA output after this, switch gps_backup()
    to a timed request (duration = FIX_EVERY * SEND_INTERVAL_S * 1000 ms)."""
    gps.write(b"\xff\xff\xff\xff")
    time.sleep_ms(500)

def read_gps(timeout_ms=1500):
    """Parse GPGGA/GNGGA for lat, lon (decimal degrees). Returns (lat, lon)."""
    end = time.ticks_add(time.ticks_ms(), timeout_ms)
    lat = lon = 0.0
    while time.ticks_diff(end, time.ticks_ms()) > 0:
        if gps.any():
            try:
                line = gps.readline()
                if not line:
                    continue
                s = line.decode("ascii", "ignore").strip()
                if "GGA" in s:
                    p = s.split(",")
                    if len(p) > 6 and p[2] and p[4] and p[6] != "0":   # p[6]: fix quality
                        lat = _nmea_deg(p[2], p[3], 2)
                        lon = _nmea_deg(p[4], p[5], 3)
                        return lat, lon
            except Exception:
                pass
    return lat, lon

def _nmea_deg(val, hemi, deg_digits):
    # ddmm.mmmm / dddmm.mmmm -> decimal degrees
    if not val:
        return 0.0
    dot = val.find(".")
    deg = int(val[:dot-2])
    minutes = float(val[dot-2:])
    dec = deg + minutes / 60.0
    if hemi in ("S", "W"):
        dec = -dec
    return dec

def get_fix(timeout_s=FIX_TIMEOUT_S):
    """[power] Wake the receiver, wait for a valid fix, put it back to sleep."""
    gps_wake()
    end = time.ticks_add(time.ticks_ms(), timeout_s * 1000)
    lat = lon = 0.0
    while time.ticks_diff(end, time.ticks_ms()) > 0:
        lat, lon = read_gps(1500)
        if lat and lon:
            break
    gps_backup()
    print("fix: %.6f %.6f" % (lat, lon) if lat and lon else "no fix within timeout")
    return lat, lon

# ----------------- A02YYUW ultrasonic (PIO RX UART on GP16) -----------------
# Frame: 0xFF, dist_high, dist_low, checksum = (0xFF + high + low) & 0xFF.
# If you already have a working PIO reader, paste it over this block and keep
# the read_distance_mm() name.
A02_PIN, A02_BAUD = 16, 9600

@rp2.asm_pio(autopush=True, push_thresh=8, in_shiftdir=rp2.PIO.SHIFT_RIGHT,
             fifo_join=rp2.PIO.JOIN_RX)
def _uart_rx():
    wait(0, pin, 0)             # start bit
    set(x, 7)             [10]  # centre of first data bit
    label("bitloop")
    in_(pins, 1)
    jmp(x_dec, "bitloop") [6]   # 8 cycles per bit

_a02 = rp2.StateMachine(0, _uart_rx, freq=8 * A02_BAUD, in_base=Pin(A02_PIN, Pin.IN, Pin.PULL_UP))
_a02.active(1)

def read_distance_mm(timeout_ms=1200):
    end = time.ticks_add(time.ticks_ms(), timeout_ms)
    buf = bytearray()
    while _a02.rx_fifo():          # drop whatever accumulated while we slept
        _a02.get()
    while time.ticks_diff(end, time.ticks_ms()) > 0:
        if _a02.rx_fifo():
            buf.append((_a02.get() >> 24) & 0xFF)
            while len(buf) >= 4:
                if buf[0] == 0xFF and ((0xFF + buf[1] + buf[2]) & 0xFF) == buf[3]:
                    return (buf[1] << 8) | buf[2]
                buf.pop(0)
        else:
            time.sleep_ms(5)
    return 0

# ----------------- payload builders -----------------
def build_payload(temp, hum, soil_pct, dist_mm):
    t = int(round(temp * 100))
    if t < 0: t += 65536
    h = int(round(hum * 100)) & 0xFFFF
    d = dist_mm & 0xFFFF
    b = bytes([
        (t >> 8) & 0xFF, t & 0xFF,
        (h >> 8) & 0xFF, h & 0xFF,
        soil_pct & 0xFF,
        (d >> 8) & 0xFF, d & 0xFF,
    ])
    return "".join("%02X" % x for x in b)

def build_location(lat, lon):
    la = int(round(lat * 1_000_000))
    if la < 0: la += 4294967296
    lo = int(round(lon * 1_000_000))
    if lo < 0: lo += 4294967296
    b = bytes([
        (la >> 24) & 0xFF, (la >> 16) & 0xFF, (la >> 8) & 0xFF, la & 0xFF,
        (lo >> 24) & 0xFF, (lo >> 16) & 0xFF, (lo >> 8) & 0xFF, lo & 0xFF,
    ])
    return "".join("%02X" % x for x in b)

# ----------------- main -----------------
POWER_ON_DELAY_S = 3               # let the LoRa-E5 and GPS finish booting before we talk to them
time.sleep(POWER_ON_DELAY_S)
print("Configuring LoRa-E5...")
lora_setup()
for _try in range(3):
    if lora_join():
        break
    time.sleep(10)
if not _joined:
    print("Could not join; will retry at each cycle")

print("Acquiring GPS fix (up to %d s)..." % FIX_TIMEOUT_S)
lat, lon = get_fix()
if lat and lon:
    lora_send(build_location(lat, lon), port=2)
else:
    lora_sleep()

print("Sensor loop: uplink every %d s, fix refresh every %d cycles" % (SEND_INTERVAL_S, FIX_EVERY))
cycles = 0
while True:
    temp, hum = read_sht30()
    soil_pct  = read_soil_pct()
    dist_mm   = read_distance_mm()

    payload = build_payload(temp, hum, soil_pct, dist_mm)
    print("T=%.2fC H=%.1f%% soil=%d%% dist=%dmm  payload=%s" %
          (temp, hum, soil_pct, dist_mm, payload))
    lora_send(payload, port=1)

    cycles += 1
    if cycles % FIX_EVERY == 0:                       # [power] daily position refresh
        lat, lon = get_fix()
        if lat and lon:
            lora_send(build_location(lat, lon), port=2)

    zzz(SEND_INTERVAL_S)                              # [power] MCU asleep until next sample

# ============================================================================
# MATCHING ChirpStack codec (Device Profile -> Codec -> JavaScript functions):
#
# function decodeUplink(input) {
#   var b = input.bytes;
#   function s16(hi, lo) { var v = hi * 256 + lo; return v > 32767 ? v - 65536 : v; }
#   function s32(a, b_, c, d) { var v = ((a * 16777216) + (b_ * 65536) + (c * 256) + d);
#                               return v > 2147483647 ? v - 4294967296 : v; }
#   if (input.fPort === 2) {
#     if (b.length < 8) { return { data: {}, errors: ["expected 8 bytes"] }; }
#     return { data: { latitude:  s32(b[0], b[1], b[2], b[3]) / 1e6,
#                      longitude: s32(b[4], b[5], b[6], b[7]) / 1e6 } };
#   }
#   if (b.length < 7) { return { data: {}, errors: ["expected 7 bytes"] }; }
#   return { data: { temperature: s16(b[0], b[1]) / 100.0,
#                    humidity:    (b[2] * 256 + b[3]) / 100.0,
#                    soil_moisture: b[4],
#                    distance:    b[5] * 256 + b[6] } };
# }
# function encodeDownlink(input) { return { bytes: [] }; }
# ============================================================================