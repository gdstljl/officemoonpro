///|
/// 页面合成：段落 → 行 → 页（含脚注区），字体回退。
/// 对标计划 P3 扩展：行排、上标、字体回退链子集。

///|
pub struct PageSpec {
  width_em : Double
  height_em : Double
  margin_left_em : Double
  margin_right_em : Double
  margin_top_em : Double
  margin_bottom_em : Double
  line_height_em : Double
  /// 脚注区预留高度（em）
  footnote_area_em : Double
}

///|
/// 跨包构造 PageSpec。
pub fn make_page_spec(
  width_em~ : Double,
  height_em~ : Double,
  margin_left_em~ : Double,
  margin_right_em~ : Double,
  margin_top_em~ : Double,
  margin_bottom_em~ : Double,
  line_height_em~ : Double,
  footnote_area_em~ : Double,
) -> PageSpec {
  PageSpec::{
    width_em,
    height_em,
    margin_left_em,
    margin_right_em,
    margin_top_em,
    margin_bottom_em,
    line_height_em,
    footnote_area_em,
  }
}

///|
/// 默认页面：A4 纵向比例，行宽约 32em。
pub fn default_page_spec() -> PageSpec {
  PageSpec::{
    width_em: 38.0,
    height_em: 54.0,
    margin_left_em: 3.0,
    margin_right_em: 3.0,
    margin_top_em: 3.0,
    margin_bottom_em: 3.0,
    line_height_em: 1.5,
    footnote_area_em: 8.0,
  }
}

///|
pub struct PlacedLine {
  runs : Array[PlacedRun]
  /// 行宽（em）
  width : Double
  /// 基线 y（em，相对页面顶部）
  y : Double
}

///|
pub struct PlacedNote {
  id : Int32
  mark : String
  text : String
}

///|
pub struct PlacedPage {
  lines : Array[PlacedLine]
  footnotes : Array[PlacedNote]
  page_no : Int32
}

///|
/// 字体回退：字符 → 字体名（Word ascii/hAnsi/cs 字体链的子集）。
pub fn font_for_char(c : Char) -> String {
  let code = c.to_int()
  if code < 0x250 {
    "Calibri"
  } else if code >= 0x3040 && code <= 0x30FF {
    "MS Mincho"
  } else if code >= 0xAC00 && code <= 0xD7AF {
    "Malgun Gothic"
  } else if code >= 0x2460 && code <= 0x32FF {
    "SimSun"
  } else if code >= 0x4E00 && code <= 0x9FFF {
    "SimSun"
  } else if code >= 0xFF00 && code <= 0xFFEF {
    "SimSun"
  } else {
    "Segoe UI Symbol"
  }
}

///|
fn paragraph_tokens(
  doc : @doc.Document,
  para_idx : Int32,
  props : @core.NoteProps,
) -> Array[Token] {
  let tokens : Array[Token] = []
  let para = doc.get_paragraph(para_idx)
  let mut ii = 0
  while ii < para.inline_count() {
    let v = para.inline_view(ii)
    if v.is_text {
      for t in tokenize(v.text) {
        tokens.push(t)
      }
    } else {
      // 脚注 mark：原子 token，上标
      let mark = doc.note_mark(v.id, props)
      let w = measure_text(mark) * suggest_mark_scale(mark, 4.0)
      tokens.push(Token::{
        text: mark,
        width: w,
        is_space: false,
        no_break_before: false,
        no_break_after: false,
        is_superscript: true,
        note_id: v.id,
      })
    }
    ii += 1
  }
  tokens
}

///|
fn build_line(
  tokens : Array[Token],
  x0 : Double,
  y : Double,
) -> (PlacedLine, Array[Int32]) {
  let runs : Array[PlacedRun] = []
  let refs : Array[Int32] = []
  let mut x = x0
  for t in tokens {
    runs.push(PlacedRun::{
      text: t.text,
      x,
      dy: if t.is_superscript {
        SUPERSCRIPT_DY_EM
      } else {
        0.0
      },
      width: t.width,
      scale: 1.0,
    })
    x += t.width
    if t.note_id >= 0 && !contains_id(refs, t.note_id) {
      refs.push(t.note_id)
    }
  }
  (PlacedLine::{ runs, width: x - x0, y, }, refs)
}

///|
fn contains_id(arr : Array[Int32], id : Int32) -> Bool {
  for x in arr {
    if x == id {
      return true
    }
  }
  false
}

///|
/// 整文档排版：段落断行 → 行按页高分页 → 每页收集脚注区。
pub fn layout_document(
  doc : @doc.Document,
  spec : PageSpec,
  props : @core.NoteProps,
) -> Array[PlacedPage] {
  let content_width = spec.width_em - spec.margin_left_em - spec.margin_right_em
  let body_height = spec.height_em -
    spec.margin_top_em -
    spec.margin_bottom_em -
    spec.footnote_area_em
  let mut lines_per_page = 0
  let mut h = spec.line_height_em
  while h <= body_height {
    lines_per_page += 1
    h += spec.line_height_em
  }
  if lines_per_page < 1 {
    lines_per_page = 1
  }
  // 1. 全部段落断行
  let all_lines : Array[Array[Token]] = []
  let mut pi = 0
  while pi < doc.paragraph_count() {
    let tokens = paragraph_tokens(doc, pi, props)
    for lt in break_lines(tokens, content_width) {
      all_lines.push(lt)
    }
    pi += 1
  }
  // 2. 分页
  let pages : Array[PlacedPage] = []
  let mut li = 0
  let mut page_no = 1
  while li < all_lines.length() {
    let lines : Array[PlacedLine] = []
    let page_note_ids : Array[Int32] = []
    let mut k = 0
    while k < lines_per_page && li < all_lines.length() {
      let y = spec.margin_top_em + (k.to_double() + 1.0) * spec.line_height_em
      let (pline, refs) = build_line(all_lines[li], spec.margin_left_em, y)
      lines.push(pline)
      for r in refs {
        if !contains_id(page_note_ids, r) {
          page_note_ids.push(r)
        }
      }
      li += 1
      k += 1
    }
    let notes : Array[PlacedNote] = []
    for nid in page_note_ids {
      notes.push(PlacedNote::{
        id: nid,
        mark: doc.note_mark(nid, props),
        text: doc.find_note_text(nid),
      })
    }
    pages.push(PlacedPage::{ lines, footnotes: notes, page_no, })
    page_no += 1
  }
  pages
}
