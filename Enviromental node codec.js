function decodeUplink(input) {
  var b = input.bytes;
  if (b.length < 15) {
    return { data: {}, errors: ["expected 15 bytes, got " + b.length] };
  }
  var tRaw = (b[0] * 256) + b[1];
  if (tRaw > 32767) {
    tRaw = tRaw - 65536;
  }
  var temperature = tRaw / 100.0;
  var humidity = ((b[2] * 256) + b[3]) / 100.0;
  var soil_moisture = b[4];
  var latRaw = (b[5] * 16777216) + (b[6] * 65536) + (b[7] * 256) + b[8];
  if (latRaw > 2147483647) {
    latRaw = latRaw - 4294967296;
  }
  var latitude = latRaw / 1000000.0;
  var lonRaw = (b[9] * 16777216) + (b[10] * 65536) + (b[11] * 256) + b[12];
  if (lonRaw > 2147483647) {
    lonRaw = lonRaw - 4294967296;
  }
  var longitude = lonRaw / 1000000.0;
  var distance = (b[13] * 256) + b[14];   // A02YYUW ultrasonic, mm
  return {
    data: {
      temperature: temperature,
      humidity: humidity,
      soil_moisture: soil_moisture,
      latitude: latitude,
      longitude: longitude,
      distance: distance
    }
  };
}
function encodeDownlink(input) {
  return { bytes: [] };
}