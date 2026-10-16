///|
/// 编号格式（ECMA-376 §17.18.59 ST_NumberFormat，全 62 种，对标 Rust wordcraft）。
/// `DecimalEnclosedCircle` / `DecimalEnclosedCircleChinese` 用本工程扩展到 1000
/// 的实现（超出 Word 能力，属既定扩展）；其余渲染语义与 Rust 一致，
/// Rust 不绘制的（希伯来/阿拉伯/印地/泰语等）直接回退十进制。

///|
pub enum NumFormat {
  Decimal
  UpperRoman
  LowerRoman
  UpperLetter
  LowerLetter
  Ordinal
  CardinalText
  OrdinalText
  Hex
  Chicago
  IdeographDigital
  JapaneseCounting
  Aiueo
  Iroha
  DecimalFullWidth
  DecimalHalfWidth
  JapaneseLegal
  JapaneseDigitalTenThousand
  DecimalEnclosedCircle
  DecimalFullWidth2
  AiueoFullWidth
  IrohaFullWidth
  DecimalZero
  Bullet
  Ganada
  Chosung
  DecimalEnclosedFullstop
  DecimalEnclosedParen
  DecimalEnclosedCircleChinese
  IdeographEnclosedCircle
  IdeographTraditional
  IdeographZodiac
  IdeographZodiacTraditional
  TaiwaneseCounting
  IdeographLegalTraditional
  TaiwaneseCountingThousand
  TaiwaneseDigital
  ChineseCounting
  ChineseLegalSimplified
  ChineseCountingThousand
  KoreanDigital
  KoreanCounting
  KoreanLegal
  KoreanDigital2
  VietnameseCounting
  RussianLower
  RussianUpper
  None
  NumberInDash
  Hebrew1
  Hebrew2
  ArabicAlpha
  ArabicAbjad
  HindiVowels
  HindiConsonants
  HindiNumbers
  HindiCounting
  ThaiLetters
  ThaiNumbers
  ThaiCounting
  BahtText
  DollarText
}

///|
/// 跨包构造器（新版 MoonBit 无载荷变体不可跨包直接构造，仿 `Json::null()` 惯例）。
pub fn NumFormat::decimal() -> NumFormat {
  Decimal
}

///|
pub fn NumFormat::upper_roman() -> NumFormat {
  UpperRoman
}

///|
pub fn NumFormat::lower_roman() -> NumFormat {
  LowerRoman
}

///|
pub fn NumFormat::upper_letter() -> NumFormat {
  UpperLetter
}

///|
pub fn NumFormat::lower_letter() -> NumFormat {
  LowerLetter
}

///|
pub fn NumFormat::ordinal() -> NumFormat {
  Ordinal
}

///|
pub fn NumFormat::cardinal_text() -> NumFormat {
  CardinalText
}

///|
pub fn NumFormat::ordinal_text() -> NumFormat {
  OrdinalText
}

///|
pub fn NumFormat::hex() -> NumFormat {
  Hex
}

///|
pub fn NumFormat::chicago() -> NumFormat {
  Chicago
}

///|
pub fn NumFormat::ideograph_digital() -> NumFormat {
  IdeographDigital
}

///|
pub fn NumFormat::japanese_counting() -> NumFormat {
  JapaneseCounting
}

///|
pub fn NumFormat::aiueo() -> NumFormat {
  Aiueo
}

///|
pub fn NumFormat::iroha() -> NumFormat {
  Iroha
}

///|
pub fn NumFormat::decimal_full_width() -> NumFormat {
  DecimalFullWidth
}

///|
pub fn NumFormat::decimal_half_width() -> NumFormat {
  DecimalHalfWidth
}

///|
pub fn NumFormat::japanese_legal() -> NumFormat {
  JapaneseLegal
}

///|
pub fn NumFormat::japanese_digital_ten_thousand() -> NumFormat {
  JapaneseDigitalTenThousand
}

///|
pub fn NumFormat::decimal_enclosed_circle() -> NumFormat {
  DecimalEnclosedCircle
}

///|
pub fn NumFormat::decimal_full_width2() -> NumFormat {
  DecimalFullWidth2
}

///|
pub fn NumFormat::aiueo_full_width() -> NumFormat {
  AiueoFullWidth
}

///|
pub fn NumFormat::iroha_full_width() -> NumFormat {
  IrohaFullWidth
}

///|
pub fn NumFormat::decimal_zero() -> NumFormat {
  DecimalZero
}

///|
pub fn NumFormat::bullet() -> NumFormat {
  Bullet
}

///|
pub fn NumFormat::ganada() -> NumFormat {
  Ganada
}

///|
pub fn NumFormat::chosung() -> NumFormat {
  Chosung
}

///|
pub fn NumFormat::decimal_enclosed_fullstop() -> NumFormat {
  DecimalEnclosedFullstop
}

///|
pub fn NumFormat::decimal_enclosed_paren() -> NumFormat {
  DecimalEnclosedParen
}

///|
pub fn NumFormat::decimal_enclosed_circle_chinese() -> NumFormat {
  DecimalEnclosedCircleChinese
}

///|
pub fn NumFormat::ideograph_enclosed_circle() -> NumFormat {
  IdeographEnclosedCircle
}

///|
pub fn NumFormat::ideograph_traditional() -> NumFormat {
  IdeographTraditional
}

///|
pub fn NumFormat::ideograph_zodiac() -> NumFormat {
  IdeographZodiac
}

///|
pub fn NumFormat::ideograph_zodiac_traditional() -> NumFormat {
  IdeographZodiacTraditional
}

///|
pub fn NumFormat::taiwanese_counting() -> NumFormat {
  TaiwaneseCounting
}

///|
pub fn NumFormat::ideograph_legal_traditional() -> NumFormat {
  IdeographLegalTraditional
}

///|
pub fn NumFormat::taiwanese_counting_thousand() -> NumFormat {
  TaiwaneseCountingThousand
}

///|
pub fn NumFormat::taiwanese_digital() -> NumFormat {
  TaiwaneseDigital
}

///|
pub fn NumFormat::chinese_counting() -> NumFormat {
  ChineseCounting
}

///|
pub fn NumFormat::chinese_legal_simplified() -> NumFormat {
  ChineseLegalSimplified
}

///|
pub fn NumFormat::chinese_counting_thousand() -> NumFormat {
  ChineseCountingThousand
}

///|
pub fn NumFormat::korean_digital() -> NumFormat {
  KoreanDigital
}

///|
pub fn NumFormat::korean_counting() -> NumFormat {
  KoreanCounting
}

///|
pub fn NumFormat::korean_legal() -> NumFormat {
  KoreanLegal
}

///|
pub fn NumFormat::korean_digital2() -> NumFormat {
  KoreanDigital2
}

///|
pub fn NumFormat::vietnamese_counting() -> NumFormat {
  VietnameseCounting
}

///|
pub fn NumFormat::russian_lower() -> NumFormat {
  RussianLower
}

///|
pub fn NumFormat::russian_upper() -> NumFormat {
  RussianUpper
}

///|
pub fn NumFormat::none_() -> NumFormat {
  None
}

///|
pub fn NumFormat::number_in_dash() -> NumFormat {
  NumberInDash
}

///|
pub fn NumFormat::hebrew1() -> NumFormat {
  Hebrew1
}

///|
pub fn NumFormat::hebrew2() -> NumFormat {
  Hebrew2
}

///|
pub fn NumFormat::arabic_alpha() -> NumFormat {
  ArabicAlpha
}

///|
pub fn NumFormat::arabic_abjad() -> NumFormat {
  ArabicAbjad
}

///|
pub fn NumFormat::hindi_vowels() -> NumFormat {
  HindiVowels
}

///|
pub fn NumFormat::hindi_consonants() -> NumFormat {
  HindiConsonants
}

///|
pub fn NumFormat::hindi_numbers() -> NumFormat {
  HindiNumbers
}

///|
pub fn NumFormat::hindi_counting() -> NumFormat {
  HindiCounting
}

///|
pub fn NumFormat::thai_letters() -> NumFormat {
  ThaiLetters
}

///|
pub fn NumFormat::thai_numbers() -> NumFormat {
  ThaiNumbers
}

///|
pub fn NumFormat::thai_counting() -> NumFormat {
  ThaiCounting
}

///|
pub fn NumFormat::baht_text() -> NumFormat {
  BahtText
}

///|
pub fn NumFormat::dollar_text() -> NumFormat {
  DollarText
}

///|
/// 全部 62 种格式（ST_NumberFormat 顺序）。
pub let all_num_formats : Array[NumFormat] = [
  NumFormat::decimal(),
  NumFormat::upper_roman(),
  NumFormat::lower_roman(),
  NumFormat::upper_letter(),
  NumFormat::lower_letter(),
  NumFormat::ordinal(),
  NumFormat::cardinal_text(),
  NumFormat::ordinal_text(),
  NumFormat::hex(),
  NumFormat::chicago(),
  NumFormat::ideograph_digital(),
  NumFormat::japanese_counting(),
  NumFormat::aiueo(),
  NumFormat::iroha(),
  NumFormat::decimal_full_width(),
  NumFormat::decimal_half_width(),
  NumFormat::japanese_legal(),
  NumFormat::japanese_digital_ten_thousand(),
  NumFormat::decimal_enclosed_circle(),
  NumFormat::decimal_full_width2(),
  NumFormat::aiueo_full_width(),
  NumFormat::iroha_full_width(),
  NumFormat::decimal_zero(),
  NumFormat::bullet(),
  NumFormat::ganada(),
  NumFormat::chosung(),
  NumFormat::decimal_enclosed_fullstop(),
  NumFormat::decimal_enclosed_paren(),
  NumFormat::decimal_enclosed_circle_chinese(),
  NumFormat::ideograph_enclosed_circle(),
  NumFormat::ideograph_traditional(),
  NumFormat::ideograph_zodiac(),
  NumFormat::ideograph_zodiac_traditional(),
  NumFormat::taiwanese_counting(),
  NumFormat::ideograph_legal_traditional(),
  NumFormat::taiwanese_counting_thousand(),
  NumFormat::taiwanese_digital(),
  NumFormat::chinese_counting(),
  NumFormat::chinese_legal_simplified(),
  NumFormat::chinese_counting_thousand(),
  NumFormat::korean_digital(),
  NumFormat::korean_counting(),
  NumFormat::korean_legal(),
  NumFormat::korean_digital2(),
  NumFormat::vietnamese_counting(),
  NumFormat::russian_lower(),
  NumFormat::russian_upper(),
  NumFormat::none_(),
  NumFormat::number_in_dash(),
  NumFormat::hebrew1(),
  NumFormat::hebrew2(),
  NumFormat::arabic_alpha(),
  NumFormat::arabic_abjad(),
  NumFormat::hindi_vowels(),
  NumFormat::hindi_consonants(),
  NumFormat::hindi_numbers(),
  NumFormat::hindi_counting(),
  NumFormat::thai_letters(),
  NumFormat::thai_numbers(),
  NumFormat::thai_counting(),
  NumFormat::baht_text(),
  NumFormat::dollar_text(),
]

///|
/// 把序号 n 按格式渲染成文本（对标 Rust `NumFormat::format`）。
pub fn NumFormat::format(self : NumFormat, n : Int32) -> String {
  match self {
    Decimal => n.to_string()
    DecimalZero => decimal_zero(n)
    UpperRoman => roman(n).to_upper()
    LowerRoman => roman(n)
    UpperLetter => letters(n).to_upper()
    LowerLetter => letters(n)
    RussianUpper => russian_letters_upper(n)
    RussianLower => russian_letters(n)
    Ordinal => n.to_string() + ordinal_suffix(n)
    CardinalText => cardinal_text(n)
    OrdinalText => ordinal_text(n)
    Bullet => ""
    None => ""
    Chicago => chicago(n)
    NumberInDash => "- " + n.to_string() + " -"
    DecimalEnclosedCircle => @cjk.circled(n)
    DecimalEnclosedCircleChinese => @cjk.circled(n)
    DecimalEnclosedFullstop => @cjk.decimal_enclosed_fullstop(n)
    DecimalEnclosedParen => @cjk.decimal_enclosed_paren(n)
    DecimalFullWidth => @cjk.decimal_full_width(n)
    DecimalFullWidth2 => @cjk.decimal_full_width(n)
    IdeographDigital => @cjk.ideograph_digital(n)
    TaiwaneseDigital => @cjk.ideograph_digital(n)
    KoreanDigital2 => @cjk.ideograph_digital(n)
    JapaneseCounting => @cjk.japanese_counting(n)
    JapaneseLegal => @cjk.japanese_legal(n)
    JapaneseDigitalTenThousand => @cjk.japanese_digital_ten_thousand(n)
    Aiueo => @cjk.aiueo(n)
    AiueoFullWidth => @cjk.aiueo_full_width(n)
    Iroha => @cjk.iroha(n)
    IrohaFullWidth => @cjk.iroha_full_width(n)
    IdeographEnclosedCircle => @cjk.ideograph_enclosed_circle(n)
    IdeographTraditional => @cjk.ideograph_traditional(n)
    IdeographZodiac => @cjk.ideograph_zodiac(n)
    IdeographZodiacTraditional => @cjk.ideograph_zodiac_traditional(n)
    IdeographLegalTraditional => @cjk.ideograph_legal_traditional(n)
    TaiwaneseCounting => @cjk.taiwanese_counting(n)
    TaiwaneseCountingThousand => @cjk.taiwanese_counting_thousand(n)
    ChineseCounting => @cjk.chinese_counting(n)
    ChineseCountingThousand => @cjk.chinese_counting_thousand(n)
    ChineseLegalSimplified => @cjk.chinese_legal_simplified(n)
    KoreanCounting => @cjk.korean_counting(n)
    KoreanDigital => @cjk.korean_digital(n)
    KoreanLegal => @cjk.korean_legal(n)
    Ganada => @cjk.ganada(n)
    Chosung => @cjk.chosung(n)
    // 以下 Rust 直接回退十进制：
    Hex => n.to_string()
    DecimalHalfWidth => n.to_string()
    VietnameseCounting => n.to_string()
    Hebrew1 => n.to_string()
    Hebrew2 => n.to_string()
    ArabicAlpha => n.to_string()
    ArabicAbjad => n.to_string()
    HindiVowels => n.to_string()
    HindiConsonants => n.to_string()
    HindiNumbers => n.to_string()
    HindiCounting => n.to_string()
    ThaiLetters => n.to_string()
    ThaiNumbers => n.to_string()
    ThaiCounting => n.to_string()
    BahtText => n.to_string()
    DollarText => n.to_string()
  }
}

///|
/// OOXML 格式名（对标 Rust `NumFormat::ooxml`）。
pub fn NumFormat::ooxml(self : NumFormat) -> String {
  match self {
    Decimal => "decimal"
    UpperRoman => "upperRoman"
    LowerRoman => "lowerRoman"
    UpperLetter => "upperLetter"
    LowerLetter => "lowerLetter"
    Ordinal => "ordinal"
    CardinalText => "cardinalText"
    OrdinalText => "ordinalText"
    Hex => "hex"
    Chicago => "chicago"
    IdeographDigital => "ideographDigital"
    JapaneseCounting => "japaneseCounting"
    Aiueo => "aiueo"
    Iroha => "iroha"
    DecimalFullWidth => "decimalFullWidth"
    DecimalHalfWidth => "decimalHalfWidth"
    JapaneseLegal => "japaneseLegal"
    JapaneseDigitalTenThousand => "japaneseDigitalTenThousand"
    DecimalEnclosedCircle => "decimalEnclosedCircle"
    DecimalFullWidth2 => "decimalFullWidth2"
    AiueoFullWidth => "aiueoFullWidth"
    IrohaFullWidth => "irohaFullWidth"
    DecimalZero => "decimalZero"
    Bullet => "bullet"
    Ganada => "ganada"
    Chosung => "chosung"
    DecimalEnclosedFullstop => "decimalEnclosedFullstop"
    DecimalEnclosedParen => "decimalEnclosedParen"
    DecimalEnclosedCircleChinese => "decimalEnclosedCircleChinese"
    IdeographEnclosedCircle => "ideographEnclosedCircle"
    IdeographTraditional => "ideographTraditional"
    IdeographZodiac => "ideographZodiac"
    IdeographZodiacTraditional => "ideographZodiacTraditional"
    TaiwaneseCounting => "taiwaneseCounting"
    IdeographLegalTraditional => "ideographLegalTraditional"
    TaiwaneseCountingThousand => "taiwaneseCountingThousand"
    TaiwaneseDigital => "taiwaneseDigital"
    ChineseCounting => "chineseCounting"
    ChineseLegalSimplified => "chineseLegalSimplified"
    ChineseCountingThousand => "chineseCountingThousand"
    KoreanDigital => "koreanDigital"
    KoreanCounting => "koreanCounting"
    KoreanLegal => "koreanLegal"
    KoreanDigital2 => "koreanDigital2"
    VietnameseCounting => "vietnameseCounting"
    RussianLower => "russianLower"
    RussianUpper => "russianUpper"
    None => "none"
    NumberInDash => "numberInDash"
    Hebrew1 => "hebrew1"
    Hebrew2 => "hebrew2"
    ArabicAlpha => "arabicAlpha"
    ArabicAbjad => "arabicAbjad"
    HindiVowels => "hindiVowels"
    HindiConsonants => "hindiConsonants"
    HindiNumbers => "hindiNumbers"
    HindiCounting => "hindiCounting"
    ThaiLetters => "thaiLetters"
    ThaiNumbers => "thaiNumbers"
    ThaiCounting => "thaiCounting"
    BahtText => "bahtText"
    DollarText => "dollarText"
  }
}

// ---- 西文格式实现（对标 Rust section.rs） ----

///|
/// DecimalZero：至少两位（Rust `{n:02}`）。
fn decimal_zero(n : Int32) -> String {
  let s = n.to_string()
  if s.length() >= 2 {
    s
  } else {
    "0" + s
  }
}

///|
/// 小写罗马数字（0 → 空；>3999 重复 m；上限 50000）。
pub fn roman(n : Int32) -> String {
  let table = [
    (1000, "m"),
    (900, "cm"),
    (500, "d"),
    (400, "cd"),
    (100, "c"),
    (90, "xc"),
    (50, "l"),
    (40, "xl"),
    (10, "x"),
    (9, "ix"),
    (5, "v"),
    (4, "iv"),
    (1, "i"),
  ]
  let mut m = if n > 50000 { 50000 } else { n }
  let sb = StringBuilder()
  for t in table {
    let (v, r) = t
    while m >= v {
      sb.write_string(r)
      m -= v
    }
  }
  sb.to_string()
}

///|
/// Word 风格字母：a..z, aa..zz（重复字母，非 26 进制）；0 → 空，上限 780。
pub fn letters(n : Int32) -> String {
  if n <= 0 {
    return ""
  }
  let nn = if n > 780 { 780 } else { n }
  let k = (nn - 1) / 26 + 1
  let c = ('a'.to_int() + (nn - 1) % 26).unsafe_to_char()
  let sb = StringBuilder()
  let mut i = 0
  while i < k {
    sb.write_char(c)
    i += 1
  }
  sb.to_string()
}

///|
let russian_letters_table : Array[String] = [
  "а", "б", "в", "г", "д", "е", "ж", "з", "и", "к", "л", "м", "н", "о",
  "п", "р", "с", "т", "у", "ф", "х", "ц", "ч", "ш", "щ", "ы", "э", "ю",
  "я",
]

///|
let russian_letters_upper_table : Array[String] = [
  "А", "Б", "В", "Г", "Д", "Е", "Ж", "З", "И", "К", "Л", "М", "Н", "О",
  "П", "Р", "С", "Т", "У", "Ф", "Х", "Ц", "Ч", "Ш", "Щ", "Ы", "Э", "Ю",
  "Я",
]

///|
fn russian_letters_with(table : Array[String], n : Int32) -> String {
  if n <= 0 {
    return ""
  }
  let len = table.length()
  let nn = if n > len * 30 { len * 30 } else { n }
  let k = (nn - 1) / len + 1
  let ch = table[(nn - 1) % len]
  let sb = StringBuilder()
  let mut i = 0
  while i < k {
    sb.write_string(ch)
    i += 1
  }
  sb.to_string()
}

///|
/// Word 风格俄文字母（29 个，不含 ё й ъ ь）：а..я, аа..яя（重复字母）。
pub fn russian_letters(n : Int32) -> String {
  russian_letters_with(russian_letters_table, n)
}

///|
/// 大写俄文字母：А..Я（MoonBit `to_upper` 不处理西里尔字母，单独立表）。
pub fn russian_letters_upper(n : Int32) -> String {
  russian_letters_with(russian_letters_upper_table, n)
}

///|
/// Chicago 风格：*, †, ‡, §，然后加倍（**, †† …，最多 10 重）。
pub fn chicago(n : Int32) -> String {
  if n <= 0 {
    return ""
  }
  let marks = ["*", "†", "‡", "§"]
  let i = n - 1
  let mut k = i / 4 + 1
  if k > 10 {
    k = 10
  }
  let sb = StringBuilder()
  let mut j = 0
  while j < k {
    sb.write_string(marks[i % 4])
    j += 1
  }
  sb.to_string()
}

///|
fn ordinal_suffix(n : Int32) -> String {
  if n % 100 >= 11 && n % 100 <= 13 {
    "th"
  } else if n % 10 == 1 {
    "st"
  } else if n % 10 == 2 {
    "nd"
  } else if n % 10 == 3 {
    "rd"
  } else {
    "th"
  }
}

///|
let ones_en : Array[String] = [
  "zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine",
  "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen",
  "eighteen", "nineteen",
]

///|
let tens_en : Array[String] = [
  "", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety",
]

///|
fn cardinal_words(n : Int32) -> String {
  if n <= 19 {
    ones_en[n]
  } else if n <= 99 {
    let t = tens_en[n / 10]
    if n % 10 == 0 {
      t
    } else {
      t + "-" + ones_en[n % 10]
    }
  } else if n <= 999 {
    let h = cardinal_words(n / 100) + " hundred"
    if n % 100 == 0 {
      h
    } else {
      h + " " + cardinal_words(n % 100)
    }
  } else {
    let th = cardinal_words(n / 1000) + " thousand"
    if n % 1000 == 0 {
      th
    } else {
      th + " " + cardinal_words(n % 1000)
    }
  }
}

///|
fn capitalize(s : String) -> String {
  let sb = StringBuilder()
  let mut up = true
  for c in s.to_array() {
    if up {
      sb.write_char(c.to_ascii_uppercase())
    } else {
      sb.write_char(c)
    }
    up = c == '-' || c == ' '
  }
  sb.to_string()
}

///|
/// 英文基数词，首字母大写（`Twenty-One`），上限 999999。
pub fn cardinal_text(n : Int32) -> String {
  capitalize(cardinal_words(if n > 999999 { 999999 } else { n }))
}

///|
fn lower_first(s : String) -> String {
  s.to_lower()
}

///|
/// 英文序数词（`Twenty-First`）。
pub fn ordinal_text(n : Int32) -> String {
  let c = lower_first(cardinal_text(n))
  let chars = c.to_array()
  // 找最后一个分隔符（- 或空格），拆 head/last
  let mut si = -1
  let mut i = 0
  while i < chars.length() {
    if chars[i] == '-' || chars[i] == ' ' {
      si = i
    }
    i += 1
  }
  let head_sb = StringBuilder()
  let last_sb = StringBuilder()
  i = 0
  while i < chars.length() {
    if i <= si {
      head_sb.write_char(chars[i])
    } else {
      last_sb.write_char(chars[i])
    }
    i += 1
  }
  let last = last_sb.to_string()
  let ord = match last {
    "one" => "first"
    "two" => "second"
    "three" => "third"
    "five" => "fifth"
    "eight" => "eighth"
    "nine" => "ninth"
    "twelve" => "twelfth"
    _ =>
      if last.length() > 1 &&
        last.to_array()[last.to_array().length() - 1] == 'y' {
        let arr = last.to_array()
        let sb = StringBuilder()
        let mut k = 0
        while k < arr.length() - 1 {
          sb.write_char(arr[k])
          k += 1
        }
        sb.write_string("ieth")
        sb.to_string()
      } else {
        last + "th"
      }
  }
  capitalize(head_sb.to_string() + ord)
}

///|
pub enum NoteKind {
  Footnote
  Endnote
}

///|
/// 跨包构造器（新版 MoonBit 无载荷变体不可跨包直接构造）。
pub fn NoteKind::footnote() -> NoteKind {
  Footnote
}

///|
pub fn NoteKind::endnote() -> NoteKind {
  Endnote
}

///|
/// NoteKind 判等（跨包 match 变体受限，集中在这里）。
pub fn note_kind_eq(a : NoteKind, b : NoteKind) -> Bool {
  match (a, b) {
    (Footnote, Footnote) => true
    (Endnote, Endnote) => true
    _ => false
  }
}

///|
pub struct NoteProps {
  num_fmt : NumFormat
  num_start : Int32
}

///|
/// 构造脚注属性（字段保持包内可见，对外走这个构造器）。
pub fn make_note_props(num_fmt~ : NumFormat, num_start~ : Int32) -> NoteProps {
  NoteProps::{ num_fmt, num_start, }
}

///|
/// 按属性的编号格式渲染序号 n（跨包取字段受限，走这个方法）。
pub fn NoteProps::format_mark(self : NoteProps, n : Int32) -> String {
  self.num_fmt.format(n)
}

///|
/// 插入第 n 条脚注/尾注时，正文上标 mark 的文本。
/// 对应 Rust `layout/src/fields.rs` 的 note_mark 接线。
pub fn note_mark(n : Int32, props : NoteProps) -> String {
  props.num_fmt.format(n)
}
