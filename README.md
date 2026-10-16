# WordCraft → MoonBit（带圈数字序号：10 → 1000）

Rust 版 WordCraft（`github.com/storytold/wordcraft`）的 MoonBit 移植工程。
本期只交付痛点所在的**编号核心模块**，其余按路线图分批推进。

## 背景

`crates/doc/src/cjk_numbers.rs` 的 `enclosed(n, first, count)` 是表驱动 +
越界回退十进制：`decimalEnclosedCircle` 只到 20，
`decimalEnclosedCircleChinese` 只到 10——第 11 个脚注序号就掉回裸数字。

本工程把带圈序号扩展到 **1000**：

| n        | 输出      | 说明         |
| -------- | --------- | ------------ |
| 1–20     | ①…⑳       | 预组合字形   |
| 21–35    | ㉑…㉟      | 预组合字形   |
| 36–50    | ㊱…㊿      | 预组合字形   |
| 51–1000  | ⑤① / ①⓪⓪⓪ | 逐位组圈     |
| 0 / >1000| `0` / `1001` | 十进制回退 |

上限由 `CIRCLE_MAX` 常量控制，改一处即可调整。

## 结构

```
wordcraft/
├─ moon.mod
├─ core/
│  ├─ cjk/                 # 带圈数字核心
│  │  ├─ circled.mbt       # circled(n) 纯函数 + 字模表
│  │  └─ circled_test.mbt  # 边界值 + 1..=1000 穷举
│  ├─ numfmt.mbt           # NumFormat / NoteKind / NoteProps / note_mark 接线
│  ├─ numfmt_test.mbt
│  ├─ doc/                 # P1: 最小文档模型
│  │  ├─ model.mbt         # Paragraph / Inline / InlineObject::NoteRef / Note / Document
│  │  └─ model_test.mbt
│  ├─ engine/              # P1: References 命令
│  │  ├─ references.mbt    # insert_footnote / insert_endnote（对标 Rust note()）
│  │  └─ references_test.mbt
│  ├─ docx/                # P2: OOXML 片段编解码
│  │  ├─ xml.mbt           # 最小 XML 解析器/生成器
│  │  ├─ numfmt.mbt        # 格式名 ↔ NumFormat（未知回退 decimal）
│  │  ├─ numbering.mbt      # numbering.xml 编解码
│  │  ├─ notes.mbt         # footnotes/endnotes/document.xml/settings 编解码
│  │  └─ *_test.mbt
│  ├─ zip/                 # zip 容器层（纯 MoonBit）
│  │  ├─ crc32.mbt        # CRC-32（IEEE）
│  │  ├─ inflate.mbt      # DEFLATE 解压（RFC 1951，与 Python zlib 交叉验证）
│  │  ├─ zip.mbt          # zip 读（stored/deflated）/ 写（stored）
│  │  └─ *_test.mbt
│  └─ layout/              # P3: 布局子集
│     ├─ metrics.mbt       # 字符宽度（em）/ 上标偏移 / mark 缩放建议
│     └─ layout_test.mbt
├─ cmd/main/main.mbt       # P4: CLI（demo / circled / mark 子命令）
└─ README.md
```

两个 OOXML 变体（`DecimalEnclosedCircle` /
`DecimalEnclosedCircleChinese`）共用同一实现，仅保留两个名字以保
docx 往返保真——读写按格式名存档，与渲染字形解耦。

## 与 Word 的差异（既定）

51 以上连续带圈是**本需求的扩展行为**，超出 Word 能力（Word 越界回退
十进制），不算 parity 回归。

## 构建与测试

需要 MoonBit 工具链（`moon`）：https://www.moonbitlang.com/download

```bash
moon test        # 单元测试（含 1..=1000 穷举）
moon run cmd/main  # CLI 验收：抽查 15 个关键位置
moon info && moon fmt  # 更新接口文件并格式化（按 AGENTS.md）
```

## 移植适配记录（相对原计划 §6 参考实现）

1. `StringBuilder::new()` → `StringBuilder()`，
   `append_string` → `write_string`（`Logger` trait 方法）。
2. 顶层 `const Array[String]` 不允许，字模表改用顶层 `let`。
3. 新版 MoonBit 无载荷枚举变体不可跨包直接构造，
   对外提供 `NumFormat::decimal()` 等构造器（仿标准库 `Json::null()`）。
4. 结构体字面量用 `Type::{ field: value }` 语法。
5. 字符串插值用 `\{expr}`。
6. 穷举测试用 `while` 循环写法（更稳）。

## P1 已交付（2026-10-16）：文档模型 + 插入命令

对照 Rust 源码（`crates/engine/src/cmd/references.rs` 的 `note()`、
`crates/doc/src/para.rs` 的 `Paragraph`/`InlineObject::NoteRef`、
`crates/layout/src/fields.rs` 的 `note_mark`）移植：

- `core/doc`：`Paragraph`（有序 inline 列表，简化 Rust 的
  `text/runs/objects` 三件套）、`InlineObject::NoteRef{kind,id,custom}`、
  `Note`、`Document`（正文段落 + 脚注库）
- `core/engine`：`insert_footnote` / `insert_endnote`，custom mark 按
  Word 规则清洗（去首尾空白、去控制字符、最多 10 字符）
- mark 解析：custom 非空用 custom，否则同 kind 按插入顺序自动编号
  （脚注/尾注独立计数）

## P2 已交付（2026-10-16）：OOXML 片段编解码

对标 Rust `crates/docx`（`read/story.rs`、`write/story.rs`、`read/mod.rs`、
`fixtures.rs` 的 east_asian 用例）：

- `xml.mbt`：最小 XML 解析器/生成器（元素、属性、实体、CDATA、注释/PI 跳过）
- `numfmt.mbt`：格式名 ↔ `NumFormat`；未知名字按 Rust 回退为 `decimal`
- `numbering.mbt`：`numbering.xml` 各级 `w:numFmt` 解析/生成，往返格式名不变
- `notes.mbt`：`footnotes.xml` / `endnotes.xml` 解析/生成（含标准分隔符）、
  `document.xml` 的 `w:footnoteReference`（含 `customMarkFollows` + 后随 `w:t`）
  解析/生成、`settings.xml` 的 `w:footnotePr/w:numFmt` 解析/生成
- `package.mbt`：zip 条目 ↔ `Document` 整包映射（`read_package`/`write_package`，
  含 `[Content_Types].xml` / rels / settings / numbering）
- `core/zip`：纯 MoonBit 的 zip 容器——CRC-32、DEFLATE 解压（RFC 1951，
  与 Python zlib 交叉验证）、zip 读（stored/deflated）/写（stored，Word 可读）

**验证**：`moon run cmd/main -- dump-sample` 输出的样例包经 Python
`zipfile` 校验——CRC 全对、条目齐全、中文 UTF-8 正确；43 个测试全绿，
含"内存文档 → zip 字节 → 解包 → 文档"的端到端往返（脚注文本、custom
mark、编号格式、settings 全部保真）。

## P3 已交付（2026-10-16）：布局子集

回答计划 §9 风险 #1（多圈连排 mark 在上标脚注里的宽度与基线）：

- 带圈字符按全角 1em 计宽：`⑤①` = 2em，`①⓪⓪⓪` = 4em
- 上标基线抬升约定 `SUPERSCRIPT_DY_EM = 0.33`
- `suggest_mark_scale`：mark 超宽时给出等比缩放字号（"单独字号回退"），
  否则 1.0

完整排版引擎（断行、分页、字体回退链）不在本期范围。

## P4 已交付（2026-10-16）：CLI + WASM

- CLI（`cmd/main`）：`demo`（完整演示）、`circled <n>`、`mark <n> [fmt]`、
  `dump-sample`（样例 `.docx` 的 hex，供外部校验）四个子命令（`@env.args()`）
- `moon build --target wasm-gc` 通过，库可编译为 WASM
- UI：明确不在范围——MoonBit 无 egui 等价物，图形界面需另起 Web 前端项目

## 后续路线图

| 阶段 | 内容 | 状态 |
| ---- | ---- | ---- |
| P0 | 编号核心：带圈数字 10→1000 | ✅ 完成 |
| P1 | 文档模型最小集：Paragraph/Run/NoteRef、NoteProps、插入命令 | ✅ 完成 |
| P2 | docx 读写子集：numbering.xml、脚注格式、脚注内容（XML 层；zip 延后） | ✅ 完成 |
| P3 | 布局子集：上标 mark 宽度/基线验证（完整排版引擎不在范围） | ✅ 完成 |
| P4 | CLI 命令面 + WASM 构建（UI 明确不在范围） | ✅ 完成 |

每个阶段独立可测；Rust 侧测试覆盖率高，可直接翻译断言。
