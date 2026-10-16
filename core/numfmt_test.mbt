///|
/// NumFormat 接线的黑盒测试。

///|
test "两种 EnclosedCircle 变体输出一致" {
  let mut n = 0
  while n <= 1001 {
    assert_eq(
      @core.NumFormat::decimal_enclosed_circle().format(n),
      @core.NumFormat::decimal_enclosed_circle_chinese().format(n),
    )
    n += 1
  }
}

///|
test "note_mark 走编号格式" {
  let props = @core.make_note_props(
    num_fmt=@core.NumFormat::decimal_enclosed_circle(),
    num_start=1,
  )
  assert_eq(@core.note_mark(1, props), "①")
  assert_eq(@core.note_mark(21, props), "㉑")
  assert_eq(@core.note_mark(1000, props), "①⓪⓪⓪")
}

///|
test "Decimal 与 DecimalZero 占位行为" {
  assert_eq(@core.NumFormat::decimal().format(7), "7")
  assert_eq(@core.NumFormat::decimal_zero().format(7), "07")
  assert_eq(@core.NumFormat::decimal_zero().format(42), "42")
}
