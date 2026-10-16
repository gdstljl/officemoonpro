///|
/// DEFLATE 解压缩（RFC 1951），纯 MoonBit 实现。
/// 输入输出均为字节数组（`Array[Int]`，每项 0–255）。
/// 输入损坏返回 `None`；内部用 raise 传播错误，顶层统一转 Option。

// 长度码基址/附加位（symbol 257–285 → 索引 0–28）
let len_base : Array[Int32] = [
  3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31, 35, 43, 51, 59, 67, 83,
  99, 115, 131, 163, 195, 227, 258,
]

///|
let len_extra : Array[Int32] = [
  0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5,
  5, 0,
]
// 距离码基址/附加位（symbol 0–29）

///|
let dist_base : Array[Int32] = [
  1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193, 257, 385, 513, 769,
  1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577,
]

///|
let dist_extra : Array[Int32] = [
  0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11,
  12, 12, 13, 13,
]
// 动态 Huffman：19 个码长码的传输顺序

///|
let cl_order : Array[Int32] = [
  16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15,
]

///|
struct BitReader {
  data : Array[Int32]
  /// pos[0]：绝对位偏移，LSB-first（用单元素数组以便方法内可变）
  pos : Array[Int32]
}

///|
fn BitReader::read_bits(self : BitReader, n : Int32) -> Int32 raise {
  let mut v = 0
  let mut i = 0
  while i < n {
    let p = self.pos[0]
    if p / 8 >= self.data.length() {
      raise Failure("inflate: truncated input")
    }
    let b = self.data[p / 8]
    v = v | (((b >> (p % 8)) & 1) << i)
    self.pos[0] = p + 1
    i += 1
  }
  v
}

///|
/// Huffman 解码二叉树：child[2*node+bit]，-1 表无；sym[node]，-1 表内部节点。
struct HuffTree {
  child : Array[Int32]
  sym : Array[Int32]
}

///|
fn new_tree() -> HuffTree {
  HuffTree::{ child: [-1, -1], sym: [-1], }
}

///|
fn tree_insert(t : HuffTree, code : Int32, len : Int32, symbol : Int32) -> Unit {
  let mut node = 0
  let mut i = 0
  while i < len {
    // 码字在线上是 MSB-first 传输（RFC 1951 §3.2.2），按线序插入
    let bit = (code >> (len - 1 - i)) & 1
    let slot = node * 2 + bit
    while t.child.length() <= slot {
      t.child.push(-1)
    }
    if t.child[slot] == -1 {
      let nn = t.sym.length()
      t.child[slot] = nn
      t.child.push(-1)
      t.child.push(-1)
      t.sym.push(-1)
    }
    node = t.child[slot]
    i += 1
  }
  t.sym[node] = symbol
}

///|
fn tree_decode(t : HuffTree, br : BitReader) -> Int32 raise {
  let mut node = 0
  let mut result = -1
  while result == -1 {
    let s = t.sym[node]
    if s != -1 {
      result = s
    } else {
      let bit = br.read_bits(1)
      let nxt = t.child[node * 2 + bit]
      if nxt == -1 {
        raise Failure("inflate: bad huffman code")
      }
      node = nxt
    }
  }
  result
}

///|
/// 由码长数组建规范 Huffman 树。
fn build_tree(lengths : Array[Int32]) -> HuffTree raise {
  let mut max_len = 0
  for l in lengths {
    if l > max_len {
      max_len = l
    }
  }
  if max_len == 0 {
    raise Failure("inflate: empty huffman tree")
  }
  let bl_count : Array[Int32] = []
  let next_code : Array[Int32] = []
  let mut i = 0
  while i <= max_len {
    bl_count.push(0)
    next_code.push(0)
    i += 1
  }
  for l in lengths {
    if l > 0 {
      bl_count[l] = bl_count[l] + 1
    }
  }
  let mut code = 0
  let mut bits = 1
  while bits <= max_len {
    code = (code + bl_count[bits - 1]) << 1
    next_code[bits] = code
    bits += 1
  }
  let t = new_tree()
  let mut n = 0
  while n < lengths.length() {
    let len = lengths[n]
    if len != 0 {
      tree_insert(t, next_code[len], len, n)
      next_code[len] = next_code[len] + 1
    }
    n += 1
  }
  t
}

///|
fn fixed_litlen_tree() -> HuffTree raise {
  let lengths : Array[Int32] = []
  let mut i = 0
  while i < 288 {
    let l = if i < 144 {
      8
    } else if i < 256 {
      9
    } else if i < 280 {
      7
    } else {
      8
    }
    lengths.push(l)
    i += 1
  }
  build_tree(lengths)
}

///|
fn fixed_dist_tree() -> HuffTree raise {
  let lengths : Array[Int32] = []
  let mut i = 0
  while i < 32 {
    lengths.push(5)
    i += 1
  }
  build_tree(lengths)
}

///|
fn decode_block(
  br : BitReader,
  litlen : HuffTree,
  dist : HuffTree,
  out : Array[Int32],
) -> Unit raise {
  let mut done = false
  while !done {
    let sym = tree_decode(litlen, br)
    if sym < 256 {
      out.push(sym)
    } else if sym == 256 {
      done = true
    } else if sym <= 285 {
      let li = sym - 257
      let length = len_base[li] + br.read_bits(len_extra[li])
      let dsym = tree_decode(dist, br)
      if dsym < 0 || dsym > 29 {
        raise Failure("inflate: bad distance symbol")
      }
      let dist_ = dist_base[dsym] + br.read_bits(dist_extra[dsym])
      if dist_ <= 0 || dist_ > out.length() {
        raise Failure("inflate: bad distance")
      }
      let mut i = 0
      while i < length {
        out.push(out[out.length() - dist_])
        i += 1
      }
    } else {
      raise Failure("inflate: bad literal/length symbol")
    }
  }
}

///|
fn dynamic_trees(br : BitReader) -> (HuffTree, HuffTree) raise {
  let hlit = br.read_bits(5) + 257
  let hdist = br.read_bits(5) + 1
  let hclen = br.read_bits(4) + 4
  let cl_lengths : Array[Int32] = []
  let mut i = 0
  while i < 19 {
    cl_lengths.push(0)
    i += 1
  }
  i = 0
  while i < hclen {
    cl_lengths[cl_order[i]] = br.read_bits(3)
    i += 1
  }
  let cl_tree = build_tree(cl_lengths)
  let total = hlit + hdist
  let lengths : Array[Int32] = []
  i = 0
  while i < total {
    lengths.push(0)
    i += 1
  }
  i = 0
  while i < total {
    let sym = tree_decode(cl_tree, br)
    if sym <= 15 {
      lengths[i] = sym
      i += 1
    } else if sym == 16 {
      if i == 0 {
        raise Failure("inflate: bad repeat")
      }
      let rep = br.read_bits(2) + 3
      let prev = lengths[i - 1]
      let mut j = 0
      while j < rep {
        if i >= total {
          raise Failure("inflate: bad repeat")
        }
        lengths[i] = prev
        i += 1
        j += 1
      }
    } else if sym == 17 {
      let rep = br.read_bits(3) + 3
      let mut j = 0
      while j < rep {
        if i >= total {
          raise Failure("inflate: bad repeat")
        }
        lengths[i] = 0
        i += 1
        j += 1
      }
    } else if sym == 18 {
      let rep = br.read_bits(7) + 11
      let mut j = 0
      while j < rep {
        if i >= total {
          raise Failure("inflate: bad repeat")
        }
        lengths[i] = 0
        i += 1
        j += 1
      }
    } else {
      raise Failure("inflate: bad code length symbol")
    }
  }
  let lit_lengths : Array[Int32] = []
  let dist_lengths : Array[Int32] = []
  i = 0
  while i < hlit {
    lit_lengths.push(lengths[i])
    i += 1
  }
  while i < total {
    dist_lengths.push(lengths[i])
    i += 1
  }
  (build_tree(lit_lengths), build_tree(dist_lengths))
}

///|
fn inflate_inner(data : Array[Int32]) -> Array[Int32] raise {
  let br = BitReader::{ data, pos: [0], }
  let out : Array[Int32] = []
  let mut is_final = false
  while !is_final {
    is_final = br.read_bits(1) == 1
    let btype = br.read_bits(2)
    if btype == 0 {
      // stored：对齐到字节边界
      let p = br.pos[0]
      br.pos[0] = (p + 7) / 8 * 8
      let len = br.read_bits(16)
      let nlen = br.read_bits(16)
      if (len ^ nlen) != 0xFFFF {
        raise Failure("inflate: bad stored block lengths")
      }
      let mut i = 0
      while i < len {
        let byte_pos = br.pos[0] / 8
        if byte_pos >= data.length() {
          raise Failure("inflate: truncated input")
        }
        out.push(data[byte_pos])
        br.pos[0] = br.pos[0] + 8
        i += 1
      }
    } else if btype == 1 {
      decode_block(br, fixed_litlen_tree(), fixed_dist_tree(), out)
    } else if btype == 2 {
      let (litlen, dist) = dynamic_trees(br)
      decode_block(br, litlen, dist, out)
    } else {
      raise Failure("inflate: bad block type")
    }
  }
  out
}

///|
/// DEFLATE 解压缩；输入损坏返回 `None`。
pub fn inflate(data : Array[Int32]) -> Array[Int32]? {
  Some(inflate_inner(data)) catch {
    _ => None
  }
}
