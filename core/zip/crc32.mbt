///|
/// CRC-32（IEEE 802.3），zip 条目校验用。
/// 用 UInt 计算以保证逻辑右移。

///|
pub fn crc32(data : Array[Int32]) -> UInt32 {
  let mut crc : UInt32 = 0xFFFFFFFF
  for b in data {
    crc = crc ^ b.reinterpret_as_uint()
    let mut k = 0
    while k < 8 {
      crc = if (crc & 1) == 1 { (crc >> 1) ^ 0xEDB88320 } else { crc >> 1 }
      k += 1
    }
  }
  crc ^ 0xFFFFFFFF
}
