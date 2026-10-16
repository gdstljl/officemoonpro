///|
/// 脚注/尾注 XML 片段编解码。
/// 对标 Rust `read/story.rs`（`w:footnoteReference` / `w:footnoteRef` 读取）
/// 与 `write/story.rs`（写入）。

///|
/// footnotes.xml / endnotes.xml 中的一条脚注。
pub struct NoteEntry {
  fid : Int32
  kind : @core.NoteKind
  /// "" 或 separator / continuationSeparator / continuationNotice
  note_type : String
  /// 首个段落的 w:t 文本拼接
  text : String
}

///|
fn parse_note_part(
  xml : String,
  tag : String,
  kind : @core.NoteKind,
) -> Array[NoteEntry] {
  let out : Array[NoteEntry] = []
  match parse_xml(xml) {
    Some(root) =>
      for el in root.find_all(tag) {
        let fid = match el.attr("w:id") {
          Some(v) => parse_int(v).unwrap_or(0)
          None => 0
        }
        let note_type = el.attr("w:type").unwrap_or("")
        out.push(NoteEntry::{
          fid,
          kind,
          note_type,
          text: el.descendant_texts("w:t"),
        })
      }
    None => ()
  }
  out
}

///|
pub fn parse_footnotes(xml : String) -> Array[NoteEntry] {
  parse_note_part(xml, "w:footnote", @core.NoteKind::footnote())
}

///|
pub fn parse_endnotes(xml : String) -> Array[NoteEntry] {
  parse_note_part(xml, "w:endnote", @core.NoteKind::endnote())
}

///|
/// Word 需要的三个标准分隔符条目（对标 Rust fixtures 的断言）。
pub fn footnote_separators() -> Array[NoteEntry] {
  let types = ["separator", "continuationSeparator", "continuationNotice"]
  let ids = [-1, 0, 1]
  let out : Array[NoteEntry] = []
  let mut i = 0
  while i < 3 {
    out.push(NoteEntry::{
      fid: ids[i],
      kind: @core.NoteKind::footnote(),
      note_type: types[i],
      text: "",
    })
    i += 1
  }
  out
}

///|
fn text_run(text : String) -> XmlNode {
  XmlNode::{
    name: "w:r",
    attrs: [],
    children: [
      XmlNode::{
        name: "w:t",
        attrs: [XmlAttr::{ name: "xml:space", value: "preserve", }],
        children: [],
        text,
      },
    ],
    text: "",
  }
}

///|
/// 生成 footnotes.xml / endnotes.xml。
/// 每条一个元素：首段以 `w:footnoteRef`（自引 mark，对标 Rust write）开头，
/// 随后是文本 run；separator 类条目只写空段落。
pub fn build_note_part(entries : Array[NoteEntry], footnote : Bool) -> String {
  let item_tag = if footnote { "w:footnote" } else { "w:endnote" }
  let ref_tag = if footnote { "w:footnoteRef" } else { "w:endnoteRef" }
  let part_tag = if footnote { "w:footnotes" } else { "w:endnotes" }
  let items : Array[XmlNode] = []
  for e in entries {
    let runs : Array[XmlNode] = [
      XmlNode::{
        name: "w:r",
        attrs: [],
        children: [
          XmlNode::{ name: ref_tag, attrs: [], children: [], text: "", },
        ],
        text: "",
      },
    ]
    if e.text != "" {
      runs.push(text_run(e.text))
    }
    let iattrs : Array[XmlAttr] = []
    if e.note_type != "" {
      iattrs.push(XmlAttr::{ name: "w:type", value: e.note_type, })
    }
    iattrs.push(XmlAttr::{ name: "w:id", value: e.fid.to_string(), })
    items.push(XmlNode::{
      name: item_tag,
      attrs: iattrs,
      children: [XmlNode::{ name: "w:p", attrs: [], children: runs, text: "", }],
      text: "",
    })
  }
  write_xml(XmlNode::{ name: part_tag, attrs: [], children: items, text: "", })
}

///|
/// document.xml 中的脚注/尾注引用。
pub struct DocRef {
  fid : Int32
  kind : @core.NoteKind
  custom_mark_follows : Bool
  custom_text : String
}

///|
/// 按文档序提取 `w:footnoteReference` / `w:endnoteReference`。
/// `w:customMarkFollows="1"` 时，紧随其后的兄弟 `w:t` 文本即 custom mark
///（对标 Rust read/story.rs）。
pub fn parse_doc_refs(xml : String) -> Array[DocRef] {
  let out : Array[DocRef] = []
  match parse_xml(xml) {
    None => out
    Some(root) => {
      collect_refs(root, out)
      out
    }
  }
}

///|
fn collect_refs(node : XmlNode, out : Array[DocRef]) -> Unit {
  let kids = node.children
  let mut i = 0
  while i < kids.length() {
    let k = kids[i]
    if k.name == "w:footnoteReference" || k.name == "w:endnoteReference" {
      let foot = k.name == "w:footnoteReference"
      let fid = match k.attr("w:id") {
        Some(v) => parse_int(v).unwrap_or(0)
        None => 0
      }
      let cmf = match k.attr("w:customMarkFollows") {
        Some("1") => true
        Some("true") => true
        _ => false
      }
      let mut ctext = ""
      if cmf && i + 1 < kids.length() && kids[i + 1].name == "w:t" {
        ctext = kids[i + 1].text
      }
      out.push(DocRef::{
        fid,
        kind: if foot {
          @core.NoteKind::footnote()
        } else {
          @core.NoteKind::endnote()
        },
        custom_mark_follows: cmf,
        custom_text: ctext,
      })
    }
    collect_refs(k, out)
    i += 1
  }
}

///|
/// 生成含脚注引用的 document.xml 段落片段。
/// custom mark 走 `w:customMarkFollows` + `w:t`（对标 Rust write/story.rs）。
pub fn build_doc_paragraph(text : String, refs : Array[DocRef]) -> String {
  let runs : Array[XmlNode] = []
  if text != "" {
    runs.push(text_run(text))
  }
  for r in refs {
    let foot = @core.note_kind_eq(r.kind, @core.NoteKind::footnote())
    let tag = if foot { "w:footnoteReference" } else { "w:endnoteReference" }
    let rattrs : Array[XmlAttr] = []
    if r.custom_mark_follows {
      rattrs.push(XmlAttr::{ name: "w:customMarkFollows", value: "1", })
    }
    rattrs.push(XmlAttr::{ name: "w:id", value: r.fid.to_string(), })
    let rchildren : Array[XmlNode] = [
      XmlNode::{ name: tag, attrs: rattrs, children: [], text: "", },
    ]
    if r.custom_mark_follows && r.custom_text != "" {
      rchildren.push(XmlNode::{
        name: "w:t",
        attrs: [XmlAttr::{ name: "xml:space", value: "preserve", }],
        children: [],
        text: r.custom_text,
      })
    }
    runs.push(XmlNode::{
      name: "w:r",
      attrs: [],
      children: rchildren,
      text: "",
    })
  }
  write_xml(XmlNode::{ name: "w:p", attrs: [], children: runs, text: "", })
}

///|
/// 解析 settings.xml 片段中 `w:footnotePr` / `w:endnotePr` 的 `w:numFmt`。
/// 缺失返回 None；名字未知按 Rust 回退为 Decimal。
pub fn parse_settings_numfmt(xml : String, footnote : Bool) -> @core.NumFormat? {
  let tag = if footnote { "w:footnotePr" } else { "w:endnotePr" }
  match parse_xml(xml) {
    None => None
    Some(root) => {
      // find_all 只找后代；根节点本身也可能是目标
      let pr = if root.name == tag {
        Some(root)
      } else {
        let all = root.find_all(tag)
        if all.length() == 0 {
          None
        } else {
          Some(all[0])
        }
      }
      match pr {
        Some(p) =>
          match p.child("w:numFmt") {
            Some(nf) =>
              match nf.attr("w:val") {
                Some(v) => Some(numfmt_from_ooxml(v))
                None => None
              }
            None => None
          }
        None => None
      }
    }
  }
}

///|
/// 生成 settings.xml 的 `w:footnotePr` / `w:endnotePr` 片段（只含 numFmt）。
pub fn build_settings_numfmt(fmt : @core.NumFormat, footnote : Bool) -> String {
  let tag = if footnote { "w:footnotePr" } else { "w:endnotePr" }
  write_xml(XmlNode::{
    name: tag,
    attrs: [],
    children: [
      XmlNode::{
        name: "w:numFmt",
        attrs: [XmlAttr::{ name: "w:val", value: fmt.ooxml(), }],
        children: [],
        text: "",
      },
    ],
    text: "",
  })
}
