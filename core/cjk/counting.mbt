///|
/// 东亚计数系统（对标 Rust `crates/doc/src/cjk_numbers.rs`）：
/// 万进制计数（十/百/千 + 万/億）、汉字数字、假名/谚文序列、带圈数。
/// 超出序列范围的值回退十进制（与 Rust 一致）。

///|
/// 计数系统中"一"在单位前的省略规则。
priv enum OmitOne {
  Never
  LeadingTen
  Units
}

///|
/// 万进制计数系统（每 4 位一组，如 1|2345|6789）。
priv struct Counting {
  /// 数字 0–9（索引 0 仅占位/零值用）
  digits : Array[String]
  /// 单位：十、百、千
  units : Array[String]
  /// 万进位：万、亿
  myriads : Array[String]
  /// 零字符（中文 零）；None 则跳过零
  zero : String?
  omit_one : OmitOne
}

///|
let cn_digits : Array[String] = [
  "〇", "一", "二", "三", "四", "五", "六", "七", "八", "九",
]

///|
let chinese_sys : Counting = Counting::{
  digits: cn_digits,
  units: ["十", "百", "千"],
  myriads: ["万", "亿"],
  zero: Some("零"),
  omit_one: OmitOne::LeadingTen,
}

///|
let taiwanese_sys : Counting = Counting::{
  digits: cn_digits,
  units: ["十", "百", "千"],
  myriads: ["萬", "億"],
  zero: Some("零"),
  omit_one: OmitOne::LeadingTen,
}

///|
let chinese_legal_sys : Counting = Counting::{
  digits: ["零", "壹", "贰", "叁", "肆", "伍", "陆", "柒", "捌", "玖"],
  units: ["拾", "佰", "仟"],
  myriads: ["万", "亿"],
  zero: Some("零"),
  omit_one: OmitOne::Never,
}

///|
let traditional_legal_sys : Counting = Counting::{
  digits: ["零", "壹", "貳", "參", "肆", "伍", "陸", "柒", "捌", "玖"],
  units: ["拾", "佰", "仟"],
  myriads: ["萬", "億"],
  zero: Some("零"),
  omit_one: OmitOne::Never,
}

///|
let japanese_sys : Counting = Counting::{
  digits: cn_digits,
  units: ["十", "百", "千"],
  myriads: ["万", "億"],
  zero: None,
  omit_one: OmitOne::Units,
}

///|
let japanese_legal_sys : Counting = Counting::{
  digits: ["〇", "壱", "弐", "参", "四", "伍", "六", "七", "八", "九"],
  units: ["拾", "百", "阡"],
  myriads: ["萬", "億"],
  zero: None,
  omit_one: OmitOne::Never,
}

///|
let korean_sys : Counting = Counting::{
  digits: ["영", "일", "이", "삼", "사", "오", "육", "칠", "팔", "구"],
  units: ["십", "백", "천"],
  myriads: ["만", "억"],
  zero: None,
  omit_one: OmitOne::Units,
}

///|
fn counting_format(c : Counting, n : Int32) -> String {
  if n == 0 {
    return match c.zero {
      Some(z) => z
      None => "〇"
    }
  }
  let groups = [n / 100000000, n / 10000 % 10000, n % 10000]
  let sb = StringBuilder()
  let mut started = false
  let mut zero_pending = false
  let mut gi = 0
  while gi < 3 {
    let g = groups[gi]
    if g == 0 {
      if started {
        zero_pending = true
      }
    } else {
      let ds = [g / 1000, g / 100 % 10, g / 10 % 10, g % 10]
      let mut pos = 0
      while pos < 4 {
        let d = ds[pos]
        if d == 0 {
          if started {
            zero_pending = true
          }
        } else {
          if zero_pending {
            match c.zero {
              Some(z) => sb.write_string(z)
              None => ()
            }
          }
          zero_pending = false
          let unit = match pos {
            0 => Some(c.units[2])
            1 => Some(c.units[1])
            2 => Some(c.units[0])
            _ => None
          }
          let mut omit = false
          match unit {
            Some(_) =>
              if d == 1 {
                omit = match c.omit_one {
                  OmitOne::Never => false
                  OmitOne::LeadingTen => pos == 2 && !started
                  OmitOne::Units => true
                }
              }
            None => ()
          }
          if !omit {
            sb.write_string(c.digits[d])
          }
          match unit {
            Some(u) => sb.write_string(u)
            None => ()
          }
          started = true
        }
        pos += 1
      }
      if gi == 0 {
        sb.write_string(c.myriads[1])
      } else if gi == 1 {
        sb.write_string(c.myriads[0])
      }
    }
    gi += 1
  }
  sb.to_string()
}

///|
/// 逐位数字：n 的每位十进制数字映射到 set。
fn digits_str(n : Int32, set : Array[String]) -> String {
  let sb = StringBuilder()
  for c in n.to_string().to_array() {
    let d = c.to_int() - '0'.to_int()
    if d >= 0 && d <= 9 && d < set.length() {
      sb.write_string(set[d])
    } else {
      sb.write_char(c)
    }
  }
  sb.to_string()
}

///|
/// 一, 二 … 十, 十一 … 九十九；100 起逐位（一〇〇）。
pub fn chinese_counting(n : Int32) -> String {
  if n < 100 {
    counting_format(chinese_sys, n)
  } else {
    digits_str(n, cn_digits)
  }
}

///|
/// 中文计数（含单位）：一百零一, 一千, 一万。
pub fn chinese_counting_thousand(n : Int32) -> String {
  counting_format(chinese_sys, n)
}

///|
/// 简体中文大写（财务）：壹, 贰, 叁 … 壹拾。
pub fn chinese_legal_simplified(n : Int32) -> String {
  counting_format(chinese_legal_sys, n)
}

///|
/// 繁体中文大写：壹, 貳, 參 … 壹拾。
pub fn ideograph_legal_traditional(n : Int32) -> String {
  counting_format(traditional_legal_sys, n)
}

///|
/// 台湾计数：100 下同中文计数，之上逐位。
pub fn taiwanese_counting(n : Int32) -> String {
  if n < 100 {
    counting_format(taiwanese_sys, n)
  } else {
    digits_str(n, cn_digits)
  }
}

///|
/// 台湾计数（含单位）：一百零一, 一千, 一萬。
pub fn taiwanese_counting_thousand(n : Int32) -> String {
  counting_format(taiwanese_sys, n)
}

///|
/// 日文计数：一 … 十, 十一, 百, 千, 一万。
pub fn japanese_counting(n : Int32) -> String {
  counting_format(japanese_sys, n)
}

///|
/// 日文大写：壱, 弐, 参 … 壱拾。
pub fn japanese_legal(n : Int32) -> String {
  counting_format(japanese_legal_sys, n)
}

///|
/// 日文数字 + 万/億组标记：一二, 一万二三四五。
pub fn japanese_digital_ten_thousand(n : Int32) -> String {
  let sb = StringBuilder()
  let mut started = false
  let mut gi = 0
  while gi < 3 {
    let g = if gi == 0 {
      n / 100000000
    } else if gi == 1 {
      n / 10000 % 10000
    } else {
      n % 10000
    }
    let mark = if gi == 0 {
      Some("億")
    } else if gi == 1 {
      Some("万")
    } else {
      None
    }
    let mut skip = false
    if !started {
      skip = match mark {
        Some(_) => g == 0
        None => false
      }
    }
    if !skip {
      let s = digits_str(g, cn_digits)
      if started {
        // 内部组补足四位：一万〇〇〇一
        let mut k = s.to_array().length()
        while k < 4 {
          sb.write_string("〇")
          k += 1
        }
      }
      sb.write_string(s)
      match mark {
        Some(m) => sb.write_string(m)
        None => ()
      }
      started = true
    }
    gi += 1
  }
  sb.to_string()
}

///|
/// 韩文汉字数词：일, 이, 삼 … 십, 십일, 백。
pub fn korean_counting(n : Int32) -> String {
  counting_format(korean_sys, n)
}

///|
/// 韩文逐位数字：일, 일영, 일일。
pub fn korean_digital(n : Int32) -> String {
  digits_str(n, korean_sys.digits)
}

///|
let ko_ones : Array[String] = [
  "", "하나", "둘", "셋", "넷", "다섯", "여섯", "일곱", "여덟", "아홉",
]

///|
let ko_tens : Array[String] = [
  "", "열", "스물", "서른", "마흔", "쉰", "예순", "일흔", "여든", "아흔",
]

///|
/// 韩文固有词数词：하나, 둘 … 열, 열하나 … 아흔아홉；0 或 ≥100 回退十进制。
pub fn korean_legal(n : Int32) -> String {
  if n <= 0 || n > 99 {
    return n.to_string()
  }
  ko_tens[n / 10] + ko_ones[n % 10]
}

///|
/// 逐位汉字数字：一, 一〇, 一〇一。
pub fn ideograph_digital(n : Int32) -> String {
  digits_str(n, cn_digits)
}

///|
/// 序列的第 n 项（1-based），超限回退十进制。
fn nth_str(set : Array[String], n : Int32) -> String {
  if n >= 1 && n - 1 < set.length() {
    set[n - 1]
  } else {
    n.to_string()
  }
}

///|
fn nth_of(set : String, n : Int32) -> String {
  if n <= 0 {
    return n.to_string()
  }
  let chars = set.to_array()
  if n - 1 < chars.length() {
    chars[n - 1].to_string()
  } else {
    n.to_string()
  }
}

///|
/// 码点 first 起连续 count 个圈住 1..=count，超限回退十进制。
fn enclosed(n : Int32, first : Int32, count : Int32) -> String {
  if n >= 1 && n <= count {
    (first + n - 1).unsafe_to_char().to_string()
  } else {
    n.to_string()
  }
}

///|
/// ⒈⒉⒊ … ⒛。
pub fn decimal_enclosed_fullstop(n : Int32) -> String {
  enclosed(n, 0x2488, 20)
}

///|
/// ⑴⑵⑶ … ⒇。
pub fn decimal_enclosed_paren(n : Int32) -> String {
  enclosed(n, 0x2474, 20)
}

///|
/// ㊀㊁㊂ … ㊉（圈汉字）。
pub fn ideograph_enclosed_circle(n : Int32) -> String {
  enclosed(n, 0x3280, 10)
}

///|
/// 全角数字：１, ２ … １０。
pub fn decimal_full_width(n : Int32) -> String {
  let sb = StringBuilder()
  for c in n.to_string().to_array() {
    let d = c.to_int() - '0'.to_int()
    if d >= 0 && d <= 9 {
      sb.write_char((0xFF10 + d).unsafe_to_char())
    } else {
      sb.write_char(c)
    }
  }
  sb.to_string()
}

///|
let stems : Array[String] = [
  "甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸",
]

///|
let branches : Array[String] = [
  "子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥",
]

///|
/// 天干：甲, 乙, 丙 … 癸。
pub fn ideograph_traditional(n : Int32) -> String {
  nth_str(stems, n)
}

///|
/// 地支：子, 丑, 寅 … 亥。
pub fn ideograph_zodiac(n : Int32) -> String {
  nth_str(branches, n)
}

///|
/// 六十甲子：甲子, 乙丑 … 癸亥；范围外回退十进制。
pub fn ideograph_zodiac_traditional(n : Int32) -> String {
  if n < 1 || n > 60 {
    return n.to_string()
  }
  let i = n - 1
  stems[i % 10] + branches[i % 12]
}

///|
let aiueo_fw : String = "アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン"

///|
let aiueo_hw : String = "ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜｦﾝ"

///|
let iroha_fw : String = "イロハニホヘトチリヌルヲワカヨタレソツネナラムウヰノオクヤマケフコエテアサキユメミシヱヒモセス"

///|
let iroha_hw : String = "ｲﾛﾊﾆﾎﾍﾄﾁﾘﾇﾙｦﾜｶﾖﾀﾚｿﾂﾈﾅﾗﾑｳヰﾉｵｸﾔﾏｹﾌｺｴﾃｱｻｷﾕﾒﾐｼヱﾋﾓｾｽ"

///|
let ganada_s : String = "가나다라마바사아자차카타파하"

///|
let chosung_s : String = "ㄱㄴㄷㄹㅁㅂㅅㅇㅈㅊㅋㅌㅍㅎ"

///|
/// 半角片假名五十音：ｱ, ｲ, ｳ …
pub fn aiueo(n : Int32) -> String {
  nth_of(aiueo_hw, n)
}

///|
/// 全角片假名五十音：ア, イ, ウ …
pub fn aiueo_full_width(n : Int32) -> String {
  nth_of(aiueo_fw, n)
}

///|
/// 半角片假名伊吕波：ｲ, ﾛ, ﾊ …
pub fn iroha(n : Int32) -> String {
  nth_of(iroha_hw, n)
}

///|
/// 全角片假名伊吕波：イ, ロ, ハ …
pub fn iroha_full_width(n : Int32) -> String {
  nth_of(iroha_fw, n)
}

///|
/// 谚文音节：가, 나, 다 …
pub fn ganada(n : Int32) -> String {
  nth_of(ganada_s, n)
}

///|
/// 谚文初声：ㄱ, ㄴ, ㄷ …
pub fn chosung(n : Int32) -> String {
  nth_of(chosung_s, n)
}
