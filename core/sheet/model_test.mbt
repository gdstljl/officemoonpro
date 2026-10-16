///|
/// sheet 数据模型测试：A1 地址、单元格读写、工作簿。

///|
test "A1 地址互转" {
  assert_eq(@sheet.rc_to_a1(0, 0), "A1")
  assert_eq(@sheet.rc_to_a1(0, 25), "Z1")
  assert_eq(@sheet.rc_to_a1(0, 26), "AA1")
  assert_eq(@sheet.rc_to_a1(9, 1), "B10")
  assert_eq(@sheet.col_to_letters(0), "A")
  assert_eq(@sheet.col_to_letters(26), "AA")
  assert_eq(@sheet.col_to_letters(27), "AB")
  assert_eq(@sheet.col_to_letters(51), "AZ")
  assert_eq(@sheet.col_to_letters(52), "BA")
  match @sheet.a1_to_rc("A1") {
    Some((r, c)) => {
      assert_eq(r, 0)
      assert_eq(c, 0)
    }
    None => assert_true(false)
  }
  match @sheet.a1_to_rc("AA10") {
    Some((r, c)) => {
      assert_eq(r, 9)
      assert_eq(c, 26)
    }
    None => assert_true(false)
  }
  match @sheet.a1_to_rc("b3") {
    Some((r, c)) => {
      assert_eq(r, 2)
      assert_eq(c, 1)
    }
    None => assert_true(false)
  }
  assert_true((@sheet.a1_to_rc("1A") is None))
  assert_true((@sheet.a1_to_rc("") is None))
  assert_true((@sheet.a1_to_rc("A0") is None))
}

///|
test "单元格读写" {
  let wb = @sheet.make_workbook()
  let si = wb.add_sheet("Sheet1")
  assert_eq(si, 0)
  assert_eq(wb.sheet_count(), 1)
  match wb.get_sheet(0) {
    Some(ws) => {
      ws.set_cell(0, 0, @sheet.CellValue::text("hello"))
      ws.set_cell(0, 1, @sheet.CellValue::number(42.0))
      ws.set_cell(1, 0, @sheet.CellValue::bool(true))
      ws.set_formula(2, 2, "SUM(A1:A10)")
      assert_eq(ws.cell_display(0, 0), "hello")
      assert_eq(ws.cell_display(0, 1), "42")
      assert_eq(ws.cell_display(1, 0), "TRUE")
      assert_eq(ws.cell_display(2, 2), "=SUM(A1:A10)")
      assert_eq(ws.cell_display(5, 5), "")
      match ws.get_cell(0, 0) {
        Some(c) => assert_eq(c.get_value().display(), "hello")
        None => assert_true(false)
      }
      assert_true((ws.get_cell(9, 9) is None))
      match ws.used_range() {
        Some((min_r, min_c, max_r, max_c)) => {
          assert_eq(min_r, 0)
          assert_eq(min_c, 0)
          assert_eq(max_r, 2)
          assert_eq(max_c, 2)
        }
        None => assert_true(false)
      }
    }
    None => assert_true(false)
  }
  assert_eq(wb.sheet_names(), ["Sheet1"])
}

///|
test "空表 used_range" {
  let wb = @sheet.make_workbook()
  let _ = wb.add_sheet("空")
  match wb.get_sheet(0) {
    Some(ws) => assert_true((ws.used_range() is None))
    None => assert_true(false)
  }
}
