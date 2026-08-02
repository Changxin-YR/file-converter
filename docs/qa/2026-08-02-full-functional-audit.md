# 2026-08-02 全功能审计与能力扩展

## 环境

- 工程：HarmonyOS Stage / ArkTS / API 22
- 设备：phone 模拟器 `127.0.0.1:5555`,1320x2856
- 应用：`com.maxtools.formatconverter/EntryAbility`
- 产物：`entry/build/default/outputs/default/entry-default-unsigned.hap`
- 安全：未增加网络或其他权限；未修改包名、应用 ID、签名或发布配置

## 功能矩阵

| 模块 | 操作前状态 | 动作 | 操作后与输出验证 | 结论 |
| --- | --- | --- | --- | --- |
| 首页/关于/路由 | 最新 HAP 未安装 | 安装并启动,逐项打开 8 个工具 | 首页与工具页可见；隐私声明保持单机离线 | passed |
| 文档互转 | 合成 CSV/TXT/UTF-16LE 等样本 | CSV→JSON、UTF-16LE→HTML 等 | 内容、编码和转义已校验 | passed（沿用 2026-08-01 设备证据） |
| 图片 PNG→WEBP | 320x200 合成色块 PNG | 选择 WEBP 并保存 | 输出可解码,320x200 | passed |
| 图片 PNG→BMP | 同一合成 PNG | 目标选择 BMP | 项目内编码器的文件头、尺寸、32-bit BGRA 单测通过；系统 picker 阻断本轮设备输入 | automated passed / device blocked |
| 图片 HEIF | 目标曾显示可用 | 真实转换复现失败后收敛能力 | HEIF 目标灰置,不进入执行路径 | fixed |
| 图片缩放/裁剪 | 320x200 PNG | 缩放、裁剪 100x80 并保存 | 输出尺寸和关键像素正确 | passed |
| 颜色提取 | 中央绿色区域 | 提取中央区域平均色 | 显示 `#009A00`;移除虚假“已复制”反馈 | passed / fixed |
| PCM WAV→M4A | 16-bit PCM WAV | 选择 M4A 并保存 | 标准 M4A 文件头,12589 字节 | passed（既有设备证据） |
| MP4→M4A | H.264+AAC 2 秒合成 MP4 | Native 无损音轨重封装 | 2in1 选择、保存通过；25308 字节，含 `mp4a/soun` 且无视频 handler | passed |
| MOV→MP4 | H.264+AAC MOV | Native 无损重封装 | 2in1 选择、保存通过；36854 字节，含 `avc1/mp4a` 和 `vide/soun` | fixed / passed |
| MP3 输出 | 原页面曾把 AAC/MP4 伪装为 `.mp3` | 收敛能力 | MP3 灰置且不进入执行白名单 | fixed |
| JPG/文本/HTML→PDF | 合成输入 | 生成并保存 PDF | 文本 PDF 正向路径既有设备通过；JPG 路径本轮受 picker 阻断 | partial passed |
| 项目文本 PDF→DOC/MD | 未压缩 literal/UTF-16BE `Tj` PDF | 严格提取并导出 | 2in1 MD 与源 TXT 字节一致；DOC 含 Office 结构及完整源文本 | passed |
| 复杂 PDF | FlateDecode/Encrypt/ObjStm/空文本 | 尝试提取 | 在保存前明确拒绝,不生成空文件 | passed（自动失败路径） |
| ZIP/时区/单位 | 合成文本和固定数值 | 压缩解压、时区、温度切换 | ZIP 文件有效；`1 °C = 33.8 °F` | passed（既有设备证据） |

## 本轮修复与新增

- 修复视频伪 MP3：AAC+MP4 不再以 `.mp3` 名称保存。
- 修复 PDF 伪能力：二进制 DOC/DOCX 不再按 UTF-8 读取；复杂 PDF 不再生成占位或空文件。
- 修复颜色提取伪复制：删除未写剪贴板却提示成功的交互。
- 新增 32-bit BI_RGB BMP 编码器,RGBA 转 BGRA,负高度 top-down。
- 新增 MP4 内 AAC 音轨到 M4A 的 Native 无损重封装。
- 新增项目自产未压缩文本 PDF 到 DOC/Markdown 的受限转换。
- 新增 H.264/AAC MOV 到 MP4 的 Native 无损重封装，绕开缺失的 AVC 编码器。
- 修复独立工具页在 2in1 自动分栏后被压成窄侧栏的问题。

## 设备证据

- `docs/qa/video-m4a-capability.jpeg`：M4A 可用、MP3 灰置和准确能力说明。
- `docs/qa/video-m4a-ui.jpeg`、`docs/qa/layout-video-picker2.json`：系统选择器显示“没有文件”。
- `docs/qa/layout-final-home.json`：最新首页能力文案和全部入口。
- `docs/qa/qa-color-grid-output.webp`：真实 PNG→WEBP 输出。
- `docs/qa/image-crop-pass.jpeg`、`docs/qa/layout-crop-pass.json`：裁剪设备通过。
- `docs/qa/video-mov-convert-hilog.txt`：模拟器 AVC 编码器缺失日志。
- `docs/qa/pdf-capability-fixed.jpeg`、`docs/qa/pdf-disabled-toast.jpeg`：PDF 能力收敛前一阶段证据。
- `docs/qa/2026-08-02-2in1-functional-test.md`：2in1 文件选择、转换、保存、布局和产物验证。

## 未解决与环境限制

1. phone 模拟器的 DocumentViewPicker 浏览行为异常；2in1 文件管理器可浏览分类目录，已完成此前阻塞的设备闭环。
2. 当前模拟器仍缺少 AVC 编码器；H.264/AAC MOV 已通过无损重封装解决，其他编码或容器的通用视频转码仍需随包离线引擎。
3. HEIF、GIF、MP3 输出未实现并保持灰置。
4. 复杂 PDF、扫描 PDF、Office 二进制双向转换仍需随包离线引擎,当前明确拒绝。
5. 已覆盖 phone 与 2in1；尚无独立 tablet 设备证据。

## 自动验证

- `scripts/test-bmp-encoder.js`
- `scripts/test-video-audio-extract-contract.js`
- `scripts/test-pdf-text-extractor.js`
- 全部 `scripts/test-*.js`
- `scripts/_type_check.js`
- `scripts/check-standard.ps1`
- `scripts/build-harmony.ps1`

最终结果以本报告末次回归记录和命令输出为准；构建成功不替代设备功能结论。
