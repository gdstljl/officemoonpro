///|
/// 最小 XML 子集解析器与生成器。
///
/// 解析支持：元素、属性（单/双引号）、自闭合标签、文本、注释、处理指令、
/// CDATA、预定义实体（`&amp;` `&lt;` `&gt;` `&quot;` `&apos;`）与数字字符引用。
/// 命名空间保留为名称前缀（如 `w:footnote`），不做解析。
/// 目标是 docx 片段（numbering / footnotes / document / settings），不是通用 XML。

///|
pub struct XmlAttr {
  name : String
  value : String
}

///|
pub struct XmlNode {
  name : String
  attrs : Array[XmlAttr]
  children : Array[XmlNode]
  text : String
}

///|
/// 取属性值；不存在返回 None。
pub fn XmlNode::attr(self : XmlNode, name : String) -> String? {
  for a in self.attrs {
    if a.name == name {
      return Some(a.value)
    }
  }
  None
}

///|
/// 第一个名为 name 的直接子元素。
pub fn XmlNode::child(self : XmlNode, name : String) -> XmlNode? {
  for c in self.children {
    if c.name == name {
      return Some(c)
    }
  }
  None
}

///|
/// 所有名为 name 的直接子元素（文档序）。
pub fn XmlNode::children_named(self : XmlNode, name : String) -> Array[XmlNode] {
  let out : Array[XmlNode] = []
  for c in self.children {
    if c.name == name {
      out.push(c)
    }
  }
  out
}

///|
/// 递归查找所有名为 name 的后代（文档序）。
pub fn XmlNode::find_all(self : XmlNode, name : String) -> Array[XmlNode] {
  let out : Array[XmlNode] = []
  collect_named(self, name, out)
  out
}

///|
fn collect_named(node : XmlNode, name : String, out : Array[XmlNode]) -> Unit {
  for c in node.children {
    if c.name == name {
      out.push(c)
    }
    collect_named(c, name, out)
  }
}

///|
/// 所有名为 name 的后代元素的 text 拼接（文档序）。
pub fn XmlNode::descendant_texts(self : XmlNode, name : String) -> String {
  let sb = StringBuilder()
  for n in self.find_all(name) {
    sb.write_string(n.text)
  }
  sb.to_string()
}

///|
/// XML 转义（文本/属性值用）。
pub fn escape_xml(s : String) -> String {
  let sb = StringBuilder()
  write_escaped(s, sb)
  sb.to_string()
}

///|
/// 解析完整 XML 文档，返回根元素；格式错误返回 None。
pub fn parse_xml(s : String) -> XmlNode? {
  let chars = s.to_array()
  let mut p = skip_ws(chars, 0)
  // 跳过 prolog：<?...?>、<!--...-->、<!DOCTYPE...>
  let mut again = true
  while again {
    again = false
    if starts_with(chars, p, "<?") {
      match find_seq(chars, p, "?>") {
        Some(np) => {
          p = skip_ws(chars, np)
          again = true
        }
        None => return None
      }
    } else if starts_with(chars, p, "<!--") {
      match find_seq(chars, p, "-->") {
        Some(np) => {
          p = skip_ws(chars, np)
          again = true
        }
        None => return None
      }
    } else if starts_with(chars, p, "<!") {
      match find_seq(chars, p, ">") {
        Some(np) => {
          p = skip_ws(chars, np)
          again = true
        }
        None => return None
      }
    }
  }
  if p >= chars.length() || chars[p].to_int() != 0x3C {
    return None
  }
  let (_, node) = parse_element(chars, p)
  node
}

///|
/// 把节点写回 XML（属性与文本做转义；空元素写成自闭合）。
pub fn write_xml(node : XmlNode) -> String {
  let sb = StringBuilder()
  write_node(node, sb)
  sb.to_string()
}

///|
fn write_node(n : XmlNode, sb : StringBuilder) -> Unit {
  sb.write_char('<')
  sb.write_string(n.name)
  for a in n.attrs {
    sb.write_char(' ')
    sb.write_string(a.name)
    sb.write_string("=\"")
    write_escaped(a.value, sb)
    sb.write_char('"')
  }
  if n.children.length() == 0 && n.text == "" {
    sb.write_string("/>")
  } else {
    sb.write_char('>')
    write_escaped(n.text, sb)
    for c in n.children {
      write_node(c, sb)
    }
    sb.write_string("</")
    sb.write_string(n.name)
    sb.write_char('>')
  }
}

///|
fn write_escaped(s : String, sb : StringBuilder) -> Unit {
  for c in s.to_array() {
    match c.to_int() {
      0x26 => sb.write_string("&amp;")
      0x3C => sb.write_string("&lt;")
      0x3E => sb.write_string("&gt;")
      0x22 => sb.write_string("&quot;")
      _ => sb.write_char(c)
    }
  }
}

///|
/// 解析整数属性（可选前导 `-`/`+`）；非法返回 None。
pub fn parse_int(s : String) -> Int32? {
  let chars = s.to_array()
  if chars.length() == 0 {
    return None
  }
  let mut i = 0
  let mut neg = false
  if chars[0].to_int() == 0x2D {
    neg = true
    i = 1
  } else if chars[0].to_int() == 0x2B {
    i = 1
  }
  let mut v = 0
  let mut any = false
  while i < chars.length() {
    let d = chars[i].to_int() - 0x30
    if d < 0 || d > 9 {
      return None
    }
    v = v * 10 + d
    any = true
    i += 1
  }
  if !any {
    return None
  }
  Some(if neg { 0 - v } else { v })
}

// ---- 内部：解析 ----

///|
fn is_space_code(code : Int32) -> Bool {
  code == 0x20 || code == 0x09 || code == 0x0A || code == 0x0D
}

///|
fn is_name_code(code : Int32) -> Bool {
  (code >= 0x61 && code <= 0x7A) ||
  (code >= 0x41 && code <= 0x5A) ||
  (code >= 0x30 && code <= 0x39) ||
  code == 0x5F ||
  code == 0x3A ||
  code == 0x2E ||
  code == 0x2D
}

///|
fn skip_ws(chars : Array[Char], pos : Int32) -> Int32 {
  let mut p = pos
  while p < chars.length() && is_space_code(chars[p].to_int()) {
    p += 1
  }
  p
}

///|
fn parse_name(chars : Array[Char], pos : Int32) -> (Int32, String) {
  let sb = StringBuilder()
  let mut p = pos
  while p < chars.length() && is_name_code(chars[p].to_int()) {
    sb.write_char(chars[p])
    p += 1
  }
  (p, sb.to_string())
}

///|
fn has_non_space(s : String) -> Bool {
  for c in s.to_array() {
    if !is_space_code(c.to_int()) {
      return true
    }
  }
  false
}

///|
fn starts_with(chars : Array[Char], pos : Int32, s : String) -> Bool {
  let cs = s.to_array()
  if pos + cs.length() > chars.length() {
    return false
  }
  let mut i = 0
  while i < cs.length() {
    if chars[pos + i].to_int() != cs[i].to_int() {
      return false
    }
    i += 1
  }
  true
}

///|
/// 返回 seq 之后的位置；找不到返回 None。
fn find_seq(chars : Array[Char], pos : Int32, s : String) -> Int32? {
  let len = s.to_array().length()
  let mut p = pos
  while p + len <= chars.length() {
    if starts_with(chars, p, s) {
      return Some(p + len)
    }
    p += 1
  }
  None
}

///|
fn hex_val(code : Int32) -> Int32 {
  if code >= 0x30 && code <= 0x39 {
    code - 0x30
  } else if code >= 0x61 && code <= 0x66 {
    code - 0x61 + 10
  } else if code >= 0x41 && code <= 0x46 {
    code - 0x41 + 10
  } else {
    -1
  }
}

///|
fn decode_numeric_entity(name : String) -> Char? {
  let chars = name.to_array()
  if chars.length() < 2 || chars[0].to_int() != 0x23 {
    return None
  }
  let mut v = 0
  if chars[1].to_int() == 0x78 || chars[1].to_int() == 0x58 {
    let mut i = 2
    if i >= chars.length() {
      return None
    }
    while i < chars.length() {
      let d = hex_val(chars[i].to_int())
      if d < 0 {
        return None
      }
      v = v * 16 + d
      i += 1
    }
  } else {
    let mut i = 1
    while i < chars.length() {
      let d = chars[i].to_int() - 0x30
      if d < 0 || d > 9 {
        return None
      }
      v = v * 10 + d
      i += 1
    }
  }
  if v < 0 || v > 0xFFFF {
    return None
  }
  Some(v.unsafe_to_char())
}

///|
/// pos 在 '&'；返回 (新位置, 是否成功, 字符)。
fn parse_entity(chars : Array[Char], pos : Int32) -> (Int32, Bool, Char) {
  let mut p = pos + 1
  let sb = StringBuilder()
  while p < chars.length() && chars[p].to_int() != 0x3B && p - pos < 12 {
    sb.write_char(chars[p])
    p += 1
  }
  if p >= chars.length() || chars[p].to_int() != 0x3B {
    return (pos, false, '&')
  }
  let ch = match sb.to_string() {
    "amp" => Some('&')
    "lt" => Some('<')
    "gt" => Some('>')
    "quot" => Some('"')
    "apos" => Some('\'')
    name => decode_numeric_entity(name)
  }
  match ch {
    Some(c) => (p + 1, true, c)
    None => (pos, false, '&')
  }
}

///|
/// 解析文本直到 '<'（含实体解析）；返回 (新位置, 文本)。
fn parse_text(chars : Array[Char], pos : Int32) -> (Int32, String) {
  let sb = StringBuilder()
  let mut p = pos
  while p < chars.length() && chars[p].to_int() != 0x3C {
    if chars[p].to_int() == 0x26 {
      let (p2, ok, c) = parse_entity(chars, p)
      if ok {
        sb.write_char(c)
        p = p2
      } else {
        sb.write_char('&')
        p += 1
      }
    } else {
      sb.write_char(chars[p])
      p += 1
    }
  }
  (p, sb.to_string())
}

///|
fn parse_attr_value(chars : Array[Char], pos : Int32) -> (Int32, String?) {
  if pos >= chars.length() {
    return (pos, None)
  }
  let q = chars[pos].to_int()
  if q != 0x22 && q != 0x27 {
    return (pos, None)
  }
  let sb = StringBuilder()
  let mut p = pos + 1
  while p < chars.length() && chars[p].to_int() != q {
    if chars[p].to_int() == 0x26 {
      let (p2, ok, c) = parse_entity(chars, p)
      if ok {
        sb.write_char(c)
        p = p2
      } else {
        sb.write_char('&')
        p += 1
      }
    } else {
      sb.write_char(chars[p])
      p += 1
    }
  }
  if p >= chars.length() {
    return (pos, None)
  }
  (p + 1, Some(sb.to_string()))
}

///|
/// pos 在 '<'；返回 (新位置, 节点?)。
fn parse_element(chars : Array[Char], pos : Int32) -> (Int32, XmlNode?) {
  let mut p = pos + 1
  let (p2, name) = parse_name(chars, p)
  if name == "" {
    return (pos, None)
  }
  p = p2
  let attrs : Array[XmlAttr] = []
  p = skip_ws(chars, p)
  let mut self_closing = false
  let mut open_done = false
  while !open_done {
    if p >= chars.length() {
      return (pos, None)
    }
    let c = chars[p].to_int()
    if c == 0x2F {
      // '/'
      if p + 1 < chars.length() && chars[p + 1].to_int() == 0x3E {
        p += 2
        self_closing = true
        open_done = true
      } else {
        return (pos, None)
      }
    } else if c == 0x3E {
      // '>'
      p += 1
      open_done = true
    } else {
      let (p3, aname) = parse_name(chars, p)
      if aname == "" {
        return (pos, None)
      }
      p = skip_ws(chars, p3)
      if p >= chars.length() || chars[p].to_int() != 0x3D {
        return (pos, None)
      }
      p = skip_ws(chars, p + 1)
      let (p4, aval) = parse_attr_value(chars, p)
      match aval {
        Some(v) => {
          attrs.push(XmlAttr::{ name: aname, value: v, })
          p = skip_ws(chars, p4)
        }
        None => return (pos, None)
      }
    }
  }
  if self_closing {
    return (p, Some(XmlNode::{ name, attrs, children: [], text: "", }))
  }
  let children : Array[XmlNode] = []
  let text_sb = StringBuilder()
  let mut closed = false
  while !closed {
    if p >= chars.length() {
      return (pos, None)
    }
    if chars[p].to_int() == 0x3C {
      // '<'
      if starts_with(chars, p, "</") {
        let (p3, cname) = parse_name(chars, p + 2)
        if cname != name {
          return (pos, None)
        }
        let p4 = skip_ws(chars, p3)
        if p4 >= chars.length() || chars[p4].to_int() != 0x3E {
          return (pos, None)
        }
        p = p4 + 1
        closed = true
      } else if starts_with(chars, p, "<!--") {
        match find_seq(chars, p, "-->") {
          Some(np) => p = np
          None => return (pos, None)
        }
      } else if starts_with(chars, p, "<?") {
        match find_seq(chars, p, "?>") {
          Some(np) => p = np
          None => return (pos, None)
        }
      } else if starts_with(chars, p, "<![CDATA[") {
        match find_seq(chars, p, "]]>") {
          Some(np) => {
            // CDATA 内容：原文，不做实体解析
            let mut q = p + 9
            while q < np - 3 {
              text_sb.write_char(chars[q])
              q += 1
            }
            p = np
          }
          None => return (pos, None)
        }
      } else if starts_with(chars, p, "<!") {
        match find_seq(chars, p, ">") {
          Some(np) => p = np
          None => return (pos, None)
        }
      } else {
        let (p3, child) = parse_element(chars, p)
        match child {
          Some(c) => {
            children.push(c)
            p = p3
          }
          None => return (pos, None)
        }
      }
    } else {
      let (p2, t) = parse_text(chars, p)
      // 纯空白文本（美化换行）丢弃；有实质字符的整体保留
      if has_non_space(t) {
        text_sb.write_string(t)
      }
      p = p2
    }
  }
  (p, Some(XmlNode::{ name, attrs, children, text: text_sb.to_string(), }))
}
