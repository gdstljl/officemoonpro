# WordCraft 可执行程序（免编译即用）

下载后直接使用，无需安装 MoonBit 工具链、无需编译。

## macOS 用户

下载 `WordCraft-macOS.dmg`：
1. 双击 DMG 挂载
2. 双击里面的 `WordCraft.html`，在浏览器中直接使用
3. 所有功能离线可用（WASM 已内嵌在单个 HTML 文件中）

一个 App，同时处理 Word 文档和 Excel 表格（WPS 式双模）。

## 方式一：Web 界面（推荐，零安装，全平台）

直接下载 `wordcraft-standalone.html`（单文件，WASM 已内嵌）：
1. 双击用浏览器打开
2. 功能：
   - ① 编号格式探索器：62 种 OOXML 编号格式实时预览
   - ② 带圈数字表：1–50
   - ③ 文档演示：正文 + 上标脚注 + 脚注区
   - ④ 排版演示：断行 → 分页 → 脚注区
   - ⑤ 导出 .docx：浏览器内生成真实 Word 文件并下载

## 方式二：命令行（需 Node.js）

1. 下载 `dist/wordcraft.js` 和 `dist/wordcraft-lib.js`（放在同一目录）
2. 运行：
   ```
   node wordcraft.js demo              # 完整演示
   node wordcraft.js circled 1000      # 打印 circled(1000) → ①⓪⓪⓪
   node wordcraft.js mark 5            # 第 5 个脚注的 mark
   node wordcraft.js dump-sample > s.hex  # 样例 .docx 的 hex
   ```

## 说明

- 全部逻辑由 MoonBit 编译为 WebAssembly / JavaScript，源码在仓库 `core/`、`web/`、`cmd/` 目录。
- 原生（native）可执行文件因当前 MoonBit 工具链链接器问题暂无法构建，待上游修复后补充。
