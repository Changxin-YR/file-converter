# 测试报告合理建议修复实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 修复 PDF 字节输入、文档批量保存、Picker URI 文件状态读取和音频跳过进度问题，同时保留现有离线能力边界。

**Architecture:** PDF 提取器在纯逻辑层接收原始字节；文档页先生成沙箱临时结果，再由 SaveService 一次申请多个目标 URI；视频入口统一使用已打开 fd；音频页显式统计跳过项。所有修改先由 Node 契约或纯逻辑测试复现失败，再实施最小修复。

**Tech Stack:** HarmonyOS API 22、ArkTS/ArkUI、CoreFileKit Picker/FileIo、Node.js 契约测试、Hvigor。

---

### Task 1: 登记任务

**Files:**
- Modify: `tasks.md`

- [ ] **Step 1: 新增任务条目**

登记 `T-20260803-004`，状态为 `in_progress`，范围对应设计文档中的四类修复及文档、QA、构建验证。

- [ ] **Step 2: 检查任务状态格式**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check-standard.ps1`
Expected: `tasks.md` 状态词检查通过。

### Task 2: PDF 原始字节输入

**Files:**
- Modify: `scripts/test-pdf-text-extractor.js`
- Modify: `scripts/test-pdf-capability-contract.js`
- Modify: `entry/src/main/ets/common/converters/PdfTextExtractor.ets`
- Modify: `entry/src/main/ets/pages/PdfToolsPage.ets`

- [ ] **Step 1: 写入失败测试**

将提取器用例改为传入 `ArrayBuffer`，增加 PDF 内容前后含 `0xFF` 的样本；页面契约要求 `PdfTextExtractor.extract(buffer.slice(0, bytesRead))` 且 PDF 路径不调用 `TextCodec.decode`。

- [ ] **Step 2: 验证 RED**

Run: `node scripts/test-pdf-text-extractor.js; node scripts/test-pdf-capability-contract.js`
Expected: FAIL，因为 `extract` 仍只接收字符串且页面仍先 UTF-8 解码。

- [ ] **Step 3: 最小实现**

将 `extract(raw: ArrayBuffer)` 内部通过 `Uint8Array` 逐字节构造保真字符串；页面保留实际读取字节的切片并直接传入提取器。

- [ ] **Step 4: 验证 GREEN**

Run: `node scripts/test-pdf-text-extractor.js; node scripts/test-pdf-capability-contract.js`
Expected: 两个脚本均 PASS。

### Task 3: 文档一次批量保存

**Files:**
- Create: `scripts/test-document-batch-save-contract.js`
- Modify: `entry/src/main/ets/services/SaveService.ets`
- Modify: `entry/src/main/ets/pages/DocumentConvertPage.ets`

- [ ] **Step 1: 写入失败契约**

契约要求 `SaveService.getSavePaths(defaultFileNames: string[])` 一次设置全部 `newFileNames`，页面只调用批量方法，并包含 `cacheDir` 临时结果、返回数量校验和 `finally` 清理。

- [ ] **Step 2: 验证 RED**

Run: `node scripts/test-document-batch-save-contract.js`
Expected: FAIL，因为服务和页面仍逐文件调用 `getSavePath`。

- [ ] **Step 3: 最小实现**

SaveService 增加批量方法并让单文件方法复用它。DocumentConvertPage 增加临时结果类型，先逐个转换到缓存，再一次获取目标 URI、逐个复制，最后统一删除临时文件；单文件转换失败继续处理后续项，保存取消结束整批保存。

- [ ] **Step 4: 验证 GREEN**

Run: `node scripts/test-document-batch-save-contract.js`
Expected: PASS。

### Task 4: 视频 Picker URI 兼容

**Files:**
- Modify: `scripts/test-video-capability-contract.js`
- Modify: `scripts/test-video-remux-contract.js`
- Modify: `scripts/test-video-audio-extract-contract.js`
- Modify: `entry/src/main/ets/pages/VideoConvertPage.ets`
- Modify: `entry/src/main/ets/services/VideoRemuxService.ets`
- Modify: `entry/src/main/ets/services/VideoAudioExtractService.ets`

- [ ] **Step 1: 写入失败契约**

三个契约分别禁止 `statSync(sourceUri)`，并要求使用 `statSync(sourceFile.fd)`。

- [ ] **Step 2: 验证 RED**

Run: `node scripts/test-video-capability-contract.js; node scripts/test-video-remux-contract.js; node scripts/test-video-audio-extract-contract.js`
Expected: FAIL，三个入口当前仍直接 stat Picker URI。

- [ ] **Step 3: 最小实现并验证 GREEN**

将三个 `statSync(sourceUri)` 改为 `statSync(sourceFile.fd)`，保留现有句柄与失败产物清理。重新运行上述三个命令，Expected: PASS。

### Task 5: 音频跳过进度与反馈

**Files:**
- Create: `scripts/test-audio-skip-progress-contract.js`
- Modify: `entry/src/main/ets/pages/AudioConvertPage.ets`

- [ ] **Step 1: 写入失败契约并验证 RED**

契约要求 `skippedCount`、同格式分支内进度更新，以及最终成功/跳过反馈。

Run: `node scripts/test-audio-skip-progress-contract.js`
Expected: FAIL。

- [ ] **Step 2: 最小实现并验证 GREEN**

循环前初始化跳过数；同格式分支递增并更新 `(i + 1) / total`；最终状态在成功时包含跳过数，全部跳过时显示无需转换。重新运行脚本，Expected: PASS。

### Task 6: 文档、QA 与完整验证

**Files:**
- Modify: `design.md`
- Modify: `docs/开发文档.md`
- Modify: `changes.md`
- Modify: `design-qa.md`
- Create: `docs/qa/2026-08-03-test-report-remediation.md`
- Modify: `tasks.md`

- [ ] **Step 1: 更新用户可见行为和开发约束**

记录文档批量保存只弹一次系统对话框、音频跳过反馈、PDF 字节输入和 Picker URI fd 规则。

- [ ] **Step 2: 运行全部自动契约**

Run: `Get-ChildItem .\scripts\test-*.js | ForEach-Object { node $_.FullName; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE } }`
Expected: 全部 PASS。

- [ ] **Step 3: 运行静态门禁与 HarmonyOS 构建**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check-standard.ps1`
Expected: `RESULT: PASSED (0 warning(s))`。

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-harmony.ps1`
Expected: `BUILD SUCCESSFUL`，exit code 0。

- [ ] **Step 4: 记录设备验证状态并完成任务**

检查可用 HDC 端点；若可用，记录操作前状态、动作和操作后状态；若不可用，明确记为 `blocked`。只有代码、自动验证、文档和 QA 均回填后，将 `T-20260803-004` 标记为 `done`。
