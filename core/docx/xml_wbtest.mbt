///|
/// XML 解析器的白盒测试：直接检查节点字段。

///|
test "属性与子元素结构" {
  let n = parse_xml(
    "<w:lvl w:ilvl=\"3\"><w:numFmt w:val=\"decimalEnclosedCircle\"/></w:lvl>",
  ).unwrap()
  assert_eq(n.name, "w:lvl")
  assert_eq(n.attrs.length(), 1)
  assert_eq(n.attrs[0].name, "w:ilvl")
  assert_eq(n.attrs[0].value, "3")
  assert_eq(n.children.length(), 1)
  assert_eq(n.children[0].name, "w:numFmt")
}

///|
test "accessors" {
  let n = parse_xml("<w:p><w:r><w:t>x</w:t></w:r><w:r><w:t>y</w:t></w:r></w:p>").unwrap()
  assert_eq(n.descendant_texts("w:t"), "xy")
  assert_eq(n.find_all("w:r").length(), 2)
  match n.child("w:r") {
    Some(r) => assert_eq(r.descendant_texts("w:t"), "x")
    None => assert_true(false)
  }
  match n.attr("w:foo") {
    None => assert_true(true)
    Some(_) => assert_true(false)
  }
}
