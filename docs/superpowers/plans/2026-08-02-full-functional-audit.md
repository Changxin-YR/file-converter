# FormatConverter 全功能审计与缺陷修复 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 phone 模拟器中逐项验证 FormatConverter 全部公开功能及真实输出，对可修复缺陷立即修复，并准确记录平台或环境限制。

**Architecture:** 以页面公开能力为入口建立功能矩阵，以可核验输入资产驱动端到端验证，并在设备端生成输出后拉回宿主机检查内容、文件头、尺寸和媒体轨道。缺陷修复保持页面、服务、引擎边界不变，每个生产代码变更先增加能稳定复现问题的契约测试。

**Tech Stack:** HarmonyOS Stage Model、ArkTS / ArkUI、API 22 SDK、Hvigor、HDC / UI Test、PowerShell、Node.js 契约测试。

---

### Task 1: 建立审计基线

**Files:**
- Modify: `tasks.md`
- Create: `docs/qa/2026-08-02-full-functional-audit.md`

- [ ] **Step 1: 从首页和各页面源码列出所有公开入口、格式、禁用状态与期望结果**
- [ ] **Step 2: 运行 `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check-standard.ps1`，期望 `PASSED (0 warning)`**
- [ ] **Step 3: 运行 `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-harmony.ps1`，期望 `BUILD SUCCESSFUL` 并生成 HAP**
- [ ] **Step 4: 用 HDC 确认 `127.0.0.1:5555` 在线，安装并启动 `com.maxtools.formatconverter/EntryAbility`**

### Task 2: 生成并校验离线测试资产

**Files:**
- Create: `docs/qa/generated-testdata/video-sample.mp4`
- Create: `docs/qa/generated-testdata/pdf-source.pdf`
- Modify: `docs/qa/2026-08-02-full-functional-audit.md`

- [ ] **Step 1: 复用现有 CSV、JSON、XML、HTML、MD、TXT、PNG、JPG、BMP 和 WAV 资产并记录哈希、尺寸与内容基线**
- [ ] **Step 2: 检查本机 FFmpeg；可用时离线生成含视频和音频轨的短 MP4，并用 `ffprobe` 保存编解码器与时长基线**
- [ ] **Step 3: 使用项目自身或离线工具生成文本可核验的 PDF 和多文件 ZIP，并记录页数、文本与成员清单**
- [ ] **Step 4: 将资产传入模拟器可访问目录，逐个确认系统文件选择器可见**

### Task 3: 文档转换矩阵

**Files:**
- Test: `scripts/test-document-targets.js`
- Test: `scripts/test-document-read-contract.js`
- Modify if defective: `entry/src/main/ets/common/converters/*`
- Modify if defective: `entry/src/main/ets/engines/NativeTextEngine.ets`
- Modify: `docs/qa/2026-08-02-full-functional-audit.md`

- [ ] **Step 1: 验证 JSON→CSV、XML→JSON、MD→HTML、HTML→TXT、文档→Word 和 UTF-16LE 输入，逐个比对输出内容**
- [ ] **Step 2: 验证相同格式、非法输入、混合批量源文件的目标交集、空状态与错误提示**
- [ ] **Step 3: 若发现缺陷，先在对应 Node 契约测试写最小失败用例并运行确认预期失败**
- [ ] **Step 4: 在转换器或引擎实现最小修复，重跑契约测试、构建并在设备复现路径回归**

### Task 4: 图片转换与图片工具

**Files:**
- Test: `scripts/test-image-picker-contract.js`
- Modify if defective: `entry/src/main/ets/services/ImageConvertService.ets`
- Modify if defective: `entry/src/main/ets/pages/ImageConvertPage.ets`
- Modify if defective: `entry/src/main/ets/pages/ImageToolsPage.ets`
- Modify: `docs/qa/2026-08-02-full-functional-audit.md`

- [ ] **Step 1: 验证 JPG→PNG、PNG→WEBP、PNG→BMP，并检查文件签名、解码尺寸和关键像素**
- [ ] **Step 2: 验证 HEIF 编码能力；不受当前 SDK/模拟器支持时确认界面禁用或给出准确提示**
- [ ] **Step 3: 验证缩放、裁剪和颜色提取，检查实际输出尺寸、裁剪区域像素与颜色值**
- [ ] **Step 4: 验证相同格式选择、取消选择、失败状态和保存结果反馈**
- [ ] **Step 5: 若发现缺陷，先添加失败契约测试，再做最小修复并执行设备回归**

### Task 5: 音频与视频

**Files:**
- Modify if defective: `entry/src/main/ets/services/AudioConvertService.ets`
- Modify if defective: `entry/src/main/ets/services/VideoConvertService.ets`
- Modify if defective: `entry/src/main/ets/pages/AudioConvertPage.ets`
- Modify if defective: `entry/src/main/ets/pages/VideoConvertPage.ets`
- Modify: `docs/qa/2026-08-02-full-functional-audit.md`

- [ ] **Step 1: 回归 WAV→M4A，拉回结果并检查 M4A 文件头、音频轨、时长和可解码性**
- [ ] **Step 2: 检查 AAC、MP3、FLAC、WAV 输出与 OGG 是否准确灰置并给出能力提示**
- [ ] **Step 3: 验证 MP4→MP4，检查输出容器、视频轨、音频轨、分辨率和时长**
- [ ] **Step 4: 验证页面宣称的 MP4→MP3；若原生实现无法产生真实 MP3，定位能力边界并将不可用入口灰置或改为真实支持格式**
- [ ] **Step 5: 任何修复先写失败契约测试，确认失败后最小实现，再执行构建和设备回归**

### Task 6: ZIP、时区和单位换算

**Files:**
- Modify if defective: `entry/src/main/ets/services/ArchiveService.ets`
- Modify if defective: `entry/src/main/ets/pages/ArchiveTimePage.ets`
- Modify if defective: `entry/src/main/ets/pages/UnitConverterPage.ets`
- Modify: `docs/qa/2026-08-02-full-functional-audit.md`

- [ ] **Step 1: 压缩多个文件并验证 ZIP 成员名、数量和内容哈希，随后解压并逐文件比对**
- [ ] **Step 2: 验证无文件、损坏 ZIP、目标重名与取消操作的状态反馈**
- [ ] **Step 3: 验证至少两个方向的时区转换以及无效时间输入**
- [ ] **Step 4: 逐类验证重量、长度、温度、面积和体积公式，并确认分类/单位切换立即重算**
- [ ] **Step 5: 若发现缺陷，先写可运行失败测试，再最小修复和设备回归**

### Task 7: PDF 工具箱

**Files:**
- Modify if defective: `entry/src/main/ets/services/PdfService.ets`
- Modify if defective: `entry/src/main/ets/pages/PdfToolsPage.ets`
- Modify: `docs/qa/2026-08-02-full-functional-audit.md`

- [ ] **Step 1: 验证 JPG→PDF、Word→PDF、HTML→PDF，检查 PDF 文件头、页数、可渲染性与文本/图片内容**
- [ ] **Step 2: 验证 PDF→Word、PDF→MD，检查输出不是仅有文件名或空内容**
- [ ] **Step 3: 使用项目自产 PDF 和外部标准文本 PDF 分别验证，明确轻量解析器的支持边界**
- [ ] **Step 4: 验证不支持或损坏 PDF 的错误提示，不允许界面报告虚假成功**
- [ ] **Step 5: 若发现缺陷，先写失败契约测试，再做最小修复和设备回归**

### Task 8: 全量回归与交付证据

**Files:**
- Modify: `docs/qa/2026-08-02-full-functional-audit.md`
- Modify: `design-qa.md`
- Modify: `changes.md`
- Modify if user-visible behavior changed: `design.md`
- Modify if user-visible behavior changed: `docs/开发文档.md`
- Modify: `tasks.md`

- [ ] **Step 1: 回归首页、关于页、全部工具路由和加载/空/错误/禁用/完成状态**
- [ ] **Step 2: 汇总每项操作前状态、用户动作、操作后状态、输出核验与截图路径**
- [ ] **Step 3: 将结论分为 `正常`、`已修复`、`受环境阻塞`、`当前未实现`，不得以构建成功替代功能验证**
- [ ] **Step 4: 运行全部 Node 契约测试、`check-standard.ps1` 和 `build-harmony.ps1`，记录完整结果**
- [ ] **Step 5: 仅在所有可执行验证和文档回填完成后，将 `T-20260802-001` 标记为 `done`；外部设备缺失项单独标记阻塞**
