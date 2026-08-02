# 变更记录

## 2026-08-01｜开发文档重设计与配置对齐 API 22

- 状态：`blocked`（文档交付完成;构建与设备验证受外部条件阻塞）
- 用户请求：基于 transform 工程整理并重新设计开发文档,聚焦文档/图片/音频格式转换;版本 API 22、系统 6.0.2;鸿蒙语言设计;遵循标准化与流程化规范;应用为单机离线、无后端。
- 项目类型：独立 HarmonyOS Stage 模型 ArkTS / ArkUI 工程。

### 本次改动

- 新增标准文档集：`README.md`、`AGENTS.md`、`tasks.md`、`changes.md`、`design.md`、`design-qa.md`、`docs/qa/README.md`。
- 新增主开发文档：`docs/开发文档.md`（产品概述、技术架构、能力矩阵、模块设计、页面设计、离线与隐私、开发计划、测试清单等）。
- 配置对齐 API 22：
  - `AppScope/app.json5`：`minAPIVersion` / `targetAPIVersion` 由 12 改为 22。
  - `build-profile.json5`：`compatibleSdkVersion` 由 `5.0.0(12)` 改为 `6.0.2(22)`。
- 未改动源码（`Index.ets` / `EntryAbility.ets` / `module.json5` 保持骨架现状）。

### 设计要点（相对旧文档的调整）

- 能力定位调整：文档转换与图片转换为主,音频为辅助;旧文档中的"图片尺寸调整"并入图片模块作为辅助能力。
- 文档转换范围：明确原生可实现（文本类互转）与三方引擎扩展点（PDF / Office 等重型格式,离线打包）的边界,对应 `docs/开发文档.md` 第五章能力矩阵。
- 版本对齐：API 22 / HarmonyOS 6.0.2。
- 新增"设计红线"：单机离线、无后端、权限最小化、数据不出设备。

### 验证

- 标准检查：通过 `check_harmonyos_standard.py`,**22 项通过、0 失败、0 警告**（`common/components/services/viewmodel` 目录已预置为空骨架,无警告项;`engines` 目录尚未创建）。
- HarmonyOS 构建：`build-harmony.ps1` 实际运行结果为 **BLOCKED**（项目根与 DevEco 安装目录均未找到 `hvigorw` 包装器,本机需安装 API 22 / 6.0.2 SDK 后补齐包装器再构建）。
- 设备与交互：待执行,`design-qa.md` 中如实标记 `blocked`。
- 构建产物：待确认。
- 证据索引：`docs/qa/`。

### 遗留风险

- 工程仍为骨架：`common/components/services/viewmodel` 为空目录,`engines` 目录待创建,均需按 `docs/开发文档.md` 落地代码,在 T-20260801-002 及后续任务中补齐。
- 构建未执行：项目根缺少 `hvigorw.bat` 包装器,且未确认本机 DevEco SDK 是否含 API 22（6.0.2）;安装 SDK 并补齐包装器后需重跑 `build-harmony.ps1`。
- 能力矩阵中 🔶 / 🧩 项（音频封装格式、PDF / Office 引擎）依赖真机验证或三方引擎评估,落地前必须复验。

## 2026-08-01｜实现设计文档代码

- 状态：`blocked`（代码已落地;构建与设备验证受外部条件阻塞）
- 用户请求：实现设计文档内容。
- 项目类型：独立 HarmonyOS Stage 模型 ArkTS / ArkUI 工程。

### 本次改动

新增 ArkTS 源码（`entry/src/main/ets/`）：

- `common/`：`ConvertTask.ets`（状态机/类型/任务/结果模型）、`FormatTypes.ets`（图片/文档/音频格式矩阵）、`Constants.ets`（断点、后缀过滤、音频预设）、`Utils.ets`（路径解析、任务 ID）。
- `engines/`：`IConvertEngine.ets`（转换引擎接口）、`EngineRegistry.ets`（引擎注册表）、`NativeTextEngine.ets`（原生文本引擎）。
- `services/`：`FilePickerService.ets`（PhotoViewPicker / DocumentViewPicker,免授权）、`SaveService.ets`（DocumentSaveOptions 保存位置）、`ImageConvertService.ets`（图片格式互转 + 尺寸调整 + 质量）、`AudioConvertService.ets`（AVTranscoder 转码 + 码率/采样率）、`DocumentConvertService.ets`（引擎注册表分发）。
- `components/`：`FormatSelector.ets`（格式胶囊选择、原生支持灰置）、`ConvertProgressBar.ets`、`ConvertResultList.ets`。
- `pages/`：`Index.ets`（Tab:首页功能卡片 + 关于）、`DocumentConvertPage.ets`、`ImageConvertPage.ets`、`AudioConvertPage.ets`、`AboutPage.ets`（隐私声明）。

资源配置：

- `resources/base/element/color.json`：补充 primary/text_*/chip/border/success/error/card_background 等颜色。
- `resources/base/element/string.json`：补充 tab_home / tab_about。
- `resources/base/profile/main_pages.json`：注册全部五个页面路由。

设计要点（实现取舍）：

- **零权限实现**：全部依赖系统文件选择器（picker）临时授权,`module.json5` 不声明任何权限,符合"权限最小化"红线;转换产物先写应用沙箱,由用户主动"保存到指定位置"。
- **引擎抽象落地**：文本转换经 `EngineRegistry` 分发到 `NativeTextEngine`;图片/音频转换直接由对应 Service 封装原生 Kit,后续可平滑迁移为引擎实现。
- **状态刷新规范**：`@State` 数组使用重新赋值（`this.results = [...this.results, x]`）而非 `push()` 以保证 UI 刷新。
- **TaskPool 未引入**：当前转换在主线程异步执行;TaskPool 多线程优化列为后续性能项（见开发文档第十章）。
- **GIF 编码 / FLAC / WAV / OGG / PDF / Office**：保持能力矩阵标注,UI 中灰置并提示"引擎扩展"。

### 验证

- 标准检查：通过 `check_harmonyos_standard.py`（22 通过、0 失败、0 警告）与 `scripts/check-standard.ps1`。
- 静态一致性检查：全部 `$r('app.color.*')` / `$r('app.string.*')` 引用已在资源中定义;五个页面均已在 `main_pages.json` 注册;`router.pushUrl` 目标与路由一致。
- HarmonyOS 构建：`build-harmony.ps1` 运行结果仍为 **BLOCKED**（缺少 `hvigorw` 包装器与 API 22 SDK）,**代码未经编译验证**。
- 设备与交互：待执行,`design-qa.md` 中如实标记 `blocked`。
- 构建产物：待确认。
- 证据索引：`docs/qa/`。

### 遗留风险

- 代码未编译验证：需本机安装 DevEco Studio API 22（6.0.2）SDK、补齐 `hvigorw` 包装器后运行构建,并按编译错误修正。
- 音频封装格式（WAV/OGG/FLAC 相关路径）与 `CFT_WAV` 等枚举在 API 22 目标机型的支持度需真机验证。
- 图片保存采用 DocumentViewPicker 目标 uri 逐块拷贝,具体机型可用性需真机确认。
- `viewmodel/` 目录未启用;TaskPool 多线程与 PDF/Office 引擎为后续扩展项。

## 2026-08-01｜编译错误修复与文档转换核心实现

- 状态：`in_progress`（待重新编译验证）
- 用户请求：修复 ArkTS 编译错误;完整开发文档转换功能（文档转换为主）。
- 项目类型：独立 HarmonyOS Stage 模型 ArkTS / ArkUI 工程。

### 本次改动

修复编译错误（对照本机 DevEco SDK 类型定义 `@ohos.multimedia.media.d.ts` 实测）：

- `AudioConvertService`：
  - `fdSrc` / `fdDst` 从 `AVTranscoderConfig` 移为 **AVTranscoder 实例属性**（`fdSrc: AVFileDescriptor{fd,offset,length}`、`fdDst: number`）。
  - `media.CodecMimeType.AUDIO_MPEG` → `AUDIO_MP3`。
  - 容器映射修正:`m4a → CFT_MPEG_4A`、`aac → CFT_AAC`、`mp3 → CFT_MP3`、`wav → CFT_WAV`。
- 音频能力收敛：`AVTranscoderConfig` 官方注释**仅支持 AAC 编码 + MP4 容器**,`AUDIO_FORMATS` 仅 M4A 原生可用（AAC/MP3/FLAC/WAV/OGG 灰置）,页面默认目标改为 `m4a`。

新增文档转换核心（`common/converters/`,纯逻辑、单机离线）:

- `DocumentMatrix`：统一转换矩阵与调度——TXT/LOG→{TXT,MD,HTML};CSV/JSON/XML 之间及与 MD/HTML/TXT 互转;MD→HTML/TXT;HTML→TXT/MD。
- `TextCodec`：`util.TextDecoder/TextEncoder` 封装,支持 UTF-8 / UTF-16LE / GBK 等。
- `CsvConverter`（引号/转义解析）、`JsonConverter`（递归对象映射）、`XmlConverter`（递归下降解析器）、`MarkdownConverter`（MD→HTML/TXT）、`HtmlConverter`（HTML→TXT/MD）、`TableModel`（表格中间模型）。
- `NativeTextEngine` 重写：字节读取 → 源编码解码 → DocumentMatrix 转换 → 目标编码写盘。
- `DocumentConvertPage` 升级：源格式识别、目标格式按可转换性动态过滤、源编码选择（UTF-8 / UTF-16LE / GBK）,输出统一 UTF-8。
- `ConvertOptions` 增加 `sourceEncoding` / `targetEncoding`;`DOCUMENT_TEXT_FORMATS` 增加 LOG。

### 验证

- 纯逻辑文件（common/converters、services、engines、common,共 21 个）:通过 DevEco SDK 捆绑 TypeScript `transpileModule` 语法检查,**0 错误**。
- 标准门禁:`check_harmonyos_standard.py` 22 通过 / 0 失败 / 0 警告;`scripts/check-standard.ps1` 通过。
- 资源/路由一致性：`$r()` 引用、路由注册全部匹配。
- ArkTS 编译：用户实测反馈的两个错误已按 SDK 类型定义修复,**待用户重新编译确认**。
- 设备与交互：待执行。

### 遗留风险

- 待用户重新编译确认修复生效;可能仍有未暴露的后续编译错误。
- XML / HTML / MD 转换器为轻量实现,复杂文档结构（深层嵌套、异常转义）可能不完整。
- pages / components 的 ArkUI 语法（struct、组件闭包）无法用标准 TS 检查,依赖实际编译验证。
- 音频仍仅可靠输出 M4A;MP3/AAC 等输出路径需真机验证编码器后转正。

## 2026-08-01｜ArkTS / ArkUI 语法规范修复

- 状态：`done`
- 用户请求：修正 HarmonyOS 语法错误,遵循 ArkTS / ArkUI 与 API 22 规范。

### 本次改动

- `PdfGenerator.ets`：补回标准 PDF 1.4 文件头常量,修复 xref 偏移计算处引用未声明 `header` 的编译错误。
- `ConvertTask.ets`：为已存在的视频转换页面补充 `ConvertType.VIDEO`,修复格式元数据引用不存在枚举成员的类型错误。
- `scripts/build-harmony.ps1`：补充 DevEco Studio `tools/hvigor/bin/hvigorw.bat` 安装路径探测,使项目标准构建命令可在当前 DevEco 版本运行。
- 未修改页面交互、权限、网络能力、包名、应用 ID、签名身份或发布状态。

### 验证

- RED：首次 API 22 构建稳定复现 2 个 ArkTS 编译错误；逐项修复后错误依次消失。
- 静态门禁：`scripts/check-standard.ps1` 通过,0 失败、0 警告。
- 干净构建：先执行 Hvigor `clean`,再运行 `scripts/build-harmony.ps1`,`CompileArkTS`、打包均成功。
- 产物：`entry/build/default/outputs/default/entry-default-unsigned.hap`,695 KB。
- 设备验证：本次无用户可见交互变更,交互验证不适用；既有转换能力真机验证仍为 `blocked`。

### 遗留风险

- 构建仍报告既有 API 弃用与异常处理警告,以及重复 `app_name` 资源警告；均不阻断本次 ArkTS 编译,应另立迁移任务处理。
- 项目未配置签名,本次仅生成 unsigned HAP；按安全规则未修改签名配置。

## 2026-08-01｜Phone 功能逐项检测

- 状态：`in_progress`（phone 主要流程已测，缺陷修复回归与 tablet / 2in1 覆盖未完成）。
- 在 API 22 phone 模拟器安装并启动 `com.maxtools.formatconverter/EntryAbility`。
- 通过首页、关于页、全部工具路由、文档转换、PDF 生成、PDF 工具箱、重量换算、时区换算和 ZIP 解压验证。
- 发现 3 项应用问题：温度分类切换不重算、ZIP 压缩通配后缀过滤无文件、WAV -> M4A Prepare 阶段失败。
- 图片和视频真实转换分别受模拟器 MediaLibrary 未索引图片、缺少合法视频样本阻塞。
- 新增 `docs/qa/2026-08-01-phone-functional-test.md` 及对应设备截图。

## 2026-08-01｜Phone 三项功能缺陷修复

- 状态：`done`
- 单位换算：分类切换后调用 `calculate()`，保留输入并即时更新结果。
- ZIP 压缩：以明确后缀数组替换无效的 `['*']` 过滤；解压模式继续只显示 `.zip`。
- 音频转换：新增 `native_audio` NAPI 模块，解析 16-bit PCM WAV，使用 API 20+ 同步 AudioCodec 编码 AAC LC，并由 AVMuxer 输出 M4A；非 WAV→M4A 组合返回明确的不支持提示。
- 音频参数：采样率控件改为只读“跟随源文件”，避免展示尚未实现的重采样选项。
- 构建配置：接入 CMake、arm64-v8a/x86_64 ABI 和本地类型包；链接 NAPI、AudioCodec、AVMuxer、codecbase 与 media core 库。
- 设备回归：温度 `1 °C = 33.8 °F`；`archive.zip` 190 字节；`sample.m4a` 12589 字节且含标准 `ftyp M4A / isom` 文件头。
- 验证：静态门禁 `PASSED (0 warning)`，完整 HarmonyOS 构建成功，HAP 为 3324.1 KB。

## 2026-08-01｜生成资产真实转换与缺陷修复

- 状态：`done`
- 生成 CSV/JSON/XML/MD/HTML/TXT、UTF-16LE 文本及 320x200 PNG/JPG/BMP 样本并导入 API 22 phone 模拟器。
- 文档页恢复底层 `DocumentMatrix` 已具备的动态互转目标，并提供 UTF-8/GBK/UTF-16LE 源编码选择。
- 修复系统 picker URI 文本读取：从已打开 fd 获取长度并仅解码实际读取字节；同步覆盖文档页、NativeTextEngine 和 PDF 工具文本路径。
- 修复 TXT→HTML 换行被二次转义的问题。
- 图片入口从依赖相册索引的 PhotoViewPicker 改为带图片后缀过滤的 DocumentViewPicker，下载目录图片可直接选择。
- 设备实测通过 CSV→JSON、UTF-16LE→HTML、PNG→JPG、图片缩放和颜色提取；详细内容/文件头/尺寸/像素证据见 `docs/qa/2026-08-01-generated-assets-conversion-test.md`。
- 最终静态门禁 0 warning，完整 HarmonyOS 构建成功，HAP 为 3338 KB。

## 2026-08-02｜全功能审计与离线能力扩展

- 状态：`done`（设备环境限制单列,未宣称全部设备通过）。
- 收敛虚假能力：MP3、HEIF 与复杂 PDF 不再进入执行路径；颜色提取删除未写剪贴板的“复制成功”反馈。
- 新增 `BmpEncoder`：输出 32-bit BI_RGB top-down BMP,RGBA→BGRA。
- 新增 MP4 AAC 音轨→M4A：Native AVSource/AVDemuxer/AVMuxer 无损重封装,不依赖视频编码器。
- 新增受限 PDF 反向转换：仅解析项目自产未压缩 literal/UTF-16BE `Tj` 文本,压缩/加密/对象流/空文本明确失败。
- 验证：新增三组测试先失败后通过；ArkTS 类型检查 26 文件通过；API 22 Native/ArkTS 构建和 HAP 安装成功。
- 设备限制：DocumentViewPicker “浏览”退回桌面且“最近”不索引 HDC 文件；模拟器缺少 AVC 编码器；无 tablet/2in1。详见 `docs/qa/2026-08-02-full-functional-audit.md`。

## 2026-08-02｜2in1 阻塞项复测与兼容修复

- 2in1 `DocumentViewPicker` 可浏览系统分类目录并选择 HDC 导入资产，phone 选择器限制不再阻塞设备闭环。
- PNG→BMP、MP4→M4A、TXT→PDF、PDF→Markdown、PDF→Word 均完成真实选择、转换、保存和产物内容验证。
- 修复 9 个独立页面在 2in1 被 `Navigation` 自动分栏压成窄侧栏的问题，统一使用 `NavigationMode.Stack`。
- 新增 H.264/AAC MOV→MP4 Native 无损重封装，绕开模拟器缺失的 AVC 编码器；2in1 输出含有效视频和音频轨。
- 未解决边界：非 H.264/AAC 视频仍需真正转码；HEIF/GIF/MP3、复杂 PDF/Office 仍需随包离线引擎；tablet 尚无设备证据。
- 证据：`docs/qa/2026-08-02-2in1-functional-test.md`。

## 2026-08-02｜已开发功能全量回归与禁用状态修复

- 新增 `test-disabled-format-status-contract.js`，先复现未支持格式缺少明确文字状态，再完成最小修复。
- 共享 `FormatSelector` 对 `nativeSupported: false` 的格式统一灰置并显示“功能正在开发”，仍阻止选择回调。
- phone/2in1 复测图片、音频、视频禁用状态及空输入按钮；2in1 复测时区正常和非法分钟路径。
- 重新核验 BMP 像素、M4A/MP4 容器轨道、PDF/Word 文件头、Markdown 哈希和 ZIP 内容。
- 自动契约、类型检查、标准门禁和 HarmonyOS 构建通过；证据见 `docs/qa/2026-08-02-developed-functions-regression.md`。
