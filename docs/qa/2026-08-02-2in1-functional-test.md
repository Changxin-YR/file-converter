# 2026-08-02 2in1 功能复测

## 环境

- 设备：API 22 2in1 模拟器 `127.0.0.1:5557`，3120x2080
- 应用：`com.maxtools.formatconverter/EntryAbility`
- 输入：项目生成的 PNG、H.264/AAC MP4/MOV、TXT 与项目自产文本 PDF
- 安全：全程离线，未增加权限，未修改包名、应用 ID、签名或发布配置

## 结果

| 功能 | 操作前 | 动作 | 操作后 | 结论 |
| --- | --- | --- | --- | --- |
| 首页与路由 | 最新 HAP 未安装 | 安装并启动，检查 8 个入口 | 入口完整，无文字重叠 | passed |
| 2in1 工具页布局 | 工具内容被 `Navigation` 自动分栏压到约 456 px | 9 个独立页面固定 `NavigationMode.Stack` | 图片页内容横向范围 `[545,2575]`，无右侧空白分栏 | fixed / passed |
| DocumentViewPicker | phone 的“浏览”入口曾退桌面 | 在 2in1 打开文档、视频分类并切换后缀 | 可选择 HDC 导入的分类目录文件 | passed |
| PNG→BMP | `color-grid.png` 320x200 | 转 BMP 并授权保存到相册 | 256054 字节，`BM`，32-bit，解码后 RGBA 与源像素完全一致 | passed |
| MP4→M4A | H.264/AAC `video-sample.mp4` | 提取音轨并保存 | 25308 字节，含 `ftyp/M4A/mp4a/soun`，无视频 handler | passed |
| TXT→PDF | UTF-8 `plain.txt` | 生成并保存 PDF | 1212 字节项目自产文本 PDF | passed |
| PDF→Markdown | 上一步 PDF | 提取并保存 `plain.md` | 143 字节，与源 TXT 字节及 SHA-256 完全一致 | passed |
| PDF→Word | 同一 PDF | 提取并保存 `plain.doc` | 1025 字节，含 HTML、Office 命名空间、中文、数字与特殊字符 | passed |
| MOV→MP4 | H.264/AAC `video-sample.mov`；系统无 AVC 编码器 | Native 无损重封装并保存 | 36854 字节，含 `ftyp/moov/mdat`、`avc1/mp4a`、`vide/soun` | fixed / passed |

## 关键证据

- `docs/qa/2in1-stack-image.jpeg`、`layout-2in1-stack-image.json`：2in1 全宽 Stack 布局。
- `docs/qa/2in1-bmp-pass.jpeg`、`2in1-color-grid-output.bmp`：BMP 设备闭环与产物。
- `docs/qa/2in1-m4a-pass.jpeg`、`2in1-video-sample-output.m4a`：M4A 设备闭环与产物。
- `docs/qa/2in1-plain-output.md`、`2in1-plain-output.doc`：PDF 反向转换产物。
- `docs/qa/2in1-remux-pass.jpeg`、`2in1-video-sample-remux-output.mp4`：MOV 无损重封装设备闭环与产物。

## 仍受限的能力

1. MOV 无损重封装仅支持 H.264 视频轨和可选 AAC 音轨；其他轨道编码会明确失败。
2. AVI、MKV、FLV、WMV 以及非 H.264/AAC 视频转 MP4 需要真正解码和编码。当前模拟器缺少 AVC 编码器；要通用支持需引入随 HAP 打包的离线编解码引擎，会增加包体和 Native 维护成本。
3. HEIF、GIF、MP3 输出仍灰置；复杂、扫描、加密 PDF 与二进制 Office 双向转换仍需随包离线引擎。
4. 本轮有 phone 和 2in1 证据，尚无独立 tablet 设备证据。
