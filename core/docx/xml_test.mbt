///|
/// XML 解析器/生成器的黑盒测试：只走公开 API。

///|
test "解析写回规范化：空白与自闭合" {
  let norm = @docx.write_xml(
    @docx.parse_xml("<w:p>\n  <w:t>a</w:t>\n</w:p>").unwrap(),
  )
  assert_eq(norm, "<w:p><w:t>a</w:t></w:p>")
}

///|
test "属性单引号与实体" {
  let norm = @docx.write_xml(
    @docx.parse_xml("<w:t xml:space='preserve'>a &amp; b</w:t>").unwrap(),
  )
  assert_eq(norm, "<w:t xml:space=\"preserve\">a &amp; b</w:t>")
}

///|
test "注释与处理指令被跳过" {
  let norm = @docx.write_xml(
    @docx.parse_xml("<?xml version=\"1.0\"?><!-- c --><w:p/>").unwrap(),
  )
  assert_eq(norm, "<w:p/>")
}

///|
test "CDATA 按原文保留" {
  let norm = @docx.write_xml(
    @docx.parse_xml("<w:t><![CDATA[a<b]]></w:t>").unwrap(),
  )
  assert_eq(norm, "<w:t>a&lt;b</w:t>")
}

///|
test "数字字符引用" {
  let norm = @docx.write_xml(@docx.parse_xml("<w:t>&#65;&#x42;</w:t>").unwrap())
  assert_eq(norm, "<w:t>AB</w:t>")
}

///|
test "残缺 XML 返回 None" {
  let bad1 = match @docx.parse_xml("<w:p>") {
    None => true
    Some(_) => false
  }
  assert_true(bad1)
  let bad2 = match @docx.parse_xml("<w:p></w:q>") {
    None => true
    Some(_) => false
  }
  assert_true(bad2)
  let bad3 = match @docx.parse_xml("hello") {
    None => true
    Some(_) => false
  }
  assert_true(bad3)
}

///|
test "parse_int" {
  let eq = fn(a : Int32?, b : Int32?) -> Bool {
    match (a, b) {
      (Some(x), Some(y)) => x == y
      (None, None) => true
      _ => false
    }
  }
  assert_true(eq(@docx.parse_int("42"), Some(42)))
  assert_true(eq(@docx.parse_int("-1"), Some(-1)))
  assert_true(eq(@docx.parse_int("abc"), None))
  assert_true(eq(@docx.parse_int(""), None))
}
