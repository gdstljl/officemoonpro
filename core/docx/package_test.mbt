///|
/// docx 整包往返：内存文档 → XML 条目 → zip 字节 → 解包 → 文档。
/// 端到端验证带圈编号在真实容器里的保真度。

///|
test "docx 整包往返" {
  // 1. 建文档：段落 + 脚注（自动编号 + custom mark）
  let doc = @doc.Document::new()
  let para = doc.add_paragraph("Hello ")
  let f1 = @engine.insert_footnote(doc, para, "脚注一", "")
  let f2 = @engine.insert_footnote(doc, para, "脚注二", "※")
  let e1 = @engine.insert_endnote(doc, para, "尾注一", "")
  let props = @core.make_note_props(
    num_fmt=@core.NumFormat::decimal_enclosed_circle(),
    num_start=1,
  )
  // 2. 打包
  let pd = @docx.make_package_doc(
    doc,
    @core.NumFormat::decimal_enclosed_circle(),
    @core.NumFormat::decimal(),
    [@docx.make_level_fmt(0, @core.NumFormat::decimal_enclosed_circle())],
  )
  let entries = @docx.write_package(pd)
  let zipped = @zip.write_zip_text(entries)
  // 3. 解包
  let back_entries = match @zip.read_zip_text(zipped) {
    Some(es) => es
    None => {
      assert_true(false)
      []
    }
  }
  let pd2 = match @docx.read_package(back_entries) {
    Some(p) => p
    None => {
      assert_true(false)
      pd
    }
  }
  // 4. 断言
  let doc2 = pd2.doc
  assert_eq(doc2.find_note_text(f1), "脚注一")
  assert_eq(doc2.find_note_text(f2), "脚注二")
  assert_eq(doc2.find_note_text(e1), "尾注一")
  // mark：自动编号 ①，custom ※
  assert_eq(doc2.note_mark(f1, props), "①")
  assert_eq(doc2.note_mark(f2, props), "※")
  // settings 往返
  assert_eq(@docx.numfmt_to_ooxml(pd2.footnote_fmt), "decimalEnclosedCircle")
  assert_eq(@docx.numfmt_to_ooxml(pd2.endnote_fmt), "decimal")
  // numbering 往返
  assert_eq(pd2.numbering.length(), 1)
  assert_eq(
    @docx.numfmt_to_ooxml(pd2.numbering[0].num_fmt),
    "decimalEnclosedCircle",
  )
  // 正文文本往返
  assert_eq(doc2.get_paragraph(para).plain_text(), "Hello ")
}
