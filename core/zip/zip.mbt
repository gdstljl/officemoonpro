///|
/// ZIP 读写（子集）：读支持 stored / deflated 条目；
/// 写只用 stored（Word 可正常打开，符合 APPNOTE）。
/// 条目名按 UTF-8 处理。

///|
pub struct ZipEntry {
  name : String
  /// 解压后字节
  data : Array[Int32]
}

///|
fn le16(bytes : Array[Byte], pos : Int32) -> Int32 {
  bytes[pos].to_int() | (bytes[pos + 1].to_int() << 8)
}

///|
fn le32(bytes : Array[Byte], pos : Int32) -> Int32 {
  bytes[pos].to_int() |
  (bytes[pos + 1].to_int() << 8) |
  (bytes[pos + 2].to_int() << 16) |
  (bytes[pos + 3].to_int() << 24)
}

///|
/// 找 EOCD 记录（从尾部向前扫，容忍注释）。
fn find_eocd(bytes : Array[Byte]) -> Int32? {
  let n = bytes.length()
  if n < 22 {
    return None
  }
  let mut i = n - 22
  let lo = if n > 66000 { n - 66000 } else { 0 }
  while i >= lo {
    if le32(bytes, i) == 0x06054B50 {
      return Some(i)
    }
    i -= 1
  }
  None
}

///|
fn slice_int(bytes : Array[Byte], from : Int32, to : Int32) -> Array[Int32] {
  let out : Array[Int32] = []
  let mut i = from
  while i < to {
    out.push(bytes[i].to_int())
    i += 1
  }
  out
}

///|
fn slice_utf8(bytes : Array[Byte], from : Int32, len : Int32) -> String {
  let raw : Array[Byte] = []
  let mut i = 0
  while i < len {
    raw.push(bytes[from + i])
    i += 1
  }
  @utf8.decode_lossy(Bytes::from_array(raw[:]))
}

///|
priv struct CentralEntry {
  name : String
  method : Int32
  crc : UInt32
  comp_size : Int32
  header_offset : Int32
}

///|
fn read_central(bytes : Array[Byte]) -> Array[CentralEntry]? {
  let eocd = match find_eocd(bytes) {
    Some(e) => e
    None => return None
  }
  let count = le16(bytes, eocd + 10)
  let cd_offset = le32(bytes, eocd + 16)
  let out : Array[CentralEntry] = []
  let mut pos = cd_offset
  let mut i = 0
  while i < count {
    if pos + 46 > bytes.length() || le32(bytes, pos) != 0x02014B50 {
      return None
    }
    let method = le16(bytes, pos + 10)
    let crc = le32(bytes, pos + 16).to_uint()
    let comp_size = le32(bytes, pos + 24)
    let name_len = le16(bytes, pos + 28)
    let extra_len = le16(bytes, pos + 30)
    let comment_len = le16(bytes, pos + 32)
    let header_offset = le32(bytes, pos + 42)
    let name = slice_utf8(bytes, pos + 46, name_len)
    out.push(CentralEntry::{ name, method, crc, comp_size, header_offset, })
    pos = pos + 46 + name_len + extra_len + comment_len
    i += 1
  }
  Some(out)
}

///|
/// 解析 zip 包，返回条目（名 → 解压后字节）；损坏返回 `None`。
pub fn read_zip(data : Bytes) -> Array[ZipEntry]? {
  let bytes = data.to_array()
  let central = match read_central(bytes) {
    Some(c) => c
    None => return None
  }
  let out : Array[ZipEntry] = []
  for e in central {
    let off = e.header_offset
    if off + 30 > bytes.length() || le32(bytes, off) != 0x04034B50 {
      return None
    }
    let name_len = le16(bytes, off + 26)
    let extra_len = le16(bytes, off + 28)
    let data_off = off + 30 + name_len + extra_len
    if data_off + e.comp_size > bytes.length() {
      return None
    }
    let raw = slice_int(bytes, data_off, data_off + e.comp_size)
    let data_ = if e.method == 8 {
      match inflate(raw) {
        Some(d) => d
        None => return None
      }
    } else if e.method == 0 {
      raw
    } else {
      return None
    }
    if crc32(data_) != e.crc {
      return None
    }
    out.push(ZipEntry::{ name: e.name, data: data_, })
  }
  Some(out)
}

///|
/// 解析 zip 包并把条目内容按 UTF-8 解码为文本；损坏返回 `None`。
pub fn read_zip_text(data : Bytes) -> Array[(String, String)]? {
  match read_zip(data) {
    Some(entries) => {
      let out : Array[(String, String)] = []
      for e in entries {
        let raw : Array[Byte] = []
        for b in e.data {
          raw.push(b.to_byte())
        }
        out.push((e.name, @utf8.decode_lossy(Bytes::from_array(raw[:]))))
      }
      Some(out)
    }
    None => None
  }
}

// ---- 写 ----

///|
fn write_u16(out : Array[Int32], v : Int32) -> Unit {
  out.push(v & 0xFF)
  out.push((v >> 8) & 0xFF)
}

///|
fn write_u32(out : Array[Int32], v : UInt32) -> Unit {
  out.push((v & 0xFF).to_int())
  out.push(((v >> 8) & 0xFF).to_int())
  out.push(((v >> 16) & 0xFF).to_int())
  out.push(((v >> 24) & 0xFF).to_int())
}

///|
fn write_bytes(out : Array[Int32], bs : Array[Byte]) -> Unit {
  for b in bs {
    out.push(b.to_int())
  }
}

///|
/// 打包 zip（全部条目用 stored 方式；Word 可正常打开）。
/// entries: (条目名, 内容字节)。
pub fn write_zip(entries : Array[(String, Bytes)]) -> Bytes {
  let out : Array[Int32] = []
  // 中央目录需要的信息：(名, crc, 大小, 本地头偏移)
  let names : Array[Array[Byte]] = []
  let crcs : Array[UInt32] = []
  let sizes : Array[Int32] = []
  let offsets : Array[Int32] = []
  for e in entries {
    let (name, data) = e
    let name_bs = @utf8.encode(name).to_array()
    let data_bs = data.to_array()
    let data_int = slice_int(data_bs, 0, data_bs.length())
    let crc = crc32(data_int)
    let size = data_bs.length()
    offsets.push(out.length())
    // 本地文件头
    write_u32(out, 0x04034B50)
    write_u16(out, 20) // 版本需求
    write_u16(out, 0x0800) // UTF-8 标志
    write_u16(out, 0) // stored
    write_u16(out, 0) // 修改时间
    write_u16(out, 0) // 修改日期
    write_u32(out, crc)
    write_u32(out, size.to_uint())
    write_u32(out, size.to_uint())
    write_u16(out, name_bs.length())
    write_u16(out, 0) // 扩展区长度
    write_bytes(out, name_bs)
    write_bytes(out, data_bs)
    names.push(name_bs)
    crcs.push(crc)
    sizes.push(size)
  }
  let cd_offset = out.length()
  let mut i = 0
  while i < entries.length() {
    let name_bs = names[i]
    write_u32(out, 0x02014B50)
    write_u16(out, 0x3F14) // made by：Unix + 版本 20
    write_u16(out, 20)
    write_u16(out, 0x0800)
    write_u16(out, 0)
    write_u16(out, 0)
    write_u16(out, 0)
    write_u32(out, crcs[i])
    write_u32(out, sizes[i].to_uint())
    write_u32(out, sizes[i].to_uint())
    write_u16(out, name_bs.length())
    write_u16(out, 0)
    write_u16(out, 0)
    write_u16(out, 0) // 磁盘号
    write_u16(out, 0) // 内部属性
    write_u32(out, 0) // 外部属性
    write_u32(out, offsets[i].to_uint())
    write_bytes(out, name_bs)
    i += 1
  }
  let cd_size = out.length() - cd_offset
  // EOCD
  write_u32(out, 0x06054B50)
  write_u16(out, 0)
  write_u16(out, 0)
  write_u16(out, entries.length())
  write_u16(out, entries.length())
  write_u32(out, cd_size.to_uint())
  write_u32(out, cd_offset.to_uint())
  write_u16(out, 0) // 注释长度
  let final_bs : Array[Byte] = []
  for b in out {
    final_bs.push(b.to_byte())
  }
  Bytes::from_array(final_bs[:])
}

///|
/// 打包 zip，条目内容为 UTF-8 文本。
pub fn write_zip_text(entries : Array[(String, String)]) -> Bytes {
  let bs : Array[(String, Bytes)] = []
  for e in entries {
    let (name, text) = e
    bs.push((name, @utf8.encode(text)))
  }
  write_zip(bs)
}
