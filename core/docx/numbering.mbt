///|
/// numbering.xml 子集编解码：只关心每级的 `w:numFmt`。
/// 对标 Rust `read/mod.rs` 的 `level()` 与 `fixtures.rs` 的 east_asian 用例。

///|
/// 一个抽象编号某级的编号格式。
pub struct LevelFmt {
  ilvl : Int32
  num_fmt : @core.NumFormat
}

///|
/// 跨包构造 LevelFmt（新版 MoonBit 结构体跨包构造受限，集中在这里）。
pub fn make_level_fmt(ilvl : Int32, num_fmt : @core.NumFormat) -> LevelFmt {
  LevelFmt::{ ilvl, num_fmt, }
}

///|
/// 解析 numbering.xml，提取所有 `w:abstractNum/w:lvl` 的级号与格式名。
/// 格式错误返回空数组（调用方可视为无编号信息）。
pub fn parse_numbering(xml : String) -> Array[LevelFmt] {
  let out : Array[LevelFmt] = []
  match parse_xml(xml) {
    Some(root) =>
      for lvl in root.find_all("w:lvl") {
        let ilvl = match lvl.attr("w:ilvl") {
          Some(v) => parse_int(v).unwrap_or(0)
          None => 0
        }
        let fmt = match lvl.child("w:numFmt") {
          Some(nf) =>
            match nf.attr("w:val") {
              Some(v) => numfmt_from_ooxml(v)
              None => @core.NumFormat::decimal()
            }
          None => @core.NumFormat::decimal()
        }
        out.push(LevelFmt::{ ilvl, num_fmt: fmt, })
      }
    None => ()
  }
  out
}

///|
/// 生成最小 numbering.xml：单个 abstractNum（id 0）+ 一个 num（id 1）。
/// 级格式按传入数组写 `w:numFmt`；往返后格式名不变。
pub fn build_numbering(levels : Array[LevelFmt]) -> String {
  let sb = StringBuilder()
  sb.write_string("<w:numbering>")
  sb.write_string("<w:abstractNum w:abstractNumId=\"0\">")
  for l in levels {
    sb.write_string("<w:lvl w:ilvl=\"")
    sb.write_string(l.ilvl.to_string())
    sb.write_string("\"><w:start w:val=\"1\"/><w:numFmt w:val=\"")
    sb.write_string(l.num_fmt.ooxml())
    sb.write_string("\"/></w:lvl>")
  }
  sb.write_string("</w:abstractNum>")
  sb.write_string("<w:num w:numId=\"1\"><w:abstractNumId w:val=\"0\"/></w:num>")
  sb.write_string("</w:numbering>")
  sb.to_string()
}
