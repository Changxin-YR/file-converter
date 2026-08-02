# 生成资产真实转换测试

## 环境

- 设备：HarmonyOS API 22 phone 模拟器，HDC `127.0.0.1:5555`
- 应用：`com.maxtools.formatconverter/EntryAbility`
- HAP：`entry/build/default/outputs/default/entry-default-unsigned.hap`，3338 KB
- 测试数据：`docs/qa/generated-testdata/`，全部本地生成并经 HDC 导入“下载”目录

## 样本基线

| 样本 | 基线 |
| --- | --- |
| `matrix.csv` | 90 字节；3 行数据；含中文、逗号、转义双引号和空值；SHA-256 `9B730A...1022DE` |
| `plain-utf16le.txt` | 232 字节；UTF-16LE BOM；含中文、数字、HTML 特殊字符和两个段落 |
| `color-grid.png` | PNG，320x200；红/绿/蓝色块；中心 5x5 平均色 `#009A00` |
| `color-grid.jpg` | JPEG，320x200 |
| `color-grid.bmp` | BMP，320x200 |

## 设备操作与结果

| 场景 | 操作前状态 | 用户动作 | 操作后状态 | 结果 | 证据 |
| --- | --- | --- | --- | --- | --- |
| CSV→JSON | `qa-matrix-readfix.csv` 已选 | 选 JSON，转换并保存 | 270 字节 JSON；3 条记录；字段、中文、逗号、引号、空值均正确 | `passed` | `qa-matrix-readfix-converted.json`、`doc-csv-json-readfix-pass.jpeg` |
| UTF-16LE→HTML | 232 字节 UTF-16LE 文本已选 | 选 UTF-16LE 与 HTML，转换并保存 | 187 字节 UTF-8 HTML；中文完整；真实 `<br/>`；源 `<tag>` 安全转义 | `passed` | `qa-plain-utf16le-brfix-converted.html`、`doc-utf16-html-brfix-pass.jpeg` |
| PNG→JPG | 320x200 PNG 已选 | 选 JPG，质量 90，允许保存到相册 | 7447 字节 JFIF；320x200；中心 RGB `(11,238,8)` | `passed` | `qa-color-grid-converted.jpg`、`image-png-jpg-pass.jpeg` |
| 图片缩放 | 320x200 PNG 已选 | 宽度输入 160，关闭保持比例，调整并保存 | PNG 文件头正确；实际尺寸 160x200；中心 RGB `(0,255,0)` | `passed` | `qa-resized-output.png`、`image-resize-pass.jpeg` |
| 颜色选择器 | 同一 PNG 已选 | 提取中心 5x5 平均色 | 应用返回 `#009A00`，与 PC 像素计算一致 | `passed` | `image-color-pick-pass.jpeg` |

## 发现并修复

1. 文档页只显示 PDF/Word/TXT，未暴露底层互转矩阵。新增动态目标解析器与 UTF-8/GBK/UTF-16LE 源编码选择。
2. 系统 picker URI 使用 URI 取大小并忽略 `readSync` 返回值，CSV→JSON 曾错误生成 2 字节 `[]`。改为从已打开 fd 取大小，仅解码实际读取字节；同步修复文档引擎与 PDF 文本入口。
3. TXT→HTML 先插入 `<br/>` 再整体转义，导致字面量 `&lt;br/&gt;`。改为逐行转义后使用真实 `<br/>` 连接。
4. PhotoViewPicker 依赖相册索引，下载目录图片不可选。图片入口改用带图片后缀过滤的 DocumentViewPicker，仍使用系统临时授权 URI。

## 自动化与构建

- `scripts/test-document-targets.js`：通过。
- `scripts/test-document-read-contract.js`：通过。
- `scripts/test-image-picker-contract.js`：通过。
- `scripts/_type_check.js`：`TYPE OK (23 files)`。
- `scripts/check-standard.ps1`：`PASSED (0 warning)`。
- `scripts/build-harmony.ps1`：`BUILD SUCCESSFUL`，最终 HAP 3338 KB。

## 未覆盖

- 本轮未穷举文档和图片矩阵的每一种组合，也未覆盖大文件、批量取消、异常空间不足。
- 视频仍缺少合法样本；tablet / 2in1 无可用设备，保持 `blocked`。
