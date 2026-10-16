///|
/// OOXML 编号格式名 ↔ NumFormat（全 62 种）。
/// 对标 Rust `NumFormat::ooxml` / `from_ooxml`。
/// 未知名字按 Rust 回退为 Decimal（"不带圈的旧文档行为不变"）。

///|
pub fn numfmt_to_ooxml(fmt : @core.NumFormat) -> String {
  fmt.ooxml()
}

///|
pub fn numfmt_from_ooxml(name : String) -> @core.NumFormat {
  // 对标 Rust：ALL.into_iter().find(|f| f.ooxml() == s).unwrap_or(Decimal)
  for f in @core.all_num_formats {
    if f.ooxml() == name {
      return f
    }
  }
  @core.NumFormat::decimal()
}
