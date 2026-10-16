///|
/// 带圈数字序号（ECMA-376: decimalEnclosedCircle / decimalEnclosedCircleChinese）
/// 1..=1000 全部输出带圈字形；0 与 >1000 回退十进制。
///
/// 对应 Rust 实现 `crates/doc/src/cjk_numbers.rs` 的 `enclosed` 系列函数，
/// 断点从 20（中文变体 10）扩展到 1000。

///|
/// 逐位组圈的上限：第 1001 个起回退十进制。
/// 改这个常量即可调整上限，无需改算法。
pub const CIRCLE_MAX : Int32 = 1000

///|
/// ⓪ ① ② … ⑨：多位数字逐位组圈的字模（0 用 U+24EA，1..9 用 U+2460..U+2469）。
let circled_digit_table : Array[String] = [
  "⓪", "①", "②", "③", "④", "⑤", "⑥", "⑦", "⑧", "⑨",
]

///|
/// ① … ⑳（U+2460..U+2473）。
let circled_1_20 : Array[String] = [
  "①", "②", "③", "④", "⑤", "⑥", "⑦", "⑧", "⑨", "⑩", "⑪", "⑫",
  "⑬", "⑭", "⑮", "⑯", "⑰", "⑱", "⑲", "⑳",
]

///|
/// ㉑ … ㉟（U+3251..U+325F）。
let circled_21_35 : Array[String] = [
  "㉑", "㉒", "㉓", "㉔", "㉕", "㉖", "㉗", "㉘", "㉙", "㉚", "㉛", "㉜",
  "㉝", "㉞", "㉟",
]

///|
/// ㊱ … ㊿（U+32B1..U+32BF）。
let circled_36_50 : Array[String] = [
  "㊱", "㊲", "㊳", "㊴", "㊵", "㊶", "㊷", "㊸", "㊹", "㊺", "㊻", "㊼",
  "㊽", "㊾", "㊿",
]

///|
/// 51..=CIRCLE_MAX：每位十进制数字单独成圈。
/// 51 → ⑤①；100 → ①⓪⓪；1000 → ①⓪⓪⓪。
///
/// 用除法和取模拆位（不依赖字符串迭代），高位到低位依次追加。
fn circled_multi(n : Int32) -> String {
  let sb = StringBuilder()
  let mut div = 1
  while n / div >= 10 {
    div = div * 10
  }
  let mut rest = n
  while div > 0 {
    sb.write_string(circled_digit_table[rest / div])
    rest = rest % div
    div = div / 10
  }
  sb.to_string()
}

///|
/// 带圈数字：1..=20 ①…⑳；21..=35 ㉑…㉟；36..=50 ㊱…㊿；
/// 51..=1000 逐位组圈；0 与 >1000 回退十进制。
///
/// 纯函数，无 IO、无全局状态。
pub fn circled(n : Int32) -> String {
  if n >= 1 && n <= 20 {
    circled_1_20[n - 1]
  } else if n >= 21 && n <= 35 {
    circled_21_35[n - 21]
  } else if n >= 36 && n <= 50 {
    circled_36_50[n - 36]
  } else if n >= 51 && n <= CIRCLE_MAX {
    circled_multi(n)
  } else {
    n.to_string()
  }
}
