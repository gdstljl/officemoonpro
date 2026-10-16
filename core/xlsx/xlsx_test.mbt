///|
/// xlsx 读写测试：往返一致性。

///|
test "xlsx 往返" {
  let wb = @sheet.make_workbook()
  let _ = wb.add_sheet("数据")
  let _ = wb.add_sheet("第二页")
  match wb.get_sheet(0) {
    Some(ws) => {
      ws.set_cell(0, 0, @sheet.CellValue::text("姓名"))
      ws.set_cell(0, 1, @sheet.CellValue::text("分数"))
      ws.set_cell(1, 0, @sheet.CellValue::text("张三"))
      ws.set_cell(1, 1, @sheet.CellValue::number(95.5))
      ws.set_cell(2, 1, @sheet.CellValue::bool(true))
      ws.set_formula(3, 1, "SUM(B1:B3)")
    }
    None => assert_true(false)
  }
  let bytes = @xlsx.write_xlsx(wb)
  assert_true(bytes.length() > 100)
  // ZIP 头
  let arr = bytes.to_array()
  assert_eq(arr[0].to_int(), 0x50)
  assert_eq(arr[1].to_int(), 0x4B)
  match @xlsx.read_xlsx(bytes) {
    Some(wb2) => {
      assert_eq(wb2.sheet_count(), 2)
      assert_eq(wb2.sheet_names(), ["数据", "第二页"])
      match wb2.get_sheet(0) {
        Some(ws) => {
          assert_eq(ws.cell_display(0, 0), "姓名")
          assert_eq(ws.cell_display(0, 1), "分数")
          assert_eq(ws.cell_display(1, 0), "张三")
          assert_eq(ws.cell_display(1, 1), "95.5")
          assert_eq(ws.cell_display(2, 1), "TRUE")
          assert_eq(ws.cell_display(3, 1), "=SUM(B1:B3)")
        }
        None => assert_true(false)
      }
    }
    None => assert_true(false)
  }
}

///|
test "空工作簿 xlsx" {
  let wb = @sheet.make_workbook()
  let _ = wb.add_sheet("空")
  let bytes = @xlsx.write_xlsx(wb)
  match @xlsx.read_xlsx(bytes) {
    Some(wb2) => assert_eq(wb2.sheet_names(), ["空"])
    None => assert_true(false)
  }
}
