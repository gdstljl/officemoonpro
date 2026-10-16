///|
/// docx 编解码的黑盒测试：编号格式名、脚注片段、引用片段、settings。
/// XML 形状对标 Rust `crates/docx/tests/fixtures.rs`。

///|
test "numfmt 映射：已知往返，未知回退 decimal" {
  assert_eq(
    @docx.numfmt_to_ooxml(@core.NumFormat::decimal_enclosed_circle()),
    "decimalEnclosedCircle",
  )
  assert_eq(
    @docx.numfmt_to_ooxml(@core.NumFormat::decimal_enclosed_circle_chinese()),
    "decimalEnclosedCircleChinese",
  )
  assert_eq(
    @docx.numfmt_to_ooxml(@docx.numfmt_from_ooxml("decimalEnclosedCircle")),
    "decimalEnclosedCircle",
  )
  // 未知名字回退 decimal（对标 Rust from_ooxml）
  assert_eq(
    @docx.numfmt_to_ooxml(@docx.numfmt_from_ooxml("notAFormat")),
    "decimal",
  )
}

///|
test "numbering 解析与往返：格式名不变" {
  // 形状仿 fixtures.rs east_asian 用例
  let numbering = "<w:numbering><w:abstractNum w:abstractNumId=\"0\">" +
    "<w:lvl w:ilvl=\"0\"><w:start w:val=\"1\"/><w:numFmt w:val=\"decimal\"/></w:lvl>" +
    "<w:lvl w:ilvl=\"1\"><w:start w:val=\"1\"/><w:numFmt w:val=\"decimalEnclosedCircle\"/></w:lvl>" +
    "<w:lvl w:ilvl=\"2\"><w:start w:val=\"1\"/><w:numFmt w:val=\"notAFormat\"/></w:lvl>" +
    "</w:abstractNum><w:num w:numId=\"1\"><w:abstractNumId w:val=\"0\"/></w:num></w:numbering>"
  let levels = @docx.parse_numbering(numbering)
  assert_eq(levels.length(), 3)
  assert_eq(@docx.numfmt_to_ooxml(levels[1].num_fmt), "decimalEnclosedCircle")
  assert_eq(@docx.numfmt_to_ooxml(levels[2].num_fmt), "decimal")
  // 往返：build → parse，格式名不变
  let back = @docx.parse_numbering(@docx.build_numbering(levels))
  assert_eq(back.length(), 3)
  assert_eq(@docx.numfmt_to_ooxml(back[1].num_fmt), "decimalEnclosedCircle")
}

///|
test "footnotes 解析与往返" {
  let xml = "<w:footnotes>" +
    "<w:footnote w:type=\"separator\" w:id=\"-1\"><w:p><w:r><w:separator/></w:r></w:p></w:footnote>" +
    "<w:footnote w:id=\"2\"><w:p><w:r><w:footnoteRef/></w:r><w:r><w:t>note text</w:t></w:r></w:p></w:footnote>" +
    "</w:footnotes>"
  let entries = @docx.parse_footnotes(xml)
  assert_eq(entries.length(), 2)
  assert_eq(entries[0].fid, -1)
  assert_eq(entries[0].note_type, "separator")
  assert_eq(entries[1].fid, 2)
  assert_eq(entries[1].text, "note text")
  // 往返
  let back = @docx.parse_footnotes(@docx.build_note_part(entries, true))
  assert_eq(back.length(), 2)
  assert_eq(back[0].note_type, "separator")
  assert_eq(back[1].text, "note text")
}

///|
test "document 引用解析与生成（含 customMarkFollows）" {
  let xml = "<w:p><w:r><w:t>正文</w:t></w:r>" +
    "<w:r><w:footnoteReference w:id=\"2\"/></w:r>" +
    "<w:r><w:footnoteReference w:customMarkFollows=\"1\" w:id=\"3\"/><w:t xml:space=\"preserve\">※</w:t></w:r>" +
    "<w:r><w:endnoteReference w:id=\"4\"/></w:r></w:p>"
  let refs = @docx.parse_doc_refs(xml)
  assert_eq(refs.length(), 3)
  assert_eq(refs[0].fid, 2)
  assert_eq(refs[0].custom_mark_follows, false)
  assert_eq(refs[1].custom_mark_follows, true)
  assert_eq(refs[1].custom_text, "※")
  assert_eq(refs[2].fid, 4)
  // 生成后重新解析：引用数量与 custom 标记一致
  let back = @docx.parse_doc_refs(@docx.build_doc_paragraph("正文", refs))
  assert_eq(back.length(), 3)
  assert_eq(back[1].custom_mark_follows, true)
  assert_eq(back[1].custom_text, "※")
  assert_eq(back[2].fid, 4)
}

///|
test "settings numFmt 解析与往返" {
  let xml = "<w:settings><w:footnotePr><w:numFmt w:val=\"decimalEnclosedCircle\"/></w:footnotePr></w:settings>"
  match @docx.parse_settings_numfmt(xml, true) {
    Some(f) => assert_eq(@docx.numfmt_to_ooxml(f), "decimalEnclosedCircle")
    None => assert_true(false)
  }
  let built = @docx.build_settings_numfmt(
    @core.NumFormat::decimal_enclosed_circle(),
    true,
  )
  match @docx.parse_settings_numfmt(built, true) {
    Some(f) => assert_eq(@docx.numfmt_to_ooxml(f), "decimalEnclosedCircle")
    None => assert_true(false)
  }
  // 缺失返回 None
  match @docx.parse_settings_numfmt("<w:settings/>", true) {
    None => assert_true(true)
    Some(_) => assert_true(false)
  }
}

///|
test "62 种格式 OOXML 名往返" {
  for f in @core.all_num_formats {
    let name = @docx.numfmt_to_ooxml(f)
    let back = @docx.numfmt_from_ooxml(name)
    assert_eq(@docx.numfmt_to_ooxml(back), name)
  }
}
