# Offline Capability Expansion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 增加可真实验证的 BMP 输出、MP4→M4A 音轨提取和受限 PDF→DOC/Markdown 文本转换，同时保持离线、安全和准确能力声明。

**Architecture:** BMP 与 PDF 文本解析放在 `common/converters` 作为纯逻辑模块，服务负责系统文件和 PixelMap，页面只编排交互。MP4 音轨提取使用现有 NAPI 库中的 Native AVSource/AVDemuxer/AVMuxer 无损重封装 AAC 采样，避免依赖当前模拟器缺失的 AVC 编码器。

**Tech Stack:** HarmonyOS API 22、ArkTS、C++17 NAPI、Native Media AVSource/AVDemuxer/AVMuxer、Node.js + DevEco TypeScript、HDC。

---

### Task 1: 实现并验证 BMP 编码器

**Files:**
- Create: `entry/src/main/ets/common/converters/BmpEncoder.ets`
- Create: `scripts/test-bmp-encoder.js`
- Modify: `entry/src/main/ets/services/ImageConvertService.ets`
- Modify: `entry/src/main/ets/common/FormatTypes.ets`
- Modify: `entry/src/main/ets/pages/ImageConvertPage.ets`
- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `scripts/test-image-capability-contract.js`

- [ ] **Step 1: 写 BMP 编码器失败测试**

测试用 DevEco 捆绑的 TypeScript 把 `BmpEncoder.ets` 转为 CommonJS，构造 2×1 RGBA 像素 `[255,0,0,255, 0,255,0,255]`，断言输出长度 62、签名 `BM`、宽 2、高 -1、位深 32，以及像素为 BGRA `[0,0,255,255, 0,255,0,255]`。

Run: `node .\scripts\test-bmp-encoder.js`
Expected: FAIL，原因是 `BmpEncoder.ets` 尚不存在。

- [ ] **Step 2: 实现最小 BMP 编码器**

编码器公开接口：

```typescript
export class BmpEncoder {
  static encode(rgba: ArrayBuffer, width: number, height: number): ArrayBuffer
}
```

实现校验正整数尺寸和 `width * height * 4` 缓冲长度，使用 `DataView` 写 14 字节 BMP 文件头和 40 字节 BITMAPINFOHEADER，采用 32 位 BI_RGB、负高度自上而下排列，并逐像素把 RGBA 转为 BGRA。

- [ ] **Step 3: 运行 BMP 单测并确认通过**

Run: `node .\scripts\test-bmp-encoder.js`
Expected: `BMP ENCODER TESTS PASSED`

- [ ] **Step 4: 在图片服务接入 BMP 分支**

`ImageConvertService` 在尺寸调整后获取 PixelMap 实际尺寸。目标为 `bmp` 时分配 RGBA 缓冲、调用 `readPixelsToBuffer` 和 `BmpEncoder.encode`；PNG/JPG/JPEG/WEBP 继续使用 ImagePacker。只有 ImagePacker 分支创建和释放 packer。

- [ ] **Step 5: 恢复 BMP 能力声明并保留 HEIF 灰置**

`FormatTypes.ets` 和页面本地目标表把 BMP 改为 `nativeSupported: true`，HEIF 保持 `false`；首页描述改为 `PNG/JPG/WEBP/BMP 格式互转`。更新能力契约，要求 BMP 可用、HEIF 不可用。

- [ ] **Step 6: 运行图片相关测试、类型检查和构建**

Run:

```powershell
node .\scripts\test-bmp-encoder.js
node .\scripts\test-image-capability-contract.js
node .\scripts\test-image-picker-contract.js
node .\scripts\_type_check.js
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-harmony.ps1
```

Expected: 全部通过且 HarmonyOS `BUILD SUCCESSFUL`。

- [ ] **Step 7: 在模拟器验证 PNG→BMP**

安装 HAP，选择 `qa-color-grid.png`，转换为 BMP 并允许保存。拉回结果后断言 `BM` 文件头、320×200、32 位，并用 FFmpeg/Pillow 解码和比对四个关键像素。

### Task 2: 实现 MP4→M4A 音轨提取

**Files:**
- Modify: `entry/src/main/cpp/native_audio.cpp`
- Modify: `entry/src/main/cpp/CMakeLists.txt`
- Modify: `entry/src/main/cpp/types/libnative_audio/index.d.ts`
- Create: `entry/src/main/ets/services/VideoAudioExtractService.ets`
- Create: `scripts/test-video-audio-extract-contract.js`
- Modify: `entry/src/main/ets/pages/VideoConvertPage.ets`
- Modify: `scripts/test-video-capability-contract.js`

- [ ] **Step 1: 写音轨提取失败契约**

契约要求 NAPI 导出 `extractMp4AudioToM4a(sourceFd, sourceSize, targetFd)`；CMake 链接 `libnative_media_avsource.so` 和 `libnative_media_avdemuxer.so`；页面提供原生可用 M4A 目标、MP3 仍灰置，执行白名单为 `mp4` 和 `m4a`。

Run: `node .\scripts\test-video-audio-extract-contract.js`
Expected: FAIL，原因是 NAPI 和 M4A 页面路径不存在。

- [ ] **Step 2: 在 Native 层实现 AAC 音轨无损重封装**

Native 工作流：

```cpp
OH_AVSource *source = OH_AVSource_CreateWithFD(sourceFd, 0, sourceSize);
OH_AVDemuxer *demuxer = OH_AVDemuxer_CreateWithSource(source);
// 从 OH_MD_KEY_TRACK_COUNT 遍历轨道，以 OH_MD_KEY_CODEC_MIME 找 audio/mp4a-latm。
OH_AVMuxer *muxer = OH_AVMuxer_Create(targetFd, AV_OUTPUT_FORMAT_M4A);
OH_AVMuxer_AddTrack(muxer, &outputTrack, audioTrackFormat);
OH_AVDemuxer_SelectTrackByID(demuxer, audioTrack);
OH_AVMuxer_Start(muxer);
// 循环 OH_AVDemuxer_ReadSampleBuffer；非 EOS 样本写入 OH_AVMuxer_WriteSampleBuffer。
OH_AVMuxer_Stop(muxer);
```

实现必须拒绝无 AAC 音轨输入，检查全部错误码，失败时 `ftruncate(targetFd, 0)`，并按逆序销毁 AVBuffer、Muxer、Demuxer、Source 和 AVFormat。

- [ ] **Step 3: 增加 NAPI 异步包装和类型声明**

新增三参数 Promise API：

```typescript
export const extractMp4AudioToM4a:
  (sourceFd: number, sourceSize: number, targetFd: number) => Promise<void>
```

复用现有 async work 模式，后台线程执行重封装，完成回调 resolve 或携带 Native 错误 reject。

- [ ] **Step 4: 增加 ArkTS 服务并接入视频页**

`VideoAudioExtractService.extract` 打开源/目标 FD、调用 NAPI、在失败时删除目标。视频页目标增加 `M4A(提取音频)` 且 `nativeSupported: true`，MP3 保持灰置；M4A 路径调用新服务，MP4 路径继续调用 AVTranscoder。首页描述改为 `视频转 MP4 / 提取 M4A`。

- [ ] **Step 5: 运行契约、构建和 Native 链接验证**

Run:

```powershell
node .\scripts\test-video-audio-extract-contract.js
node .\scripts\test-video-capability-contract.js
node .\scripts\_type_check.js
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-harmony.ps1
```

Expected: 全部通过，HAP 中 `libnative_audio.so` 成功链接。

- [ ] **Step 6: 在模拟器验证 MP4→M4A**

选择合成 `video-sample.mp4`，目标 M4A，保存并拉回。用 FFmpeg 检查输出容器为 M4A/MP4，仅含 AAC 音频轨、无视频轨，采样率 44100 Hz，时长约 2 秒；截图保存成功状态。

- [ ] **Step 7: 验证失败路径**

以无音频轨 MP4 测试，期望明确提示“未找到 AAC 音轨”，不生成文件；MOV→MP4 在当前模拟器继续提示设备缺少 MP4 编码器。

### Task 3: 实现受限 PDF 文本提取

**Files:**
- Create: `entry/src/main/ets/common/converters/PdfTextExtractor.ets`
- Create: `scripts/test-pdf-text-extractor.js`
- Modify: `entry/src/main/ets/pages/PdfToolsPage.ets`
- Modify: `scripts/test-pdf-capability-contract.js`

- [ ] **Step 1: 写 PDF 提取器失败单测**

测试将 ArkTS 转译为 CommonJS，覆盖：ASCII literal `Tj`、转义括号/反斜杠、UTF-16BE `<FEFF...> Tj`、多页顺序，以及 `/Filter /FlateDecode` 返回 unsupported。空文本不得返回占位字符串。

Run: `node .\scripts\test-pdf-text-extractor.js`
Expected: FAIL，原因是提取器尚不存在。

- [ ] **Step 2: 实现纯逻辑 PDF 提取器**

公开结果：

```typescript
export interface PdfTextExtractResult {
  success: boolean
  text: string
  errorMsg?: string
}

export class PdfTextExtractor {
  static extract(raw: string): PdfTextExtractResult
}
```

提取器先校验 `%PDF-`，拒绝 `/Encrypt`、`/ObjStm` 和带 `/Filter` 的内容流；按 `BT...ET` 顺序解析 literal 和 hex `Tj`。literal 处理 `\\(`、`\\)`、`\\\\`、`\\n`、`\\r`、`\\t`，hex 仅接受 UTF-16BE BOM。没有文本时返回失败和准确原因。

- [ ] **Step 3: 运行 PDF 单测并确认通过**

Run: `node .\scripts\test-pdf-text-extractor.js`
Expected: `PDF TEXT EXTRACTOR TESTS PASSED`

- [ ] **Step 4: PDF 工具页接入提取器和准确失败处理**

把 PDF→Word、PDF→Markdown 重新设为可用，但描述明确为“项目自产文本 PDF”。`doPdfToText` 调用提取器；失败时抛出错误且不调用保存选择器。DOC 使用 `WordGenerator.generate`，MD 写纯文本。删除页面内旧正则 `extractPdfText`。

- [ ] **Step 5: 运行 PDF 契约、类型检查和构建**

Run:

```powershell
node .\scripts\test-pdf-text-extractor.js
node .\scripts\test-pdf-capability-contract.js
node .\scripts\_type_check.js
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-harmony.ps1
```

Expected: 全部通过且 `BUILD SUCCESSFUL`。

- [ ] **Step 6: 在模拟器验证项目自产 PDF→DOC/MD**

先用文本转 PDF 生成含中英文和转义字符的 PDF，再分别转换为 DOC 和 MD。拉回文件，断言 DOC 含 Word HTML 结构和原文，MD 与原文一致。

- [ ] **Step 7: 验证复杂 PDF 拒绝路径**

选择 ReportLab 生成的 FlateDecode PDF，期望显示“当前仅支持未压缩文本 PDF”，不弹保存成功、不生成空文件。

### Task 4: 文档同步与全量回归

**Files:**
- Modify: `README.md`
- Modify: `design.md`
- Modify: `docs/开发文档.md`
- Modify: `design-qa.md`
- Modify: `changes.md`
- Modify: `tasks.md`
- Modify: `docs/qa/2026-08-02-full-functional-audit.md`

- [ ] **Step 1: 更新产品与开发文档**

准确记录 BMP 输出、MP4→M4A 和受限 PDF 文本提取；BMP/HEIF、MP3、复杂 PDF、视频编码器能力分别说明，不使用“全格式支持”等宽泛措辞。

- [ ] **Step 2: 回填 QA 证据矩阵**

记录每项操作前状态、动作、操作后状态、输出文件校验、截图和日志。保留本轮已经确认的 WEBP、裁剪、视频编码器阻塞和灰置能力证据。

- [ ] **Step 3: 运行所有自动测试**

Run:

```powershell
Get-ChildItem .\scripts\test-*.js | ForEach-Object { node $_.FullName; if ($LASTEXITCODE -ne 0) { throw "Test failed: $($_.Name)" } }
node .\scripts\_type_check.js
```

Expected: 全部测试通过，类型检查 `TYPE OK`。

- [ ] **Step 4: 执行最终项目门禁**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check-standard.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-harmony.ps1
```

Expected: `PASSED (0 warning)` 和 `BUILD SUCCESSFUL`。

- [ ] **Step 5: 最终设备回归**

安装最终 HAP，回归首页、关于页、全部工具路由、BMP、WEBP、裁剪、WAV→M4A、MP4→M4A、PDF 正向与受限反向、ZIP、时区和单位换算。tablet/2in1 无可用设备时明确标为环境阻塞。

- [ ] **Step 6: 完成任务状态**

仅在自动化、构建、phone 模拟器回归和文档回填完成后，将 `T-20260802-001` 标记 `done`；未解决的外部能力单列，不以构建成功代替功能正常结论。
