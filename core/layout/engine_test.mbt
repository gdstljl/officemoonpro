///|
/// 排版引擎测试：断行、禁则、分页、脚注区、字体回退。

///|
fn line_texts(line : Array[@layout.Token]) -> String {
  let sb = StringBuilder()
  for t in line {
    sb.write_string(t.text)
  }
  sb.to_string()
}

///|
test "CJK 逐字断行" {
  let lines = @layout.break_lines(@layout.tokenize("你好世界"), 2.5)
  assert_eq(lines.length(), 2)
  assert_eq(line_texts(lines[0]), "你好")
  assert_eq(line_texts(lines[1]), "世界")
}

///|
test "拉丁文不断词内" {
  // "hello world"：行宽 3em 放不下 "hello"(2.5em)+" "(0.5em)+"world"(2.5em)
  let lines = @layout.break_lines(@layout.tokenize("hello world"), 5.0)
  assert_eq(lines.length(), 2)
  assert_eq(line_texts(lines[0]), "hello")
  assert_eq(line_texts(lines[1]), "world")
}

///|
test "禁则：句点不另起行" {
  // 行宽 2em："你好"占满，"。"放不下但 no_break_before，应强制跟上行
  let lines = @layout.break_lines(@layout.tokenize("你好。"), 2.0)
  assert_eq(lines.length(), 1)
  assert_eq(line_texts(lines[0]), "你好。")
}

///|
test "禁则：前括号不留行尾" {
  // "你好（世界）"行宽 3em：你/好/（占 3em，"（" no_break_after，
  // 下一个"世"放不下但可断（"（"后不可断 → "世"强制跟上？不——
  // "世" no_break_before=false，前一个"是（" no_break_after=true → 不可断 → 强制放入）
  let lines = @layout.break_lines(@layout.tokenize("你好（世"), 3.0)
  assert_eq(lines.length(), 1)
}

///|
test "行首空格丢弃" {
  let lines = @layout.break_lines(@layout.tokenize("ab cd"), 1.5)
  assert_eq(lines.length(), 2)
  assert_eq(line_texts(lines[1]), "cd")
}

///|
test "字体回退" {
  assert_eq(@layout.font_for_char('a'), "Calibri")
  assert_eq(@layout.font_for_char('①'), "SimSun")
  assert_eq(@layout.font_for_char('中'), "SimSun")
  assert_eq(@layout.font_for_char('あ'), "MS Mincho")
  assert_eq(@layout.font_for_char('한'), "Malgun Gothic")
}

///|
test "整文档排版：分页与脚注区" {
  let doc = @doc.Document::new()
  // 每段 10 个字，行宽 4em → 每段 3 行（4+4+2）
  let p1 = doc.add_paragraph("一二三四五六七八九十")
  let f1 = @engine.insert_footnote(doc, p1, "脚注一", "")
  let _ = doc.add_paragraph("甲乙丙丁戊己庚辛壬癸")
  let props = @core.make_note_props(
    num_fmt=@core.NumFormat::decimal_enclosed_circle(),
    num_start=1,
  )
  let spec = @layout.make_page_spec(
    width_em=10.0,
    height_em=10.0,
    margin_left_em=3.0,
    margin_right_em=3.0,
    margin_top_em=1.0,
    margin_bottom_em=1.0,
    line_height_em=2.0,
    footnote_area_em=2.0,
  )
  // body 高度 = 10-1-1-2 = 6 → 每页 3 行；共 6 行 → 2 页
  let pages = @layout.layout_document(doc, spec, props)
  assert_eq(pages.length(), 2)
  assert_eq(pages[0].lines.length(), 3)
  assert_eq(pages[1].lines.length(), 3)
  // 第一页有脚注
  assert_eq(pages[0].footnotes.length(), 1)
  assert_eq(pages[0].footnotes[0].mark, "①")
  assert_eq(pages[0].footnotes[0].text, "脚注一")
  assert_eq(pages[1].footnotes.length(), 0)
  // 上标定位
  let mut has_super = false
  for line in pages[0].lines {
    for r in line.runs {
      if r.dy > 0.0 {
        has_super = true
      }
    }
  }
  assert_true(has_super)
  let _ = f1
}
