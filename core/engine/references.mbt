///|
/// References 命令：脚注/尾注插入。
/// 对应 Rust `engine/cmd/references.rs` 的 `note()`（P1 子集）。
///
/// Rust 行为：
/// - 新建脚注 part：段首 NoteRef + `" {text}"` 正文
/// - 在正文插入同样的 NoteRef（Rust 按光标位置；P1 简化为段落末尾）
/// - custom mark 清洗：去首尾空白、去控制字符、最多 10 个字符
/// - 返回脚注 id（`{"id": id}`）

///|
/// 清洗 custom mark（对应 Rust：trim + filter 非控制字符 + take(10)）。
fn sanitize_mark(mark : String) -> String {
  let chars = mark.trim().to_array()
  let sb = StringBuilder()
  let mut taken = 0
  for c in chars {
    if taken >= 10 {
      break
    }
    let code = c.to_int()
    if code >= 0x20 && (code < 0x7F || code > 0x9F) {
      sb.write_char(c)
      taken += 1
    }
  }
  sb.to_string()
}

///|
/// 插入一条脚注/尾注，返回 id。
/// doc: 文档；kind: 脚注或尾注；para: 插入引用的正文段落索引；
/// text: 脚注正文；mark: 自定义 mark（空 = 自动编号）。
pub fn insert_note(
  doc : @doc.Document,
  kind : @core.NoteKind,
  para : Int32,
  text : String,
  mark : String,
) -> Int32 {
  let custom = sanitize_mark(mark)
  let id = doc.add_note(kind, text, custom)
  doc.push_object(para, @doc.make_noteref(kind, id, custom))
  id
}

///|
/// 插入脚注（对应 `references.footnote`）。
pub fn insert_footnote(
  doc : @doc.Document,
  para : Int32,
  text : String,
  mark : String,
) -> Int32 {
  insert_note(doc, @core.NoteKind::footnote(), para, text, mark)
}

///|
/// 插入尾注（对应 `references.endnote`）。
pub fn insert_endnote(
  doc : @doc.Document,
  para : Int32,
  text : String,
  mark : String,
) -> Int32 {
  insert_note(doc, @core.NoteKind::endnote(), para, text, mark)
}
