///|
/// 文档模型的黑盒测试。

///|
test "段落纯文本跳过行内对象" {
  let doc = @doc.Document::new()
  let p = doc.add_paragraph("hello")
  assert_eq(p, 0)
  assert_eq(doc.paragraph_count(), 1)
  assert_eq(doc.get_paragraph(0).plain_text(), "hello")
  doc.push_object(0, @doc.make_noteref(@core.NoteKind::footnote(), 1, ""))
  // NoteRef 不占纯文本，但结构里多了一个行内元素
  assert_eq(doc.get_paragraph(0).plain_text(), "hello")
  assert_eq(doc.get_paragraph(0).inline_count(), 2)
  assert_true(doc.get_paragraph(0).inline_is_noteref(1))
}

///|
test "脚注自动编号按 kind 独立计数" {
  let doc = @doc.Document::new()
  let props = @core.make_note_props(
    num_fmt=@core.NumFormat::decimal_enclosed_circle(),
    num_start=1,
  )
  let f1 = doc.add_note(@core.NoteKind::footnote(), "first", "")
  let f2 = doc.add_note(@core.NoteKind::footnote(), "second", "")
  let e1 = doc.add_note(@core.NoteKind::endnote(), "end", "")
  assert_eq(doc.note_count(@core.NoteKind::footnote()), 2)
  assert_eq(doc.note_count(@core.NoteKind::endnote()), 1)
  assert_eq(doc.note_mark(f1, props), "①")
  assert_eq(doc.note_mark(f2, props), "②")
  // 尾注独立从 ① 开始
  assert_eq(doc.note_mark(e1, props), "①")
  assert_eq(doc.find_note_text(f2), "second")
  assert_eq(doc.note_mark(999, props), "")
}

///|
test "custom mark 覆盖自动编号" {
  let doc = @doc.Document::new()
  let props = @core.make_note_props(
    num_fmt=@core.NumFormat::decimal_enclosed_circle(),
    num_start=1,
  )
  let id = doc.add_note(@core.NoteKind::footnote(), "t", "※")
  assert_eq(doc.note_mark(id, props), "※")
}
