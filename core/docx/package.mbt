///|
/// docx 包层：zip 条目（名 → XML 文本）与 `Document` 模型互转。
/// zip 容器由 `core/zip` 提供；这里只处理条目内容。

///|
pub struct PackageDoc {
  doc : @doc.Document
  footnote_fmt : @core.NumFormat
  endnote_fmt : @core.NumFormat
  numbering : Array[LevelFmt]
}

///|
/// 跨包构造 PackageDoc（新版 MoonBit 结构体跨包构造受限，集中在这里）。
pub fn make_package_doc(
  doc : @doc.Document,
  footnote_fmt : @core.NumFormat,
  endnote_fmt : @core.NumFormat,
  numbering : Array[LevelFmt],
) -> PackageDoc {
  PackageDoc::{ doc, footnote_fmt, endnote_fmt, numbering, }
}

///|
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
struct FidMap {
  fid : Int32
  id : Int32
  kind : @core.NoteKind
}

///|
/// 读脚注库：按 XML 顺序注册，跳过 separator 类条目。
fn read_note_lib(
  entries : Array[(String, String)],
  part : String,
  footnote : Bool,
  doc : @doc.Document,
  fmap : Array[FidMap],
) -> Unit {
  let xml = match find_entry(entries, part) {
    Some(x) => x
    None => return
  }
  let parsed = if footnote { parse_footnotes(xml) } else { parse_endnotes(xml) }
  for ne in parsed {
    if ne.note_type == "" {
      let id = doc.add_note(ne.kind, ne.text, "")
      fmap.push(FidMap::{ fid: ne.fid, id, kind: ne.kind, })
    }
  }
}

///|
fn lookup_fid(fmap : Array[FidMap], fid : Int32) -> FidMap? {
  for m in fmap {
    if m.fid == fid {
      return Some(m)
    }
  }
  None
}

///|
fn read_run(
  r_el : XmlNode,
  doc : @doc.Document,
  para : Int32,
  fmap : Array[FidMap],
) -> Unit {
  let kids = r_el.children
  let mut i = 0
  while i < kids.length() {
    let k = kids[i]
    if k.name == "w:t" {
      doc.push_text(para, k.text)
    } else if k.name == "w:footnoteReference" || k.name == "w:endnoteReference" {
      let fid = match k.attr("w:id") {
        Some(v) => parse_int(v).unwrap_or(0)
        None => 0
      }
      // customMarkFollows：后随兄弟 w:t 即 custom mark
      let mut custom = ""
      match k.attr("w:customMarkFollows") {
        Some("1") =>
          if i + 1 < kids.length() && kids[i + 1].name == "w:t" {
            custom = kids[i + 1].text
            i += 1 // 该 w:t 是 custom mark，不当正文
          }
        _ => ()
      }
      match lookup_fid(fmap, fid) {
        Some(m) => {
          doc.push_object(para, @doc.make_noteref(m.kind, m.id, ""))
          if custom != "" {
            doc.set_note_custom(m.id, custom)
          }
        }
        None => ()
      }
    }
    i += 1
  }
}

///|
/// 从条目表读取文档子集。缺少 `word/document.xml` 或 XML 损坏返回 `None`。
pub fn read_package(entries : Array[(String, String)]) -> PackageDoc? {
  let doc_xml = match find_entry(entries, "word/document.xml") {
    Some(x) => x
    None => return None
  }
  let doc = @doc.Document::new()
  let fmap : Array[FidMap] = []
  read_note_lib(entries, "word/footnotes.xml", true, doc, fmap)
  read_note_lib(entries, "word/endnotes.xml", false, doc, fmap)
  match parse_xml(doc_xml) {
    Some(root) =>
      for p_el in root.find_all("w:p") {
        let para = doc.add_empty_paragraph()
        for child in p_el.children {
          if child.name == "w:r" {
            read_run(child, doc, para, fmap)
          }
        }
      }
    None => return None
  }
  let numbering = match find_entry(entries, "word/numbering.xml") {
    Some(xml) => parse_numbering(xml)
    None => []
  }
  let footnote_fmt = match find_entry(entries, "word/settings.xml") {
    Some(xml) =>
      parse_settings_numfmt(xml, true).unwrap_or(@core.NumFormat::decimal())
    None => @core.NumFormat::decimal()
  }
  let endnote_fmt = match find_entry(entries, "word/settings.xml") {
    Some(xml) =>
      parse_settings_numfmt(xml, false).unwrap_or(@core.NumFormat::decimal())
    None => @core.NumFormat::decimal()
  }
  Some(PackageDoc::{ doc, footnote_fmt, endnote_fmt, numbering, })
}

///|
fn collect_notes(doc : @doc.Document, footnote : Bool) -> Array[NoteEntry] {
  let out : Array[NoteEntry] = []
  let mut i = 0
  while i < doc.notes_length() {
    let n = doc.note_at(i)
    let want = @core.note_kind_eq(n.kind, @core.NoteKind::footnote())
    if want == footnote {
      out.push(NoteEntry::{
        fid: n.id,
        kind: n.kind,
        note_type: "",
        text: n.text,
      })
    }
    i += 1
  }
  out
}

///|
fn build_document_xml(doc : @doc.Document) -> String {
  let sb = StringBuilder()
  sb.write_string("<w:document><w:body>")
  let mut pi = 0
  while pi < doc.paragraph_count() {
    let para = doc.get_paragraph(pi)
    sb.write_string("<w:p>")
    let mut ii = 0
    while ii < para.inline_count() {
      let v = para.inline_view(ii)
      if v.is_text {
        sb.write_string("<w:r><w:t xml:space=\"preserve\">")
        sb.write_string(escape_xml(v.text))
        sb.write_string("</w:t></w:r>")
      } else {
        let foot = @core.note_kind_eq(v.kind, @core.NoteKind::footnote())
        let tag = if foot {
          "w:footnoteReference"
        } else {
          "w:endnoteReference"
        }
        sb.write_string("<w:r><")
        sb.write_string(tag)
        if v.custom != "" {
          sb.write_string(" w:customMarkFollows=\"1\"")
        }
        sb.write_string(" w:id=\"")
        sb.write_string(v.id.to_string())
        sb.write_string("\"/>")
        if v.custom != "" {
          sb.write_string("<w:t xml:space=\"preserve\">")
          sb.write_string(escape_xml(v.custom))
          sb.write_string("</w:t>")
        }
        sb.write_string("</w:r>")
      }
      ii += 1
    }
    sb.write_string("</w:p>")
    pi += 1
  }
  sb.write_string("</w:body></w:document>")
  sb.to_string()
}

///|
fn build_settings_xml(pd : PackageDoc) -> String {
  "<w:settings>" +
  build_settings_numfmt(pd.footnote_fmt, true) +
  build_settings_numfmt(pd.endnote_fmt, false) +
  "</w:settings>"
}

///|
fn build_content_types(
  has_footnotes : Bool,
  has_endnotes : Bool,
  has_numbering : Bool,
) -> String {
  let sb = StringBuilder()
  sb.write_string(
    "<Types xmlns=\"http://schemas.openxmlformats.org/package/2006/content-types\">",
  )
  sb.write_string(
    "<Default Extension=\"rels\" ContentType=\"application/vnd.openxmlformats-package.relationships+xml\"/>",
  )
  sb.write_string(
    "<Default Extension=\"xml\" ContentType=\"application/xml\"/>",
  )
  sb.write_string(
    "<Override PartName=\"/word/document.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml\"/>",
  )
  if has_footnotes {
    sb.write_string(
      "<Override PartName=\"/word/footnotes.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.wordprocessingml.footnotes+xml\"/>",
    )
  }
  if has_endnotes {
    sb.write_string(
      "<Override PartName=\"/word/endnotes.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.wordprocessingml.endnotes+xml\"/>",
    )
  }
  if has_numbering {
    sb.write_string(
      "<Override PartName=\"/word/numbering.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.wordprocessingml.numbering+xml\"/>",
    )
  }
  sb.write_string(
    "<Override PartName=\"/word/settings.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.wordprocessingml.settings+xml\"/>",
  )
  sb.write_string("</Types>")
  sb.to_string()
}

///|
fn build_rels_document(
  has_footnotes : Bool,
  has_endnotes : Bool,
  has_numbering : Bool,
) -> String {
  let sb = StringBuilder()
  sb.write_string(
    "<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">",
  )
  let mut rid = 1
  if has_footnotes {
    sb.write_string(
      "<Relationship Id=\"rId\{rid}\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/footnotes\" Target=\"footnotes.xml\"/>",
    )
    rid += 1
  }
  if has_endnotes {
    sb.write_string(
      "<Relationship Id=\"rId\{rid}\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/endnotes\" Target=\"endnotes.xml\"/>",
    )
    rid += 1
  }
  if has_numbering {
    sb.write_string(
      "<Relationship Id=\"rId\{rid}\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/numbering\" Target=\"numbering.xml\"/>",
    )
    rid += 1
  }
  sb.write_string(
    "<Relationship Id=\"rId\{rid}\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/settings\" Target=\"settings.xml\"/>",
  )
  sb.write_string("</Relationships>")
  sb.to_string()
}

///|
/// 把 `PackageDoc` 打包为 zip 条目（名 → XML 文本）。
pub fn write_package(pd : PackageDoc) -> Array[(String, String)] {
  let entries : Array[(String, String)] = []
  entries.push(("word/document.xml", build_document_xml(pd.doc)))
  let footnotes = collect_notes(pd.doc, true)
  let endnotes = collect_notes(pd.doc, false)
  let has_footnotes = footnotes.length() > 0
  let has_endnotes = endnotes.length() > 0
  // 标准分隔符 + 正文条目
  if has_footnotes {
    let all = footnote_separators()
    for e in footnotes {
      all.push(e)
    }
    entries.push(("word/footnotes.xml", build_note_part(all, true)))
  }
  if has_endnotes {
    entries.push(("word/endnotes.xml", build_note_part(endnotes, false)))
  }
  let has_numbering = pd.numbering.length() > 0
  if has_numbering {
    entries.push(("word/numbering.xml", build_numbering(pd.numbering)))
  }
  entries.push(("word/settings.xml", build_settings_xml(pd)))
  entries.push(
    (
      "[Content_Types].xml",
      build_content_types(has_footnotes, has_endnotes, has_numbering),
    ),
  )
  entries.push(
    (
      "_rels/.rels", "<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\"><Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument\" Target=\"word/document.xml\"/></Relationships>",
    ),
  )
  entries.push(
    (
      "word/_rels/document.xml.rels",
      build_rels_document(has_footnotes, has_endnotes, has_numbering),
    ),
  )
  entries
}
