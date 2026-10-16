///|
/// XLSX 写出：Workbook → ZIP 字节（复用 core/zip）。
/// 生成 Excel/WPS 可打开的最小合法 .xlsx。

fn esc(s : String) -> String {
  @docx.escape_xml(s)
}

///|
/// 收集所有文本值，返回去重后的共享字符串表。
fn collect_shared_strings(wb : @sheet.Workbook) -> Array[String] {
  let strs : Array[String] = []
  let seen : @hashmap.HashMap[String, Int] = @hashmap.HashMap([])
  let mut si = 0
  while si < wb.sheet_count() {
    match wb.get_sheet(si) {
      Some(ws) =>
        match ws.used_range() {
          Some((min_r, min_c, max_r, max_c)) => {
            let mut r = min_r
            while r <= max_r {
              let mut c = min_c
              while c <= max_c {
                match ws.get_cell(r, c) {
                  Some(cell) =>
                    match cell.get_value() {
                      @sheet.Text(s) =>
                        if seen.get(s) is None {
                          seen.set(s, strs.length())
                          strs.push(s)
                        }
                      _ => ()
                    }
                  None => ()
                }
                c += 1
              }
              r += 1
            }
          }
          None => ()
        }
      None => ()
    }
    si += 1
  }
  strs
}

fn shared_string_index(strs : Array[String], s : String) -> Int {
  let mut i = 0
  while i < strs.length() {
    if strs[i] == s {
      return i
    }
    i += 1
  }
  0
}

fn build_shared_strings(strs : Array[String]) -> String {
  let sb = StringBuilder()
  sb.write_string("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n")
  sb.write_string("<sst xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\" count=\"")
  sb.write_string(strs.length().to_string())
  sb.write_string("\" uniqueCount=\"")
  sb.write_string(strs.length().to_string())
  sb.write_string("\">")
  for s in strs {
    sb.write_string("<si><t>")
    sb.write_string(esc(s))
    sb.write_string("</t></si>")
  }
  sb.write_string("</sst>")
  sb.to_string()
}

fn build_sheet_xml(ws : @sheet.Worksheet, strs : Array[String]) -> String {
  let sb = StringBuilder()
  sb.write_string("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n")
  sb.write_string("<worksheet xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\">")
  sb.write_string("<sheetData>")
  match ws.used_range() {
    Some((min_r, min_c, max_r, max_c)) => {
      let mut r = min_r
      while r <= max_r {
        sb.write_string("<row r=\"")
        sb.write_string((r + 1).to_string())
        sb.write_string("\">")
        let mut c = min_c
        while c <= max_c {
          match ws.get_cell(r, c) {
            Some(cell) => write_cell_xml(sb, r, c, cell, strs)
            None => ()
          }
          c += 1
        }
        sb.write_string("</row>")
        r += 1
      }
    }
    None => ()
  }
  sb.write_string("</sheetData></worksheet>")
  sb.to_string()
}

fn write_cell_xml(
  sb : StringBuilder,
  row : Int,
  col : Int,
  cell : @sheet.Cell,
  strs : Array[String],
) -> Unit {
  let a1 = @sheet.rc_to_a1(row, col)
  let formula = cell.get_formula()
  sb.write_string("<c r=\"")
  sb.write_string(a1)
  sb.write_string("\"")
  match cell.get_value() {
    @sheet.Empty =>
      if formula != "" {
        sb.write_string("><f>")
        sb.write_string(esc(formula))
        sb.write_string("</f></c>")
      } else {
        sb.write_string("/>")
      }
    @sheet.Text(s) => {
      let idx = shared_string_index(strs, s)
      sb.write_string(" t=\"s\"><v>")
      sb.write_string(idx.to_string())
      sb.write_string("</v>")
      if formula != "" {
        sb.write_string("<f>")
        sb.write_string(esc(formula))
        sb.write_string("</f>")
      }
      sb.write_string("</c>")
    }
    @sheet.Number(n) => {
      sb.write_string("><v>")
      sb.write_string(n.to_string())
      sb.write_string("</v>")
      if formula != "" {
        sb.write_string("<f>")
        sb.write_string(esc(formula))
        sb.write_string("</f>")
      }
      sb.write_string("</c>")
    }
    @sheet.Bool(b) => {
      sb.write_string(" t=\"b\"><v>")
      sb.write_string(if b { "1" } else { "0" })
      sb.write_string("</v></c>")
    }
    @sheet.Error(e) => {
      sb.write_string(" t=\"e\"><v>")
      sb.write_string(esc(e))
      sb.write_string("</v></c>")
    }
  }
}

fn build_workbook_xml(wb : @sheet.Workbook) -> String {
  let sb = StringBuilder()
  sb.write_string("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n")
  sb.write_string("<workbook xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\" xmlns:r=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships\">")
  sb.write_string("<sheets>")
  let mut i = 0
  while i < wb.sheet_count() {
    match wb.get_sheet(i) {
      Some(ws) => {
        sb.write_string("<sheet name=\"")
        sb.write_string(esc(ws.get_name()))
        sb.write_string("\" sheetId=\"")
        sb.write_string((i + 1).to_string())
        sb.write_string("\" r:id=\"rId")
        sb.write_string((i + 1).to_string())
        sb.write_string("\"/>")
      }
      None => ()
    }
    i += 1
  }
  sb.write_string("</sheets></workbook>")
  sb.to_string()
}

fn build_workbook_rels(wb : @sheet.Workbook) -> String {
  let sb = StringBuilder()
  sb.write_string("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n")
  sb.write_string("<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">")
  let mut i = 0
  while i < wb.sheet_count() {
    sb.write_string("<Relationship Id=\"rId")
    sb.write_string((i + 1).to_string())
    sb.write_string("\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet\" Target=\"worksheets/sheet")
    sb.write_string((i + 1).to_string())
    sb.write_string(".xml\"/>")
    i += 1
  }
  // styles + sharedStrings
  let base = wb.sheet_count() + 1
  sb.write_string("<Relationship Id=\"rId")
  sb.write_string(base.to_string())
  sb.write_string("\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles\" Target=\"styles.xml\"/>")
  sb.write_string("<Relationship Id=\"rId")
  sb.write_string((base + 1).to_string())
  sb.write_string("\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings\" Target=\"sharedStrings.xml\"/>")
  sb.write_string("</Relationships>")
  sb.to_string()
}

fn build_content_types(wb : @sheet.Workbook) -> String {
  let sb = StringBuilder()
  sb.write_string("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n")
  sb.write_string("<Types xmlns=\"http://schemas.openxmlformats.org/package/2006/content-types\">")
  sb.write_string("<Default Extension=\"rels\" ContentType=\"application/vnd.openxmlformats-package.relationships+xml\"/>")
  sb.write_string("<Default Extension=\"xml\" ContentType=\"application/xml\"/>")
  sb.write_string("<Override PartName=\"/xl/workbook.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml\"/>")
  sb.write_string("<Override PartName=\"/xl/sharedStrings.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml\"/>")
  sb.write_string("<Override PartName=\"/xl/styles.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml\"/>")
  let mut i = 0
  while i < wb.sheet_count() {
    sb.write_string("<Override PartName=\"/xl/worksheets/sheet")
    sb.write_string((i + 1).to_string())
    sb.write_string(".xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml\"/>")
    i += 1
  }
  sb.write_string("</Types>")
  sb.to_string()
}

fn build_root_rels() -> String {
  "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\"><Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument\" Target=\"xl/workbook.xml\"/></Relationships>"
}

fn build_styles_xml() -> String {
  "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n<styleSheet xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\"><fonts count=\"1\"><font><sz val=\"11\"/><name val=\"Calibri\"/></font></fonts><fills count=\"1\"><fill><patternFill patternType=\"none\"/></fill></fills><borders count=\"1\"><border/></borders><cellStyleXfs count=\"1\"><xf numFmtId=\"0\" fontId=\"0\" fillId=\"0\" borderId=\"0\"/></cellStyleXfs><cellXfs count=\"1\"><xf numFmtId=\"0\" fontId=\"0\" fillId=\"0\" borderId=\"0\" xfId=\"0\"/></cellXfs></styleSheet>"
}

///|
/// Workbook → .xlsx 字节。
pub fn write_xlsx(wb : @sheet.Workbook) -> Bytes {
  let strs = collect_shared_strings(wb)
  let entries : Array[(String, String)] = []
  entries.push(("[Content_Types].xml", build_content_types(wb)))
  entries.push(("_rels/.rels", build_root_rels()))
  entries.push(("xl/workbook.xml", build_workbook_xml(wb)))
  entries.push(("xl/_rels/workbook.xml.rels", build_workbook_rels(wb)))
  entries.push(("xl/sharedStrings.xml", build_shared_strings(strs)))
  entries.push(("xl/styles.xml", build_styles_xml()))
  let mut i = 0
  while i < wb.sheet_count() {
    match wb.get_sheet(i) {
      Some(ws) => {
        let name = "xl/worksheets/sheet" + (i + 1).to_string() + ".xml"
        entries.push((name, build_sheet_xml(ws, strs)))
      }
      None => ()
    }
    i += 1
  }
  @zip.write_zip_text(entries)
}
