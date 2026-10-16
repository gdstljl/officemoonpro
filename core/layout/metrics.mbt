///|
/// P3 布局子集：只回答计划 §9 风险 #1——
/// "⑤① 多圈连排在上标脚注里的宽度与基线（layout 阶段才验证）"。
///
/// 不做完整排版引擎（断行、分页不在本期范围），只提供：
/// - 字符 advance 宽度（em）：带圈字按全角 1em 计
/// - 上标基线偏移约定
/// - mark 过宽时的字号回退建议（"若过宽可给脚注 mark 单独字号回退"）

///|
/// 上标基线抬升（em）。Word 上标约为字号的 1/3，此处取 0.33 作约定常量。
pub const SUPERSCRIPT_DY_EM : Double = 0.33

///|
/// 字符 advance 宽度（em）。
/// 带圈数字（①–⑳ U+2460–2473、㉑–㉟ U+3251–325F、㊱–㊿ U+32B1–32BF、⓪ U+24EA）
/// 与 CJK 全角字符按 1em 计；半角 ASCII 按 0.5em 计。
pub fn char_width_em(c : Char) -> Double {
  let code = c.to_int()
  if code >= 0x2460 && code <= 0x2473 {
    1.0
  } else if code >= 0x3251 && code <= 0x325F {
    1.0
  } else if code >= 0x32B1 && code <= 0x32BF {
    1.0
  } else if code == 0x24EA {
    1.0
  } else if code >= 0x3000 && code <= 0x9FFF {
    1.0
  } else if code >= 0xFF00 && code <= 0xFFEF {
    1.0
  } else if code >= 0x20 && code <= 0x7E {
    0.5
  } else {
    0.5
  }
}

///|
/// 文本总宽度（em）。
pub fn measure_text(text : String) -> Double {
  let mut w = 0.0
  for c in text.to_array() {
    w += char_width_em(c)
  }
  w
}

///|
/// mark 字号缩放建议：宽度超限时等比缩小以适应 max_width_em，
/// 否则返回 1.0（对标计划 §9 #1 的"单独字号回退"）。
pub fn suggest_mark_scale(mark : String, max_width_em : Double) -> Double {
  let w = measure_text(mark)
  if w <= max_width_em {
    1.0
  } else {
    max_width_em / w
  }
}

///|
/// 摆放到基线上的一个 run。
pub struct PlacedRun {
  text : String
  /// 起始 x（em）
  x : Double
  /// 基线偏移（em），上标为正
  dy : Double
  /// 缩放后宽度（em）
  width : Double
  /// 应用的字号缩放
  scale : Double
}

///|
/// 摆放一条脚注 mark：解析文本、量宽度、按需缩放、上标抬升。
/// max_width_em：mark 允许的最大宽度（如上标区宽度）。
pub fn layout_note_mark(
  doc : @doc.Document,
  id : Int32,
  props : @core.NoteProps,
  x : Double,
  max_width_em : Double,
) -> PlacedRun {
  let mark = doc.note_mark(id, props)
  let scale = suggest_mark_scale(mark, max_width_em)
  PlacedRun::{
    text: mark,
    x,
    dy: SUPERSCRIPT_DY_EM,
    width: measure_text(mark) * scale,
    scale,
  }
}
