///|
/// zip 读写测试：writer→reader 回环 + 读取 Python 生成的 deflated 包。

///|
fn bytes_of(s : String) -> Bytes {
  let bs : Array[Byte] = []
  for c in s.to_array() {
    bs.push(c.to_int().to_byte())
  }
  Bytes::from_array(bs[:])
}

///|
test "writer→reader 回环（stored）" {
  let entries : Array[(String, Bytes)] = [
    ("hello.txt", bytes_of("Hello")),
    ("word/document.xml", bytes_of("<w:document/>")),
  ]
  let packed = @zip.write_zip(entries)
  match @zip.read_zip(packed) {
    Some(back) => {
      assert_eq(back.length(), 2)
      assert_eq(back[0].name, "hello.txt")
      assert_eq(back[1].name, "word/document.xml")
      // 内容比对
      let d0 = back[0].data
      assert_eq(d0.length(), 5)
      assert_eq(d0[0], 72) // 'H'
    }
    None => assert_true(false)
  }
}

///|
test "read_zip_text 文本回环" {
  let entries : Array[(String, String)] = [
    ("a.txt", "你好"),
    ("b.txt", "world"),
  ]
  let packed = @zip.write_zip_text(entries)
  match @zip.read_zip_text(packed) {
    Some(back) => {
      assert_eq(back.length(), 2)
      let (n0, t0) = back[0]
      assert_eq(n0, "a.txt")
      assert_eq(t0, "你好")
      let (n1, t1) = back[1]
      assert_eq(n1, "b.txt")
      assert_eq(t1, "world")
    }
    None => assert_true(false)
  }
}

///|
test "读取 Python 生成的 deflated 包" {
  // 生成脚本：
  //   zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED)
  //   z.writestr("a.txt", "hello deflate world, hello deflate world")
  //   z.writestr("word/document.xml", "<w:document>...</w:document>")
  let raw = [
    80, 75, 3, 4, 20, 0, 0, 0, 8, 0, 106, 108, 80, 93, 88, 33, 173, 23, 26, 0, 0,
    0, 40, 0, 0, 0, 5, 0, 0, 0, 97, 46, 116, 120, 116, 203, 72, 205, 201, 201, 87,
    72, 73, 77, 203, 73, 44, 73, 85, 40, 207, 47, 202, 73, 209, 81, 200, 192, 20,
    4, 0, 80, 75, 3, 4, 20, 0, 0, 0, 8, 0, 106, 108, 80, 93, 146, 204, 26, 83, 42,
    0, 0, 0, 66, 0, 0, 0, 17, 0, 0, 0, 119, 111, 114, 100, 47, 100, 111, 99, 117,
    109, 101, 110, 116, 46, 120, 109, 108, 179, 41, 183, 74, 201, 79, 46, 205, 77,
    205, 43, 177, 179, 41, 183, 74, 202, 79, 169, 4, 209, 5, 32, 162, 196, 46, 35,
    211, 70, 31, 68, 131, 200, 2, 48, 9, 81, 160, 143, 164, 11, 0, 80, 75, 1, 2,
    20, 3, 20, 0, 0, 0, 8, 0, 106, 108, 80, 93, 88, 33, 173, 23, 26, 0, 0, 0, 40,
    0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 128, 1, 0, 0, 0, 0, 97, 46, 116,
    120, 116, 80, 75, 1, 2, 20, 3, 20, 0, 0, 0, 8, 0, 106, 108, 80, 93, 146, 204,
    26, 83, 42, 0, 0, 0, 66, 0, 0, 0, 17, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 128, 1,
    61, 0, 0, 0, 119, 111, 114, 100, 47, 100, 111, 99, 117, 109, 101, 110, 116, 46,
    120, 109, 108, 80, 75, 5, 6, 0, 0, 0, 0, 2, 0, 2, 0, 114, 0, 0, 0, 150, 0, 0,
    0, 0, 0,
  ]
  let bs : Array[Byte] = []
  for b in raw {
    bs.push(b.to_byte())
  }
  match @zip.read_zip_text(Bytes::from_array(bs[:])) {
    Some(back) => {
      assert_eq(back.length(), 2)
      let (n0, t0) = back[0]
      assert_eq(n0, "a.txt")
      assert_eq(t0, "hello deflate world, hello deflate world")
      let (n1, t1) = back[1]
      assert_eq(n1, "word/document.xml")
      assert_true(t1.length() > 0)
    }
    None => assert_true(false)
  }
}

///|
test "损坏的包返回 None" {
  match @zip.read_zip(bytes_of("not a zip")) {
    None => assert_true(true)
    Some(_) => assert_true(false)
  }
}
