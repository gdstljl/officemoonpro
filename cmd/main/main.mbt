///|
/// wordcraft-cli：带圈编号与脚注链路的命令面（P4）。
///
/// 用法：
///   moon run cmd/main -- demo                    # 完整演示：编号抽查 + 脚注链路
///   moon run cmd/main -- circled 51              # 打印 circled(51)
///   moon run cmd/main -- mark 1001 enclosed-cn   # 第 1001 个脚注的 mark（decimal|enclosed|enclosed-cn）
///   moon run cmd/main -- dump-sample            # 样例 .docx 的 hex（管道给外部校验）

///|
fn main {
  let args = @env.args()
  if args.length() < 2 {
    usage()
    return
  }
  match args[1] {
    "demo" => demo()
    "dump-sample" => dump_sample()
    "xlsx-demo" => xlsx_demo()
    "circled" =>
      if args.length() < 3 {
        usage()
      } else {
        match parse_cli_int(args[2]) {
          Some(n) => println(@cjk.circled(n))
          None => usage()
        }
      }
    "mark" =>
      if args.length() < 3 {
        usage()
      } else {
        let fmt_name = if args.length() > 3 { args[3] } else { "enclosed" }
        match parse_cli_int(args[2]) {
          Some(n) => {
            let fmt = match fmt_name {
              "decimal" => @core.NumFormat::decimal()
              "enclosed-cn" =>
                @core.NumFormat::decimal_enclosed_circle_chinese()
              _ => @core.NumFormat::decimal_enclosed_circle()
            }
            let props = @core.make_note_props(num_fmt=fmt, num_start=1)
            let doc = @doc.Document::new()
            let _ = doc.add_paragraph("p")
            let mut id = 0
            let mut i = 0
            while i < n {
              id = doc.add_note(@core.NoteKind::footnote(), "", "")
              i += 1
            }
            println(doc.note_mark(id, props))
          }
          None => usage()
        }
      }
    _ => usage()
  }
}

///|
fn usage() -> Unit {
  println("usage:")
  println(
    "  demo                    完整演示：编号抽查 + 脚注链路",
  )
  println("  circled <n>             打印 circled(n)")
  println(
    "  mark <n> [fmt]          第 n 个脚注的 mark；fmt = decimal|enclosed|enclosed-cn",
  )
  println(
    "  dump-sample             样例 .docx 的 hex（管道给外部校验）",
  )
  println("  xlsx-demo               样例 .xlsx 的 hex（管道给外部校验）")
}

///|
/// 生成样例文档并以 hex 输出 zip 字节（供外部校验 Word 兼容性）。
fn dump_sample() -> Unit {
  let doc = @doc.Document::new()
  let para = doc.add_paragraph("Hello ")
  let _ = @engine.insert_footnote(doc, para, "脚注一", "")
  let _ = @engine.insert_footnote(doc, para, "脚注二", "※")
  let pd = @docx.make_package_doc(
    doc,
    @core.NumFormat::decimal_enclosed_circle(),
    @core.NumFormat::decimal(),
    [@docx.make_level_fmt(0, @core.NumFormat::decimal_enclosed_circle())],
  )
  let zipped = @zip.write_zip_text(@docx.write_package(pd))
  let sb = StringBuilder()
  let hex = "0123456789abcdef".to_array()
  for b in zipped.to_array() {
    let v = b.to_int()
    sb.write_char(hex[(v >> 4) & 0xF])
    sb.write_char(hex[v & 0xF])
  }
  println(sb.to_string())
}

///|
/// 生成样例 .xlsx 并以 hex 输出（供外部校验 Excel 兼容性）。
fn xlsx_demo() -> Unit {
  let wb = @sheet.make_workbook()
  let _ = wb.add_sheet("成绩单")
  match wb.get_sheet(0) {
    Some(ws) => {
      ws.set_cell(0, 0, @sheet.CellValue::text("姓名"))
      ws.set_cell(0, 1, @sheet.CellValue::text("数学"))
      ws.set_cell(0, 2, @sheet.CellValue::text("英语"))
      ws.set_cell(1, 0, @sheet.CellValue::text("张三"))
      ws.set_cell(1, 1, @sheet.CellValue::number(95.0))
      ws.set_cell(1, 2, @sheet.CellValue::number(88.5))
      ws.set_cell(2, 0, @sheet.CellValue::text("李四"))
      ws.set_cell(2, 1, @sheet.CellValue::number(78.0))
      ws.set_formula(3, 1, "SUM(B2:B3)")
    }
    None => ()
  }
  let bytes = @xlsx.write_xlsx(wb)
  let sb = StringBuilder()
  let hex = "0123456789abcdef".to_array()
  for b in bytes.to_array() {
    sb.write_char(hex[(b.to_int() >> 4) & 0xF])
    sb.write_char(hex[b.to_int() & 0xF])
  }
  println(sb.to_string())
}

///|
fn parse_cli_int(s : String) -> Int32? {
  let chars = s.to_array()
  if chars.length() == 0 {
    return None
  }
  let mut v = 0
  let mut i = 0
  while i < chars.length() {
    let d = chars[i].to_int() - '0'.to_int()
    if d < 0 || d > 9 {
      return None
    }
    v = v * 10 + d
    i += 1
  }
  Some(v)
}

///|
/// 完整演示：计划 §5.4 验收抽查 + P1 脚注链路。
fn demo() -> Unit {
  let props = @core.make_note_props(
    num_fmt=@core.NumFormat::decimal_enclosed_circle(),
    num_start=1,
  )
  let keys = [1, 10, 11, 20, 21, 35, 36, 50, 51, 99, 100, 101, 999, 1000, 1001]
  for n in keys {
    println("footnote \{n}: \{@core.note_mark(n, props)}")
  }
  println("--- footnotes ---")
  let doc = @doc.Document::new()
  let para = doc.add_paragraph("正文段落")
  let f1 = @engine.insert_footnote(doc, para, "第一条脚注", "")
  let f2 = @engine.insert_footnote(doc, para, "第二条脚注", "")
  let e1 = @engine.insert_endnote(doc, para, "尾注正文", "")
  let f3 = @engine.insert_footnote(doc, para, "自定义 mark", "*")
  println("f1: \{doc.note_mark(f1, props)} \{doc.find_note_text(f1)}")
  println("f2: \{doc.note_mark(f2, props)} \{doc.find_note_text(f2)}")
  println("e1: \{doc.note_mark(e1, props)} \{doc.find_note_text(e1)}")
  println("f3: \{doc.note_mark(f3, props)} \{doc.find_note_text(f3)}")
}
