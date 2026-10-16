///|
/// 电子表格数据模型（对标 GridCraft crates/model 子集）。
/// Workbook → Worksheet → Cell；单元格稀疏存储；A1 地址互转。

///|
/// 单元格值（公式求值留待后续；Error 存如 "#DIV/0!" 的文本）。
pub enum CellValue {
  Empty
  Text(String)
  Number(Double)
  Bool(Bool)
  Error(String)
}

///|
pub fn CellValue::is_empty(self : CellValue) -> Bool {
  match self {
    Empty => true
    _ => false
  }
}

///|
/// 跨包构造器。
pub fn CellValue::empty() -> CellValue {
  Empty
}

///|
pub fn CellValue::text(s : String) -> CellValue {
  Text(s)
}

///|
pub fn CellValue::number(n : Double) -> CellValue {
  Number(n)
}

///|
pub fn CellValue::bool(b : Bool) -> CellValue {
  Bool(b)
}

///|
pub fn CellValue::error(e : String) -> CellValue {
  Error(e)
}

///|
/// 显示文本（Web 表格/导出共用）。
pub fn CellValue::display(self : CellValue) -> String {
  match self {
    Empty => ""
    Text(s) => s
    Number(n) => format_number(n)
    Bool(b) => if b { "TRUE" } else { "FALSE" }
    Error(e) => e
  }
}

fn format_number(n : Double) -> String {
  // 整数显示为整数，否则保留小数
  if n == n.to_int().to_double() {
    n.to_int().to_string()
  } else {
    n.to_string()
  }
}

///|
pub struct Cell {
  value : CellValue
  /// 公式文本（不含前导 =）；空字符串表示无公式
  formula : String
}

///|
/// 跨包构造 Cell。
pub fn make_cell(value : CellValue, formula : String) -> Cell {
  Cell::{ value, formula, }
}

///|
pub fn Cell::get_value(self : Cell) -> CellValue {
  self.value
}

///|
pub fn Cell::get_formula(self : Cell) -> String {
  self.formula
}

///|
pub fn Cell::is_blank(self : Cell) -> Bool {
  self.value.is_empty() && self.formula == ""
}

// key = row * 16384 + col（xlsx 最大列数）
fn cell_key(row : Int, col : Int) -> Int {
  row * 16384 + col
}

///|
pub struct Worksheet {
  mut name : String
  cells : @hashmap.HashMap[Int, Cell]
}

///|
/// 跨包构造 Worksheet。
pub fn make_worksheet(name : String) -> Worksheet {
  Worksheet::{ name, cells: @hashmap.HashMap([]), }
}

///|
pub fn Worksheet::get_name(self : Worksheet) -> String {
  self.name
}

///|
pub fn Worksheet::set_name(self : Worksheet, name : String) -> Unit {
  self.name = name
}

///|
pub fn Worksheet::set_cell(self : Worksheet, row : Int, col : Int, value : CellValue) -> Unit {
  self.cells.set(cell_key(row, col), make_cell(value, ""))
}

///|
pub fn Worksheet::set_formula(self : Worksheet, row : Int, col : Int, formula : String) -> Unit {
  // 公式单元格：存公式文本，值暂空（求值器后续填）
  self.cells.set(cell_key(row, col), make_cell(CellValue::empty(), formula))
}

///|
pub fn Worksheet::set_cell_formula(
  self : Worksheet,
  row : Int,
  col : Int,
  value : CellValue,
  formula : String,
) -> Unit {
  self.cells.set(cell_key(row, col), make_cell(value, formula))
}

///|
pub fn Worksheet::get_cell(self : Worksheet, row : Int, col : Int) -> Cell? {
  self.cells.get(cell_key(row, col))
}

///|
pub fn Worksheet::cell_display(self : Worksheet, row : Int, col : Int) -> String {
  match self.get_cell(row, col) {
    Some(c) =>
      if c.get_formula() != "" {
        "=" + c.get_formula()
      } else {
        c.get_value().display()
      }
    None => ""
  }
}

///|
/// 已用区域：(min_row, min_col, max_row, max_col)，空表返回 None。
pub fn Worksheet::used_range(self : Worksheet) -> (Int, Int, Int, Int)? {
  let mut found = false
  let mut min_r = 0
  let mut min_c = 0
  let mut max_r = 0
  let mut max_c = 0
  for k in self.cells.keys() {
    let r = k / 16384
    let c = k % 16384
    if !found {
      min_r = r
      min_c = c
      max_r = r
      max_c = c
      found = true
    } else {
      if r < min_r {
        min_r = r
      }
      if c < min_c {
        min_c = c
      }
      if r > max_r {
        max_r = r
      }
      if c > max_c {
        max_c = c
      }
    }
  }
  if found {
    Some((min_r, min_c, max_r, max_c))
  } else {
    None
  }
}

///|
pub struct Workbook {
  sheets : Array[Worksheet]
}

///|
/// 跨包构造 Workbook。
pub fn make_workbook() -> Workbook {
  Workbook::{ sheets: [], }
}

///|
pub fn Workbook::add_sheet(self : Workbook, name : String) -> Int {
  let ws = make_worksheet(name)
  self.sheets.push(ws)
  self.sheets.length() - 1
}

///|
pub fn Workbook::sheet_count(self : Workbook) -> Int {
  self.sheets.length()
}

///|
pub fn Workbook::get_sheet(self : Workbook, idx : Int) -> Worksheet? {
  if idx >= 0 && idx < self.sheets.length() {
    Some(self.sheets[idx])
  } else {
    None
  }
}

///|
pub fn Workbook::sheet_names(self : Workbook) -> Array[String] {
  let out : Array[String] = []
  for s in self.sheets {
    out.push(s.get_name())
  }
  out
}

// ---- A1 地址 ----

///|
/// 列号（0-based）→ 字母：0→A, 25→Z, 26→AA
pub fn col_to_letters(col : Int) -> String {
  let sb = StringBuilder()
  let mut c = col
  // 用栈逆序
  let stack : Array[Int] = []
  while true {
    stack.push(c % 26)
    c = c / 26 - 1
    if c < 0 {
      break
    }
  }
  let mut i = stack.length() - 1
  while i >= 0 {
    sb.write_char((0x41 + stack[i]).unsafe_to_char())
    i -= 1
  }
  sb.to_string()
}

///|
/// (row, col) 0-based → A1：(0,0)→A1
pub fn rc_to_a1(row : Int, col : Int) -> String {
  col_to_letters(col) + (row + 1).to_string()
}

///|
/// A1 → (row, col) 0-based；非法返回 None。
pub fn a1_to_rc(a1 : String) -> (Int, Int)? {
  let chars = a1.to_array()
  let mut i = 0
  let mut col = 0
  while i < chars.length() {
    let code = chars[i].to_int()
    let v = if code >= 0x41 && code <= 0x5A {
      code - 0x41
    } else if code >= 0x61 && code <= 0x7A {
      code - 0x61
    } else {
      -1
    }
    if v < 0 {
      break
    }
    col = col * 26 + v + 1
    i += 1
  }
  if i == 0 {
    return None
  }
  col -= 1
  let mut row = 0
  let mut has_digit = false
  while i < chars.length() {
    let d = chars[i].to_int() - 0x30
    if d < 0 || d > 9 {
      return None
    }
    row = row * 10 + d
    has_digit = true
    i += 1
  }
  if !has_digit || row < 1 {
    return None
  }
  Some((row - 1, col))
}
