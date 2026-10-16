///|
/// P3 布局子集的黑盒测试：宽度、上标、缩放建议。

///|
test "带圈字符按全角 1em 计宽" {
  assert_eq(@layout.char_width_em('①'), 1.0)
  assert_eq(@layout.char_width_em('㉟'), 1.0)
  assert_eq(@layout.char_width_em('㊿'), 1.0)
  assert_eq(@layout.char_width_em('⓪'), 1.0)
  assert_eq(@layout.char_width_em('a'), 0.5)
  assert_eq(@layout.measure_text("①"), 1.0)
  assert_eq(@layout.measure_text("⑤①"), 2.0)
  assert_eq(@layout.measure_text("①⓪⓪⓪"), 4.0)
}

///|
test "上标基线抬升为正" {
  assert_true(@layout.SUPERSCRIPT_DY_EM > 0.0)
}

///|
test "mark 过宽时建议缩放，否则 1.0" {
  assert_eq(@layout.suggest_mark_scale("①", 2.0), 1.0)
  assert_eq(@layout.suggest_mark_scale("①⓪⓪⓪", 2.0), 0.5)
  assert_eq(@layout.suggest_mark_scale("①⓪⓪⓪", 4.0), 1.0)
}

///|
test "layout_note_mark 端到端" {
  let doc = @doc.Document::new()
  let props = @core.make_note_props(
    num_fmt=@core.NumFormat::decimal_enclosed_circle(),
    num_start=1,
  )
  // 第 51 条脚注 → mark "⑤①"，2em 宽
  let mut id = 0
  let mut i = 0
  while i < 51 {
    id = doc.add_note(@core.NoteKind::footnote(), "t", "")
    i += 1
  }
  let placed = @layout.layout_note_mark(doc, id, props, 10.0, 4.0)
  assert_eq(placed.text, "⑤①")
  assert_eq(placed.x, 10.0)
  assert_eq(placed.dy, @layout.SUPERSCRIPT_DY_EM)
  assert_eq(placed.width, 2.0)
  assert_eq(placed.scale, 1.0)
  // 宽度受限时缩放
  let small = @layout.layout_note_mark(doc, id, props, 0.0, 1.0)
  assert_eq(small.scale, 0.5)
  assert_eq(small.width, 1.0)
}
