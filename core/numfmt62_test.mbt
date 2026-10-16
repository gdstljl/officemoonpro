///|
/// 62 种 NumFormat 的黑盒测试：渲染向量对标 Rust（section.rs / cjk_numbers.rs），
/// OOXML 名往返保真。

///|
test "西文格式" {
  let f = @core.NumFormat::upper_roman().format(_)
  assert_eq(f(1), "I")
  assert_eq(f(4), "IV")
  assert_eq(f(9), "IX")
  assert_eq(f(44), "XLIV")
  assert_eq(f(2024), "MMXXIV")
  assert_eq(f(0), "")
  assert_eq(@core.NumFormat::lower_roman().format(2024), "mmxxiv")
  let l = @core.NumFormat::lower_letter().format(_)
  assert_eq(l(1), "a")
  assert_eq(l(26), "z")
  assert_eq(l(27), "aa")
  assert_eq(l(28), "bb")
  assert_eq(l(0), "")
  assert_eq(@core.NumFormat::upper_letter().format(27), "AA")
  let o = @core.NumFormat::ordinal().format(_)
  assert_eq(o(1), "1st")
  assert_eq(o(2), "2nd")
  assert_eq(o(3), "3rd")
  assert_eq(o(4), "4th")
  assert_eq(o(11), "11th")
  assert_eq(o(12), "12th")
  assert_eq(o(13), "13th")
  assert_eq(o(21), "21st")
  assert_eq(o(23), "23rd")
  assert_eq(o(111), "111th")
}

///|
test "英文单词格式" {
  let c = @core.NumFormat::cardinal_text().format(_)
  assert_eq(c(0), "Zero")
  assert_eq(c(1), "One")
  assert_eq(c(19), "Nineteen")
  assert_eq(c(21), "Twenty-One")
  assert_eq(c(100), "One Hundred")
  assert_eq(c(101), "One Hundred One")
  let o = @core.NumFormat::ordinal_text().format(_)
  assert_eq(o(1), "First")
  assert_eq(o(2), "Second")
  assert_eq(o(3), "Third")
  assert_eq(o(8), "Eighth")
  assert_eq(o(12), "Twelfth")
  assert_eq(o(20), "Twentieth")
  assert_eq(o(21), "Twenty-First")
}

///|
test "Chicago 与特殊格式" {
  let ch = @core.NumFormat::chicago().format(_)
  assert_eq(ch(1), "*")
  assert_eq(ch(2), "†")
  assert_eq(ch(4), "§")
  assert_eq(ch(5), "**")
  assert_eq(ch(8), "§§")
  assert_eq(ch(9), "***")
  assert_eq(ch(0), "")
  assert_eq(@core.NumFormat::bullet().format(5), "")
  assert_eq(@core.NumFormat::none_().format(5), "")
  assert_eq(@core.NumFormat::number_in_dash().format(5), "- 5 -")
  assert_eq(@core.NumFormat::decimal_zero().format(1), "01")
  assert_eq(@core.NumFormat::russian_lower().format(1), "а")
  assert_eq(@core.NumFormat::russian_lower().format(29), "я")
  assert_eq(@core.NumFormat::russian_lower().format(30), "аа")
  assert_eq(@core.NumFormat::russian_upper().format(1), "А")
  // 回退十进制的
  assert_eq(@core.NumFormat::hex().format(255), "255")
  assert_eq(@core.NumFormat::decimal_half_width().format(7), "7")
  assert_eq(@core.NumFormat::vietnamese_counting().format(7), "7")
  assert_eq(@core.NumFormat::hebrew1().format(7), "7")
  assert_eq(@core.NumFormat::thai_numbers().format(7), "7")
  assert_eq(@core.NumFormat::dollar_text().format(7), "7")
}

///|
test "中文计数系统" {
  let c = @core.NumFormat::chinese_counting().format(_)
  assert_eq(c(1), "一")
  assert_eq(c(10), "十")
  assert_eq(c(11), "十一")
  assert_eq(c(21), "二十一")
  assert_eq(c(99), "九十九")
  assert_eq(c(100), "一〇〇")
  assert_eq(c(101), "一〇一")
  let t = @core.NumFormat::chinese_counting_thousand().format(_)
  assert_eq(t(101), "一百零一")
  assert_eq(t(110), "一百一十")
  assert_eq(t(111), "一百一十一")
  assert_eq(t(1000), "一千")
  assert_eq(t(1010), "一千零一十")
  assert_eq(t(10000), "一万")
  assert_eq(t(10001), "一万零一")
  assert_eq(t(100100), "十万零一百")
  assert_eq(t(100000001), "一亿零一")
  let l = @core.NumFormat::chinese_legal_simplified().format(_)
  assert_eq(l(1), "壹")
  assert_eq(l(3), "叁")
  assert_eq(l(10), "壹拾")
  assert_eq(l(11), "壹拾壹")
  assert_eq(l(101), "壹佰零壹")
  assert_eq(l(1000), "壹仟")
  assert_eq(@core.NumFormat::ideograph_legal_traditional().format(20), "貳拾")
  assert_eq(
    @core.NumFormat::taiwanese_counting_thousand().format(10001),
    "一萬零一",
  )
  assert_eq(@core.NumFormat::ideograph_digital().format(10), "一〇")
  assert_eq(@core.NumFormat::ideograph_digital().format(101), "一〇一")
  assert_eq(@core.NumFormat::taiwanese_digital().format(10), "一〇")
  assert_eq(@core.NumFormat::korean_digital2().format(10), "一〇")
}

///|
test "日韩计数系统" {
  let j = @core.NumFormat::japanese_counting().format(_)
  assert_eq(j(10), "十")
  assert_eq(j(11), "十一")
  assert_eq(j(101), "百一")
  assert_eq(j(1000), "千")
  assert_eq(j(10000), "一万")
  assert_eq(j(10001), "一万一")
  assert_eq(@core.NumFormat::japanese_legal().format(10), "壱拾")
  assert_eq(@core.NumFormat::japanese_legal().format(1000), "壱阡")
  let d = @core.NumFormat::japanese_digital_ten_thousand().format(_)
  assert_eq(d(12), "一二")
  assert_eq(d(10000), "一万〇〇〇〇")
  assert_eq(d(12345), "一万二三四五")
  assert_eq(d(100000000), "一億〇〇〇〇万〇〇〇〇")
  let k = @core.NumFormat::korean_counting().format(_)
  assert_eq(k(11), "십일")
  assert_eq(k(20), "이십")
  assert_eq(k(101), "백일")
  assert_eq(@core.NumFormat::korean_digital().format(10), "일영")
  let kl = @core.NumFormat::korean_legal().format(_)
  assert_eq(kl(1), "하나")
  assert_eq(kl(11), "열하나")
  assert_eq(kl(20), "스물")
  assert_eq(kl(100), "100")
}

///|
test "天干地支与带圈数" {
  assert_eq(@core.NumFormat::ideograph_traditional().format(1), "甲")
  assert_eq(@core.NumFormat::ideograph_traditional().format(10), "癸")
  assert_eq(@core.NumFormat::ideograph_traditional().format(11), "11")
  assert_eq(@core.NumFormat::ideograph_zodiac().format(1), "子")
  assert_eq(@core.NumFormat::ideograph_zodiac().format(12), "亥")
  assert_eq(@core.NumFormat::ideograph_zodiac().format(13), "13")
  assert_eq(@core.NumFormat::ideograph_zodiac_traditional().format(1), "甲子")
  assert_eq(
    @core.NumFormat::ideograph_zodiac_traditional().format(11),
    "甲戌",
  )
  assert_eq(
    @core.NumFormat::ideograph_zodiac_traditional().format(60),
    "癸亥",
  )
  assert_eq(@core.NumFormat::decimal_enclosed_fullstop().format(1), "⒈")
  assert_eq(@core.NumFormat::decimal_enclosed_fullstop().format(20), "⒛")
  assert_eq(@core.NumFormat::decimal_enclosed_fullstop().format(21), "21")
  assert_eq(@core.NumFormat::decimal_enclosed_paren().format(20), "⒇")
  assert_eq(@core.NumFormat::ideograph_enclosed_circle().format(1), "㊀")
  assert_eq(@core.NumFormat::ideograph_enclosed_circle().format(10), "㊉")
  assert_eq(@core.NumFormat::decimal_full_width().format(10), "１０")
  assert_eq(@core.NumFormat::decimal_full_width2().format(10), "１０")
}

///|
test "假名与谚文序列" {
  assert_eq(@core.NumFormat::aiueo_full_width().format(1), "ア")
  assert_eq(@core.NumFormat::aiueo_full_width().format(46), "ン")
  assert_eq(@core.NumFormat::aiueo_full_width().format(47), "47")
  assert_eq(@core.NumFormat::aiueo().format(2), "ｲ")
  assert_eq(@core.NumFormat::iroha_full_width().format(1), "イ")
  assert_eq(@core.NumFormat::iroha_full_width().format(47), "ス")
  assert_eq(@core.NumFormat::iroha().format(3), "ﾊ")
  assert_eq(@core.NumFormat::ganada().format(1), "가")
  assert_eq(@core.NumFormat::ganada().format(14), "하")
  assert_eq(@core.NumFormat::ganada().format(0), "0")
  assert_eq(@core.NumFormat::chosung().format(1), "ㄱ")
  assert_eq(@core.NumFormat::chosung().format(14), "ㅎ")
}

///|
test "62 种格式：数量" {
  assert_eq(@core.all_num_formats.length(), 62)
}
