///|
/// XLSX 读入：ZIP 字节 → Workbook（复用 core/zip + docx XML 解析器）。

fn find_entry(entries : Array[(String, String)], name : String) -> String? {
  for e in entries {
    let (n, xml) = e
    if n == name {
      return Some(xml)
    }
  }
  None
}

///|
/// 解析 sharedStrings.xml → 字符串数组。
fn parse_shared_strings(xml : String) -> Array[String] {
  let out : Array[String] = []
  match @docx.parse_xml(xml) {
    Some(root) =>
      for si in root.children_named("si") {
        // 取所有 <t> 文本拼接（忽略富文本细节）
        out.push(si.descendant_texts("t"))
      }
    None => ()
  }
  out
}

fn parse_double(s : String) -> Double? {
  // 简单解析：整数或小数
  let chars = s.to_array()
  if chars.length() == 0 {
    return None
  }
  let mut i = 0
  let mut neg = false
  if chars[0] == '-' {
    neg = true
    i = 1
  } else if chars[0] == '+' {
    i = 1
  }
  let mut int_part = 0.0
  let mut frac_part = 0.0
  let mut frac_div = 1.0
  let mut has_digit = false
  let mut in_frac = false
  while i < chars.length() {
    let c = chars[i]
    if c == '.' && !in_frac {
      in_frac = true
    } else {
      let d = c.to_int() - 0x30
      if d < 0 || d > 9 {
        return None
      }
      has_digit = true
      if in_frac {
        frac_div *= 10.0
        frac_part += d.to_double() / frac_div
      } else {
        int_part = int_part * 10.0 + d.to_double()
      }
    }
    i += 1
  }
  if !has_digit {
    return None
  }
  let v = int_part + frac_part
  Some(if neg { 0.0 - v } else { v })
}

fn parse_sheet_xml(
  xml : String,
  strs : Array[String],
  ws : @sheet.Worksheet,
) -> Unit {
  match @docx.parse_xml(xml) {
    Some(root) =>
      for row in root.find_all("row") {
        for c in row.children_named("c") {
          let ref = match c.attr("r") {
            Some(r) => r
            None => continue
          }
          match @sheet.a1_to_rc(ref) {
            Some((r, col)) => {
              let t = match c.attr("t") {
                Some(x) => x
                None => ""
              }
              let v_text = c.descendant_texts("v")
              let f_text = c.descendant_texts("f")
              let value = match t {
                "s" =>
                  match parse_int_simple(v_text) {
                    Some(idx) =>
                      if idx >= 0 && idx < strs.length() {
                        @sheet.CellValue::text(strs[idx])
                      } else {
                        @sheet.CellValue::empty()
                      }
                    None => @sheet.CellValue::empty()
                  }
                "b" =>
                  if v_text == "1" {
                    @sheet.CellValue::bool(true)
                  } else {
                    @sheet.CellValue::bool(false)
                  }
                "e" => @sheet.CellValue::error(v_text)
                "str" => @sheet.CellValue::text(v_text)
                _ =>
                  match parse_double(v_text) {
                    Some(n) => @sheet.CellValue::number(n)
                    None =>
                      if v_text == "" {
                        @sheet.CellValue::empty()
                      } else {
                        @sheet.CellValue::text(v_text)
                      }
                  }
              }
              if f_text != "" {
                ws.set_cell_formula(r, col, value, f_text)
              } else {
                ws.set_cell(r, col, value)
              }
            }
            None => ()
          }
        }
      }
    None => ()
  }
}

fn parse_int_simple(s : String) -> Int? {
  let chars = s.to_array()
  if chars.length() == 0 {
    return None
  }
  let mut v = 0
  let mut i = 0
  while i < chars.length() {
    let d = chars[i].to_int() - 0x30
    if d < 0 || d > 9 {
      return None
    }
    v = v * 10 + d
    i += 1
  }
  Some(v)
}

///|
/// .xlsx 字节 → Workbook。失败返回 None。
pub fn read_xlsx(data : Bytes) -> @sheet.Workbook? {
  let entries = match @zip.read_zip_text(data) {
    Some(e) => e
    None => return None
  }
  let wb_xml = match find_entry(entries, "xl/workbook.xml") {
    Some(x) => x
    None => return None
  }
  let strs = match find_entry(entries, "xl/sharedStrings.xml") {
    Some(x) => parse_shared_strings(x)
    None => []
  }
  let wb = @sheet.make_workbook()
  match @docx.parse_xml(wb_xml) {
    Some(root) => {
      let mut idx = 1
      for sh in root.find_all("sheet") {
        let name = match sh.attr("name") {
          Some(n) => n
          None => "Sheet" + idx.to_string()
        }
        let si = wb.add_sheet(name)
        let sheet_file = "xl/worksheets/sheet" + idx.to_string() + ".xml"
        match find_entry(entries, sheet_file) {
          Some(sxml) =>
            match wb.get_sheet(si) {
              Some(ws) => parse_sheet_xml(sxml, strs, ws)
              None => ()
            }
          None => ()
        }
        idx += 1
      }
    }
    None => return None
  }
  Some(wb)
}
