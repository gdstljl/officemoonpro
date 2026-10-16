///|
/// 脚注插入命令的黑盒测试（对标 Rust `note()` 的行为）。

///|
test "插入脚注：正文 NoteRef + 脚注库 + 自动编号" {
  let doc = @doc.Document::new()
  let para = doc.add_paragraph("正文")
  let props = @core.make_note_props(
    num_fmt=@core.NumFormat::decimal_enclosed_circle(),
    num_start=1,
  )
  let id = @engine.insert_footnote(doc, para, "脚注正文", "")
  assert_eq(id, 1)
  // 正文段落末尾多了一个 NoteRef 行内对象
  let p = doc.get_paragraph(para)
  assert_eq(p.inline_count(), 2)
  assert_true(p.inline_is_noteref(1))
  assert_eq(p.plain_text(), "正文")
  // 脚注库与编号
  assert_eq(doc.find_note_text(id), "脚注正文")
  assert_eq(doc.note_mark(id, props), "①")
  // 第二条脚注自动编号 ②
  let id2 = @engine.insert_footnote(doc, para, "第二条", "")
  assert_eq(doc.note_mark(id2, props), "②")
}

///|
test "尾注独立编号" {
  let doc = @doc.Document::new()
  let para = doc.add_paragraph("正文")
  let props = @core.make_note_props(
    num_fmt=@core.NumFormat::decimal_enclosed_circle(),
    num_start=1,
  )
  let f = @engine.insert_footnote(doc, para, "脚注", "")
  let e = @engine.insert_endnote(doc, para, "尾注", "")
  assert_eq(doc.note_mark(f, props), "①")
  assert_eq(doc.note_mark(e, props), "①")
}

///|
test "custom mark 覆盖自动编号" {
  let doc = @doc.Document::new()
  let para = doc.add_paragraph("正文")
  let props = @core.make_note_props(
    num_fmt=@core.NumFormat::decimal_enclosed_circle(),
    num_start=1,
  )
  let id = @engine.insert_footnote(doc, para, "t", "※")
  assert_eq(doc.note_mark(id, props), "※")
}

///|
test "custom mark 清洗：去空白、去控制字符、最多 10 字符" {
  let doc = @doc.Document::new()
  let para = doc.add_paragraph("正文")
  let props = @core.make_note_props(
    num_fmt=@core.NumFormat::decimal_enclosed_circle(),
    num_start=1,
  )
  // 首尾空白去掉，\t 是控制字符去掉，超长截断到 10 个字符
  let id = @engine.insert_footnote(doc, para, "t", "  ab\tcdefghijklmnop  ")
  assert_eq(doc.note_mark(id, props), "abcdefghij")
}
