///|
/// CRC32 已知向量（IEEE 802.3）。

///|
fn crc_bytes_of(s : String) -> Array[Int32] {
  let out : Array[Int32] = []
  for c in s.to_array() {
    out.push(c.to_int())
  }
  out
}

///|
test "crc32 空串" {
  assert_true(@zip.crc32([]) == 0)
}

///|
test "crc32 123456789" {
  assert_true(@zip.crc32(crc_bytes_of("123456789")) == 0xCBF43926)
}

///|
test "crc32 hello" {
  assert_true(@zip.crc32(crc_bytes_of("hello")) == 0x3610A686)
}
