///|
/// inflate 测试：解压数据由 Python zlib 生成（见下方注释），交叉验证正确性。

///|
fn assert_int_array_eq(a : Array[Int32], b : Array[Int32]) -> Unit raise {
  assert_eq(a.length(), b.length())
  let mut i = 0
  while i < a.length() {
    assert_eq(a[i], b[i])
    i += 1
  }
}

///|
fn repeat_bytes(s : String, n : Int32) -> Array[Int32] {
  let out : Array[Int32] = []
  let mut k = 0
  while k < n {
    for c in s.to_array() {
      out.push(c.to_int())
    }
    k += 1
  }
  out
}

// 生成脚本：
//   import zlib
//   raw = zlib.compress(data, 6)[2:-4]  # 去掉 zlib 头尾，得原始 deflate 流

///|
test "inflate 短文本（fixed Huffman）" {
  // plain: b"Hello, World!"
  let deflate = [243, 72, 205, 201, 201, 215, 81, 8, 207, 47, 202, 73, 81, 4, 0]
  let plain = [72, 101, 108, 108, 111, 44, 32, 87, 111, 114, 108, 100, 33]
  match @zip.inflate(deflate) {
    Some(out) => assert_int_array_eq(out, plain)
    None => assert_true(false)
  }
}

///|
test "inflate 长重复文本（dynamic Huffman + 长距离回指）" {
  // plain: b"The quick brown fox jumps over the lazy dog. " * 60（2700 字节）
  let deflate = [
    237, 202, 71, 1, 128, 48, 16, 69, 65, 43, 95, 1, 106, 98, 128, 146, 208, 217,
    16, 8, 77, 61, 136, 224, 248, 206, 51, 174, 243, 90, 115, 95, 143, 170, 146,
    157, 139, 130, 93, 26, 242, 28, 55, 217, 225, 147, 246, 143, 167, 242, 185, 213,
    88, 91, 200, 145, 201, 100, 50, 153, 76, 38, 147, 201, 255, 229, 23,
  ]
  let plain = repeat_bytes("The quick brown fox jumps over the lazy dog. ", 60)
  match @zip.inflate(deflate) {
    Some(out) => assert_int_array_eq(out, plain)
    None => assert_true(false)
  }
}

///|
test "inflate 数字重复" {
  // plain: b"0123456789" * 100（1000 字节）
  let deflate = [
    51, 48, 52, 50, 54, 49, 53, 51, 183, 176, 52, 24, 101, 141, 178, 70, 89, 195,
    148, 5, 0,
  ]
  let plain = repeat_bytes("0123456789", 100)
  match @zip.inflate(deflate) {
    Some(out) => assert_int_array_eq(out, plain)
    None => assert_true(false)
  }
}

///|
test "inflate stored 块" {
  // 手工构造：bfinal=1, btype=00, LEN=2, NLEN=~2, 数据 "Hi"
  let stored = [0x01, 0x02, 0x00, 0xFD, 0xFF, 0x48, 0x69]
  match @zip.inflate(stored) {
    Some(out) => assert_int_array_eq(out, [0x48, 0x69])
    None => assert_true(false)
  }
}

///|
test "inflate 损坏输入返回 None" {
  match @zip.inflate([]) {
    None => assert_true(true)
    Some(_) => assert_true(false)
  }
  match @zip.inflate([0xFF, 0xFF, 0xFF]) {
    None => assert_true(true)
    Some(_) => assert_true(false)
  }
  // stored 块长度校验失败
  match @zip.inflate([0x01, 0x02, 0x00, 0x00, 0x00, 0x48, 0x69]) {
    None => assert_true(true)
    Some(_) => assert_true(false)
  }
}
