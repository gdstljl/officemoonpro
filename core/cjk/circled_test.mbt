///|
/// circled 的黑盒测试：只测公开 API 的行为。
/// 边界值对照 `wordcraft-moonbit-plan.md` §3.3 的契约表。

///|
test "带圈数字边界值" {
  assert_eq(@cjk.circled(0), "0")
  assert_eq(@cjk.circled(1), "①")
  assert_eq(@cjk.circled(10), "⑩")
  assert_eq(@cjk.circled(11), "⑪")
  assert_eq(@cjk.circled(20), "⑳")
  assert_eq(@cjk.circled(21), "㉑")
  assert_eq(@cjk.circled(35), "㉟")
  assert_eq(@cjk.circled(36), "㊱")
  assert_eq(@cjk.circled(50), "㊿")
  assert_eq(@cjk.circled(51), "⑤①")
  assert_eq(@cjk.circled(99), "⑨⑨")
  assert_eq(@cjk.circled(100), "①⓪⓪")
  assert_eq(@cjk.circled(101), "①⓪①")
  assert_eq(@cjk.circled(999), "⑨⑨⑨")
  assert_eq(@cjk.circled(1000), "①⓪⓪⓪")
  assert_eq(@cjk.circled(1001), "1001")
}

///|
test "1..=CIRCLE_MAX 每个序号都带圈（无裸十进制回退）" {
  let mut n = 1
  while n <= @cjk.CIRCLE_MAX {
    assert_true(@cjk.circled(n) != n.to_string())
    n += 1
  }
}
