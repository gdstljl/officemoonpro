///|
/// 最小文档模型（对应 Rust `wordcraft_doc` 的 para/section 子集）。
///
/// P1 只做脚注链路需要的部分。Rust 的 `Paragraph { text, runs, objects }`
/// 三件套在这里简化为一个有序的 inline 列表，行为等价、更易移植。

///|
/// 行内对象（Rust `InlineObject` 的 P1 子集）。
pub enum InlineObject {
  /// kind: 脚注/尾注；id: `Document::notes` 的脚注 id；
  /// custom: 自定义 mark（空 = 自动编号，对应 Rust 注释）。
  NoteRef(kind~ : @core.NoteKind, id~ : Int32, custom~ : String)
}

///|
/// 段落行内内容：纯文本或行内对象。
pub enum Inline {
  Text(String)
  Object(InlineObject)
}

///|
/// 跨包构造 NoteRef（新版 MoonBit 变体跨包构造受限，集中在这里）。
pub fn make_noteref(
  kind : @core.NoteKind,
  id : Int32,
  custom : String,
) -> InlineObject {
  NoteRef(kind~, id~, custom~)
}

///|
pub struct Paragraph {
  inlines : Array[Inline]
}

///|
/// 段落纯文本（行内对象不占文本，只出现在结构里）。
pub fn Paragraph::plain_text(self : Paragraph) -> String {
  let sb = StringBuilder()
  for inline in self.inlines {
    match inline {
      Text(t) => sb.write_string(t)
      Object(_) => ()
    }
  }
  sb.to_string()
}

///|
/// 行内元素个数（测试/调试用）。
pub fn Paragraph::inline_count(self : Paragraph) -> Int32 {
  self.inlines.length()
}

///|
/// 第 i 个行内元素是否为脚注引用（测试/调试用）。
pub fn Paragraph::inline_is_noteref(self : Paragraph, i : Int32) -> Bool {
  match self.inlines[i] {
    Object(NoteRef(kind=_, id=_, custom=_)) => true
    _ => false
  }
}

///|
/// 脚注/尾注正文（P1 用纯文本；P2 换成段落数组）。
pub struct Note {
  id : Int32
  kind : @core.NoteKind
  text : String
  mut custom : String
}

///|
/// 最小文档：正文段落 + 脚注库。
pub struct Document {
  body : Array[Paragraph]
  notes : Array[Note]
}

///|
pub fn Document::new() -> Document {
  Document::{ body: [], notes: [], }
}

///|
/// 追加正文段落，返回段落索引。
pub fn Document::add_paragraph(self : Document, text : String) -> Int32 {
  self.body.push(Paragraph::{ inlines: [Text(text)], })
  self.body.length() - 1
}

///|
pub fn Document::paragraph_count(self : Document) -> Int32 {
  self.body.length()
}

///|
pub fn Document::get_paragraph(self : Document, i : Int32) -> Paragraph {
  self.body[i]
}

///|
/// 在段落末尾追加行内对象（如 NoteRef）。
pub fn Document::push_object(
  self : Document,
  para : Int32,
  obj : InlineObject,
) -> Unit {
  self.body[para].inlines.push(Object(obj))
}

///|
/// 注册一条脚注/尾注，返回 id（从 1 开始递增）。
pub fn Document::add_note(
  self : Document,
  kind : @core.NoteKind,
  text : String,
  custom : String,
) -> Int32 {
  let id = self.notes.length() + 1
  self.notes.push(Note::{ id, kind, text, custom, })
  id
}

///|
/// 按 kind 统计已注册的脚注数。
pub fn Document::note_count(self : Document, kind : @core.NoteKind) -> Int32 {
  let mut n = 0
  for note in self.notes {
    if @core.note_kind_eq(note.kind, kind) {
      n += 1
    }
  }
  n
}

///|
/// 按 id 取脚注正文（对应 `references.notes` 的 text 字段）；不存在返回空串。
pub fn Document::find_note_text(self : Document, id : Int32) -> String {
  for note in self.notes {
    if note.id == id {
      return note.text
    }
  }
  ""
}

///|
/// 脚注 mark 文本：custom 非空用 custom，否则按序号和格式自动编号。
/// 序号 = 同 kind 脚注按插入顺序的 1-based 位次，
/// 对应 Rust `layout/src/fields.rs` 的 `FieldCtx::note_mark`。
pub fn Document::note_mark(
  self : Document,
  id : Int32,
  props : @core.NoteProps,
) -> String {
  let mut target = -1
  let mut i = 0
  while i < self.notes.length() {
    if self.notes[i].id == id {
      target = i
    }
    i += 1
  }
  if target < 0 {
    return ""
  }
  let kind = self.notes[target].kind
  let custom = self.notes[target].custom
  if custom != "" {
    return custom
  }
  let mut n = 0
  let mut j = 0
  while j <= target {
    if @core.note_kind_eq(self.notes[j].kind, kind) {
      n += 1
    }
    j += 1
  }
  props.format_mark(n)
}

///|
/// 行内元素快照（跨包读写 document.xml 用）。
/// 用 struct 而不用 enum：字段跨包可读，无需跨包模式匹配。
pub struct InlineView {
  is_text : Bool
  text : String
  kind : @core.NoteKind
  id : Int32
  custom : String
}

///|
/// 第 i 个行内元素的快照。
pub fn Paragraph::inline_view(self : Paragraph, i : Int32) -> InlineView {
  match self.inlines[i] {
    Text(t) =>
      InlineView::{
        is_text: true,
        text: t,
        kind: @core.NoteKind::footnote(),
        id: 0,
        custom: "",
      }
    Object(NoteRef(kind=k, id=nid, custom=c)) =>
      InlineView::{ is_text: false, text: "", kind: k, id: nid, custom: c, }
  }
}

///|
/// 新建空段落，返回索引（docx 读取用）。
pub fn Document::add_empty_paragraph(self : Document) -> Int32 {
  self.body.push(Paragraph::{ inlines: [], })
  self.body.length() - 1
}

///|
/// 在段落末尾追加文本（docx 读取用）。
pub fn Document::push_text(
  self : Document,
  para : Int32,
  text : String,
) -> Unit {
  if text != "" {
    self.body[para].inlines.push(Text(text))
  }
}

///|
/// 设置脚注的 custom mark（docx 读取 customMarkFollows 时用；已有值不覆盖）。
pub fn Document::set_note_custom(
  self : Document,
  id : Int32,
  custom : String,
) -> Unit {
  let mut i = 0
  while i < self.notes.length() {
    if self.notes[i].id == id && self.notes[i].custom == "" {
      self.notes[i].custom = custom
    }
    i += 1
  }
}

///|
/// 脚注库大小（打包 footnotes.xml 用）。
pub fn Document::notes_length(self : Document) -> Int32 {
  self.notes.length()
}

///|
/// 第 i 条脚注（注册顺序）。
pub fn Document::note_at(self : Document, i : Int32) -> Note {
  self.notes[i]
}
