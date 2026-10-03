function decodeUplink(input) {
  var b = input.bytes;
  if (b.length < 5) { return { data: {}, errors: ["expected 5 bytes"] }; }
  var insect_count = (b[0] * 256) + b[1];
  var max_conf = b[2] / 100.0;
  var lux = (b[3] * 256) + b[4];
  return { data: { insect_count: insect_count, max_conf: max_conf, lux: lux } };
}
function encodeDownlink(input) { return { bytes: [] }; }