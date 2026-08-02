# Functional Flow Repair Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 修复温度重算、ZIP 压缩筛选和 WAV→M4A 三项失败流程，并在 API 22 phone 模拟器完成真实回归。

**Architecture:** 页面逻辑缺陷采用最小修改。音频路径新增 `native_audio` NAPI 模块，ArkTS 管理 picker URI 和文件描述符，C++ 解析 PCM WAV、调用同步 AudioCodec 编码 AAC 并通过 AVMuxer 写入 M4A。

**Tech Stack:** HarmonyOS Stage、ArkTS/ArkUI、CoreFileKit、AVCodecKit Native C API、NAPI、CMake、Hvigor、HDC。

---

## 文件结构

- 修改 `entry/src/main/ets/pages/UnitConverterPage.ets`：分类切换后重算。
- 修改 `entry/src/main/ets/pages/ArchiveTimePage.ets`：明确后缀过滤。
- 创建 `entry/src/main/cpp/CMakeLists.txt`：构建 `libnative_audio.so`。
- 创建 `entry/src/main/cpp/native_audio.cpp`：WAV 解析、AAC 编码、M4A 复用和 NAPI Promise。
- 创建 `entry/src/main/cpp/types/libnative_audio/index.d.ts`：ArkTS 类型声明。
- 创建 `entry/src/main/cpp/types/libnative_audio/oh-package.json5`：本地 so 类型包。
- 修改 `entry/build-profile.json5`：启用 CMake 和 x86_64/arm64 ABI。
- 修改 `entry/oh-package.json5`：声明 `libnative_audio.so` 依赖。
- 修改 `entry/src/main/ets/services/AudioConvertService.ets`：WAV→M4A 分派到 native 模块。
- 更新 `tasks.md`、`changes.md`、`design.md`、`docs/开发文档.md`、`design-qa.md` 和 `docs/qa/`：记录行为、边界与证据。

### Task 1: 单位分类切换重算

- [ ] 保留现有设备失败证据：输入 `1` 后从重量切换温度，结果区域消失。
- [ ] 在分类点击回调中把 `this.result = ''` 替换为 `this.calculate()`，继续保留索引重置。
- [ ] 运行 `scripts/check-standard.ps1` 和 `scripts/build-harmony.ps1`。
- [ ] 安装新 HAP，输入 `1` 后切换温度，预期显示 `1 摄氏度 (°C) = 33.8 华氏度 (°F)`。
- [ ] 保存 `docs/qa/unit-category-recalculate-pass.jpeg`。

### Task 2: ZIP 普通文件筛选与压缩

- [ ] 保留现有设备失败证据：压缩模式进入 Download 显示“没有文件”。
- [ ] 为压缩模式定义明确后缀数组，至少包含 `.txt/.log/.csv/.json/.xml/.md/.html/.pdf/.doc/.docx/.xls/.xlsx/.ppt/.pptx/.jpg/.jpeg/.png/.webp/.bmp/.gif/.mp3/.m4a/.aac/.wav/.flac/.ogg/.mp4/.mov/.avi/.mkv/.zip`；解压模式保持 `['.zip']`。
- [ ] 构建、安装，在 Download 选择 `sample.txt`，执行压缩并保存为 `archive.zip`。
- [ ] 通过 HDC 确认 ZIP 文件存在且大小大于 0，保存 `docs/qa/zip-compress-pass.jpeg`。

### Task 3: Native WAV 解析器与模块骨架

- [ ] 在 `native_audio.cpp` 定义 `WavInfo { sampleRate, channels, bitsPerSample, dataOffset, dataSize }`。
- [ ] 实现 RIFF/WAVE chunk 扫描，接受 PCM format=1、16-bit、1/2 声道；其它输入返回具体错误。
- [ ] 导出 `convertWavToM4a(sourceFd, targetFd, bitrate): Promise<void>`，使用 `napi_create_async_work`，在工作线程运行转码。
- [ ] 配置 CMake 链接 `libace_napi.z.so`、`libnative_media_acodec.so`、`libnative_media_avmuxer.so`、`libnative_media_core.so`。
- [ ] 构建验证 native 模块和 ArkTS 类型包可解析。

### Task 4: PCM→AAC→M4A 编码

- [ ] 使用 `OH_AudioCodec_CreateByMime(OH_AVCODEC_MIMETYPE_AUDIO_AAC, true)` 创建同步编码器。
- [ ] 使用 `OH_AVFormat_CreateAudioFormat` 配置采样率、声道数，并设置 `OH_MD_KEY_BITRATE`、`OH_MD_KEY_AUDIO_SAMPLE_FORMAT=SAMPLE_S16LE`、`OH_MD_KEY_MAX_INPUT_SIZE`。
- [ ] 按 Configure→Prepare→Start 顺序启动；通过 `OH_AudioCodec_QueryInputBuffer/GetInputBuffer` 写入 PCM 和 EOS。
- [ ] 处理 `AV_ERR_STREAM_CHANGED`，从 `OH_AudioCodec_GetOutputDescription` 取得 AAC track format，调用 `OH_AVMuxer_AddTrack` 和 `OH_AVMuxer_Start`。
- [ ] 通过 `OH_AudioCodec_QueryOutputBuffer/GetOutputBuffer` 与 `OH_AVMuxer_WriteSampleBuffer` 写出编码帧，遇到 EOS 后停止并释放所有资源。
- [ ] 每一步检查 `OH_AVErrCode`，失败信息包含阶段名和错误码；失败时截断目标文件。

### Task 5: ArkTS 音频服务接入

- [ ] 在 `AudioConvertService.ets` 导入 `libnative_audio.so`。
- [ ] 对 `sourceUri` 打开只读 fd，对 `targetPath` 打开可读写 fd；WAV→M4A 调用 `await nativeAudio.convertWavToM4a(sourceFile.fd, targetFile.fd, bitrate)`。
- [ ] 对非 WAV→M4A 返回明确“不支持的原生音频转换组合”，不再调用视频 `AVTranscoder`。
- [ ] finally 中关闭 fd，失败时删除不完整目标文件。
- [ ] 完整构建、安装，选择 `sample.wav` 转换并保存 `sample.m4a`。
- [ ] 通过 HDC 确认 M4A 大小大于 0，保存 `docs/qa/audio-wav-m4a-pass.jpeg`。

### Task 6: 全量回归与文档

- [ ] 回归 TXT→TXT、TXT→PDF、PDF 工具箱 Word转PDF、ZIP 解压、时区换算。
- [ ] 运行 `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check-standard.ps1`，预期 `PASSED`、0 warning。
- [ ] 运行 `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-harmony.ps1`，预期 `BUILD SUCCESSFUL`。
- [ ] 更新 QA 报告，将三个失败项改为实际验证结果；tablet/2in1 继续如实标记阻塞。
- [ ] 更新任务、变更、设计和开发文档；仅在全部必需验证有新证据后把 T-20260801-012 标为 `done`。

说明：当前目录不是 Git 仓库，计划中的阶段性 commit 不可执行；使用文件级 QA 证据和每项构建结果替代提交检查点。
