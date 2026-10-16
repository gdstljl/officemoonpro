///|
/// 断行：CJK 感知的贪心断行（含禁则 kinsoku 子集）。
/// 拉丁文按词不断词内；CJK 逐字可断，但后括号/句点不另起行。

///|
/// 不可再分的排版单元。
pub struct Token {
  text : String
  width : Double
  /// 空格（行首可丢弃）
  is_space : Bool
  /// 不可断在该单元之前（后括号、句点等）
  no_break_before : Bool
  /// 不可断在该单元之后（前括号等）
  no_break_after : Bool
  /// 是否上标（如脚注 mark）
  is_superscript : Bool
  /// 脚注 id（mark token 有效，否则 -1）
  note_id : Int32
}

///|
fn is_space_code(code : Int32) -> Bool {
  code == 0x20 || code == 0x09 || code == 0x0A || code == 0x0D
}

///|
fn is_latin_alnum(code : Int32) -> Bool {
  (code >= 0x61 && code <= 0x7A) ||
  (code >= 0x41 && code <= 0x5A) ||
  (code >= 0x30 && code <= 0x39)
}

///|
/// 后括号/句点类：不可行首。
fn is_closing_punct(code : Int32) -> Bool {
  match code {
    0x3002
    | 0xFF0C
    | 0x3001
    | 0xFF1B
    | 0xFF1A
    | 0xFF1F
    | 0xFF01
    | 0xFF09
    | 0xFF3D
    | 0xFF7D
    | 0x300D
    | 0x300F
    | 0xFF07
    | 0xFF02
    | 0x300B
    | 0x3009
    | 0x0029
    | 0x005D
    | 0x007D
    | 0x002C
    | 0x002E
    | 0x003B
    | 0x003A
    | 0x0021
    | 0x003F => true
    _ => false
  }
}

///|
/// 前括号类：不可行尾。
fn is_opening_punct(code : Int32) -> Bool {
  match code {
    0xFF08
    | 0xFF3B
    | 0xFF5B
    | 0x300C
    | 0x300E
    | 0xFF02
    | 0x2018
    | 0x300A
    | 0x3008
    | 0x0028
    | 0x005B
    | 0x007B => true
    _ => false
  }
}

///|
fn blank_token(width : Double) -> Token {
  Token::{
    text: " ",
    width,
    is_space: true,
    no_break_before: false,
    no_break_after: false,
    is_superscript: false,
    note_id: -1,
  }
}

///|
/// 分词：CJK/符号逐字，拉丁文按词，连续空格合并。
pub fn tokenize(text : String) -> Array[Token] {
  let chars = text.to_array()
  let out : Array[Token] = []
  let mut i = 0
  while i < chars.length() {
    let c = chars[i]
    let code = c.to_int()
    if is_space_code(code) {
      let mut j = i
      while j < chars.length() && is_space_code(chars[j].to_int()) {
        j += 1
      }
      out.push(blank_token(0.5 * (j - i).to_double()))
      i = j
    } else if is_latin_alnum(code) {
      let sb = StringBuilder()
      let mut j = i
      while j < chars.length() && is_latin_alnum(chars[j].to_int()) {
        sb.write_char(chars[j])
        j += 1
      }
      let w = sb.to_string()
      out.push(Token::{
        text: w,
        width: 0.5 * w.to_array().length().to_double(),
        is_space: false,
        no_break_before: false,
        no_break_after: false,
        is_superscript: false,
        note_id: -1,
      })
      i = j
    } else {
      out.push(Token::{
        text: c.to_string(),
        width: char_width_em(c),
        is_space: false,
        no_break_before: is_closing_punct(code),
        no_break_after: is_opening_punct(code),
        is_superscript: false,
        note_id: -1,
      })
      i += 1
    }
  }
  out
}

///|
/// 贪心断行，返回每行的 token 数组。
/// 行首空格丢弃；行尾空格丢弃；禁则字符放不下时强制跟上行（溢出），不另起行。
pub fn break_lines(
  tokens : Array[Token],
  max_width : Double,
) -> Array[Array[Token]] {
  let lines : Array[Array[Token]] = []
  let mut cur : Array[Token] = []
  let mut cur_w = 0.0
  for tok in tokens {
    if cur.length() == 0 && tok.is_space {
      continue
    }
    if cur_w + tok.width <= max_width {
      cur.push(tok)
      cur_w += tok.width
      continue
    }
    // 放不下：能否断在 tok 之前？
    let can_break = cur.length() > 0 &&
      !tok.no_break_before &&
      !cur[cur.length() - 1].no_break_after
    if can_break {
      lines.push(trim_trailing_spaces(cur))
      cur = []
      cur_w = 0.0
      if tok.is_space {
        continue
      }
      cur.push(tok)
      cur_w = tok.width
    } else {
      // 禁则或行首超长：强制放入（溢出）
      cur.push(tok)
      cur_w += tok.width
    }
  }
  if cur.length() > 0 {
    lines.push(trim_trailing_spaces(cur))
  }
  lines
}

///|
fn trim_trailing_spaces(line : Array[Token]) -> Array[Token] {
  let mut end = line.length()
  while end > 0 && line[end - 1].is_space {
    end -= 1
  }
  let out : Array[Token] = []
  let mut i = 0
  while i < end {
    out.push(line[i])
    i += 1
  }
  out
}
