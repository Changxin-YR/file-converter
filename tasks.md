# 任务清单

状态定义：

- `pending`：已登记,尚未开始。
- `in_progress`：正在实施或验证。
- `done`：实现、验证和文档均已完成。
- `blocked`：受外部条件阻塞,已记录原因和下一步。

## 当前任务

### T-20260801-011 ArkTS / ArkUI 语法规范修复

- 状态：`done`
- 目标：以 API 22 完整构建诊断为依据，修正当前工程中的 ArkTS / ArkUI 语法与类型错误。
- 范围：仅修改触发编译失败的工程源码及必要的任务、变更与 QA 记录，不改变产品功能与离线安全边界。

检查项：

- [x] 复现并记录完整 HarmonyOS 构建错误。
- [x] 按 ArkTS / ArkUI 与 API 22 SDK 规范定位根因。
- [x] 最小化修复全部语法与类型错误。
- [x] 通过标准静态检查与 HarmonyOS 构建。
- [x] 回填变更、QA 证据与设备验证状态。

## 当前任务

### T-20260801-001 开发文档重设计与配置对齐 API 22

- 状态：`blocked`
- 目标：重新设计开发文档,聚焦文档/图片/音频格式转换;工程配置对齐 API 22（HarmonyOS 6.0.2）。
- 范围：新建标准文档集与 `docs/开发文档.md`;更新 `AppScope/app.json5` 与 `build-profile.json5` 版本。
- 阻塞原因：文档交付、静态检查与 HarmonyOS 构建已完成,但无可用设备/模拟器执行交互验证。
- 恢复条件：连接设备/模拟器后按 `design-qa.md` 补测。

检查项：

- [x] 审计工程现状与既有开发文档。
- [x] 完成标准文档集（README / AGENTS / tasks / changes / design / design-qa / docs/qa）。
- [x] 完成主开发文档 `docs/开发文档.md`。
- [x] 完成配置对齐 API 22。
- [x] 通过标准静态检查（check_harmonyos_standard.py：22 通过、0 失败、0 警告;check-standard.ps1 通过）。
- [x] 通过 HarmonyOS 构建（API 22 干净构建成功）。
- [ ] 完成与改动风险相称的设备和交互验证（`design-qa.md` 标记 `blocked`）。
- [x] 回填变更、QA 和遗留风险。

## 当前任务

### T-20260801-007 设计文档代码实现

- 状态：`blocked`
- 目标：实现 `docs/开发文档.md` 内容——五个页面 + 三个转换服务 + 引擎抽象层 + 公共模型 + 资源配置。
- 范围：`entry/src/main/ets/` 下 common/engines/services/components/pages 全量代码,`resources/` 颜色/字符串/路由更新。
- 阻塞原因：代码、静态检查与 HarmonyOS 构建已完成,但无可用设备/模拟器执行交互验证。
- 恢复条件：连接设备/模拟器后按 `design-qa.md` 补测。

检查项：

- [x] 公共模型与常量（ConvertTask / FormatTypes / Constants / Utils）。
- [x] 引擎抽象层（IConvertEngine / EngineRegistry / NativeTextEngine）。
- [x] 转换服务（Image / Audio / Document / FilePicker / Save）。
- [x] 复用组件（FormatSelector / ConvertProgressBar / ConvertResultList）。
- [x] 五个页面（Index / Document / Image / Audio / About）。
- [x] 资源与路由（color / string / main_pages）。
- [x] 静态门禁与资源/路由一致性检查。
- [x] 通过 HarmonyOS 构建（API 22 干净构建成功）。
- [ ] 完成设备与交互验证（`blocked`）。
- [x] 回填变更、QA 和遗留风险。

## 当前任务

### T-20260801-010 编译错误修复与文档转换核心实现

- 状态：`done`
- 目标：修复 API 22 编译错误;完整开发文档转换功能（文档转换为主）。
- 范围：AudioConvertService 修正;新增 `common/converters/` 转换核心（DocumentMatrix / TextCodec / CSV / JSON / XML / MD / HTML / TableModel）;重写 NativeTextEngine;升级 DocumentConvertPage（源格式识别、目标动态过滤、源编码选择）;音频能力收敛为 M4A。
- 完成证据：CSV→JSON 与 UTF-16LE→HTML 已在 API 22 phone 模拟器完成真实内容验证，见 `docs/qa/2026-08-01-generated-assets-conversion-test.md`。

检查项：

- [x] 对照 SDK 类型定义修复 AudioConvertService（fdSrc/fdDst 实例属性、AUDIO_MP3、容器枚举）。
- [x] 音频能力收敛（AAC→M4A 原生可靠路径,其余灰置）。
- [x] 文档转换核心（DocumentMatrix + 六个转换器 + TextCodec + TableModel）。
- [x] NativeTextEngine 重写（源/目标编码 + 转换矩阵）。
- [x] DocumentConvertPage 升级（源格式识别、目标动态过滤、源编码选择）。
- [x] 纯逻辑文件通过 DevEco TypeScript 语法检查（21 文件 0 错误）。
- [x] 标准门禁与资源/路由一致性通过。
- [x] API 22 ArkTS 干净编译通过。
- [x] 设备与交互验证。

## 后续任务

### T-20260801-006 构建修复与编译验证

- 状态：`done`
- 目标：补齐 `hvigorw` 与 API 22 SDK,运行构建并按编译结果修正代码。
- 完成证据：构建脚本已适配 DevEco Studio `tools/hvigor/bin` 路径,API 22 干净构建成功并生成 HAP。

### T-20260801-008 设备交互与多设备回归

- 状态：`done`
- 目标：覆盖 phone、tablet、2in1 实际运行分支,验证转换全流程。
- 当前环境：已发现正在运行的 HarmonyOS Emulator,先执行 phone 形态逐功能验证；tablet / 2in1 仍待对应设备。

检查项：

- [x] 确认 HDC 连接、应用安装与启动。
- [x] 验证首页、关于页及全部工具路由。
- [x] 验证无需文件输入的工具功能。
- [ ] 验证文档、图片、音频、视频与 PDF 文件流程。
- [x] 保存设备截图、日志和结果证据至 `docs/qa/`。
- [ ] 回填 phone / tablet / 2in1 覆盖状态。

### T-20260801-009 性能与能力扩展

- 状态：`pending`
- 目标：TaskPool 多线程转换;GIF 编码 / FLAC / WAV / OGG 真机复验;PDF / Office 离线引擎评估（🧩）。

### T-20260801-008 Phone 验证进展（2026-08-01）

- 状态：`in_progress`
- 已完成：模拟器连接、HAP 安装启动、首页/关于页/全部工具路由、单位与时区换算、TXT 文档转换、TXT 生成 PDF、PDF 工具箱 Word转PDF、ZIP 解压。
- 已发现：温度分类切换不自动重算；ZIP 压缩通配后缀导致文件不可见；WAV -> M4A 在 AVTranscoder Prepare 阶段失败。
- 环境阻塞：相册无已索引图片、设备无合法视频样本、无 tablet / 2in1 设备。
- QA 证据：`docs/qa/2026-08-01-phone-functional-test.md`。

### T-20260801-012 Phone 功能缺陷逐项修复

- 状态：`done`
- 目标：依次修复温度分类重算、ZIP 压缩文件筛选和 WAV -> M4A 原生转换，直到 phone 模拟器流程跑通。
- 设计：`docs/superpowers/specs/2026-08-01-functional-flow-repair-design.md`。
- 安全边界：保持单机离线，不新增网络、权限、包名、签名或发布配置变更。

检查项：

- [x] 温度分类切换即时重算并通过设备回归。
- [x] ZIP 压缩可选择普通文件、生成 ZIP 并保存。
- [x] WAV -> M4A 转换和保存成功。
- [x] 静态门禁与完整 HarmonyOS 构建通过。
- [x] 回填 QA 证据、变更记录和设备覆盖状态。

完成证据：`unit-category-recalculate-pass.jpeg`、`zip-compress-pass.jpeg`、`audio-wav-m4a-pass.jpeg`；设备侧 `archive.zip` 为 190 字节，`sample.m4a` 为 12589 字节且包含标准 `ftyp M4A / isom` 文件头。

### T-20260801-013 模拟器生成资产与真实转换矩阵验证

- 状态：`done`
- 目标：生成内容可核验的文档与图片样本，导入 phone 模拟器并逐项执行真实转换，通过输出内容、文件头、尺寸与关键像素确认功能可用。
- 范围：文档与图片转换主流程；发现缺陷时先保留复现证据，再按最小范围修复并回归。

检查项：

- [x] 生成文档、图片测试资产并记录基线属性。
- [x] 将测试资产导入模拟器可访问目录。
- [x] 验证代表性文档转换及输出内容。
- [x] 验证代表性图片格式转换、尺寸调整及输出属性。
- [x] 对失败流程定位根因、修复并重新验证。
- [x] 通过静态门禁、HarmonyOS 构建并回填 QA 证据。

完成证据：`docs/qa/2026-08-01-generated-assets-conversion-test.md`。

### T-20260802-001 全功能模拟器审计与缺陷修复

- 状态：`done`
- 目标：逐项验证首页全部工具及其可用子功能，检查操作状态与真实输出内容；可修复缺陷立即按根因分析和测试先行流程修复，环境或平台能力限制明确记录。
- 范围：文档、图片、视频、音频、图片工具、ZIP 与时区、单位换算、PDF 工具箱、首页与关于页；phone 模拟器为本轮设备基线，tablet / 2in1 按可用环境记录。
- 安全边界：保持单机离线，不新增网络权限，不修改包名、应用 ID、签名身份或发布配置。

检查项：

- [x] 建立完整功能、格式支持与设备覆盖矩阵。
- [x] 通过标准静态检查和 HarmonyOS 完整构建。
- [x] 生成可核验的文档、图片、音频、视频、PDF 与 ZIP 测试资产。
- [x] 在 phone 模拟器逐项审计；可执行项验证输出文件头、内容、尺寸或媒体可读性,系统组件/编解码器阻塞项保留证据。
- [x] 对可复现缺陷完成根因定位、失败测试、最小修复和可行范围设备回归。
- [x] 回填 QA 证据、变更记录、设计 QA 与能力限制。
- [x] 重新执行全量测试、标准门禁和 HarmonyOS 构建后标记完成。

完成证据：`docs/qa/2026-08-02-full-functional-audit.md`。未通过项不是应用内继续可修缺陷：当前模拟器 DocumentViewPicker 浏览异常、缺少 AVC 编码器且无 tablet/2in1 设备；HEIF/GIF/MP3 与复杂 PDF 保持明确不支持。

### T-20260802-002 2in1 阻塞项复测与兼容性回归

- 状态：`done`
- 目标：在新启动的 API 22 2in1 模拟器复测文件选择器、BMP、MP4→M4A、受限 PDF 反向转换和 AVC 视频编码器能力；区分可修应用问题与系统环境限制。
- 安全边界：保持单机离线,不新增权限,不修改包名、应用 ID、签名或发布配置。

检查项：

- [x] 确认 2in1 HDC 目标并安装最新 HAP。
- [x] 验证 2in1 首页、工具路由和响应式布局。
- [x] 复测 DocumentViewPicker “最近/浏览”与合成测试资产输入。
- [x] 复测 BMP、MP4→M4A、PDF→DOC/MD 正常和拒绝路径。
- [x] 复测视频转 MP4 的 AVC 编码器能力。
- [x] 修复可归因于应用的缺陷并执行全量门禁。
- [x] 回填设备证据和不能解决的外部限制。

完成证据：`docs/qa/2026-08-02-2in1-functional-test.md`。2in1 实测解决工具页自动分栏窄侧栏及 H.264/AAC MOV→MP4 编码器阻塞；通用视频转码、复杂 PDF/Office、HEIF/GIF/MP3 和 tablet 独立设备覆盖保留为明确边界。

### T-20260802-003 1.0 上架就绪审计与功能收敛

- 状态：`in_progress`
- 目标：从普通用户与开发者两个角度验证全部已声明能力，修复可归因于应用的问题，使 1.0 达到可提交审核的工程质量；未接入大型离线引擎的格式以禁用的“功能正在开发”占位，不作为 1.0 可用能力宣传。
- 安全边界：保持单机离线、无网络权限、数据不出设备；不修改包名、应用 ID、签名身份或发布状态，不写入任何签名口令或私钥。

检查项：

- [ ] 完成 1.0 能力声明、用户流程和上架配置审计。
- [ ] 修复图标、占位开发者信息、版本文案和误导性能力说明。
- [ ] 增加可重复执行的 release/readiness 静态门禁。
- [ ] 验证全部启用功能的正常、空、失败、取消和保存状态。
- [ ] 执行 phone、2in1 与可用设备的代表性设备回归。
- [ ] 生成 release 模式产物并区分代码问题与外部签名/主体材料阻塞。
- [ ] 回填设计、开发文档、变更记录和上架 QA 报告。

### T-20260802-004 已开发功能回归与禁用状态修复

- 状态：`done`
- 目标：验证当前已启用功能、真实输出和错误状态；修复未支持格式只灰置但没有明确开发状态的问题。
- 范围：自动契约、ArkTS 类型检查、phone/2in1 设备回归、转换产物结构复核和完整 HarmonyOS 构建。

检查项：

- [x] 逐项验证首页与全部已开发页面入口。
- [x] 验证空输入、正常时区、非法分钟和禁用格式状态。
- [x] 复核文档、图片、音视频、PDF 和 ZIP 真实产物。
- [x] 以失败契约复现并修复禁用格式缺少“功能正在开发”的问题。
- [x] 通过全量测试、类型检查、静态门禁和 HarmonyOS 构建。
- [x] 回填 QA、设计、开发文档和变更记录。

完成证据：`docs/qa/2026-08-02-developed-functions-regression.md`。独立 tablet、发布签名和发布者主体材料继续归入 T-20260802-003，不冒充已完成。

### T-20260802-005 参考图全界面 UI 重构

- 状态：`in_progress`
- 目标：以用户提供的八屏参考图为主视觉基准，重做全部 ArkUI 页面；未设计页面沿用同一系统，未开发能力保持布局但灰色禁用。
- 范围：首页、图片、文档、视频、音频、图片工具、档案与时间、单位、PDF、关于及共享状态组件；保持现有离线业务逻辑和真实能力矩阵。

检查项：

- [x] 完成参考图、现有页面和资源差距分析。
- [x] 确认未开发能力采用同布局灰色禁用态。
- [x] 完成 UI 重构设计并获得方案确认。
- [ ] 建立共享视觉令牌、3D 资源和 ArkUI 组件。
- [ ] 按参考图重构八个已设计页面。
- [ ] 按相似风格重构音频、视频、关于及全部状态页。
- [ ] 完成 phone、2in1 截图对照和交互回归。
- [ ] 通过全量测试、类型检查、静态门禁和 HarmonyOS 构建。
- [ ] 回填设计、开发文档、变更记录和 QA 证据。

设计依据：`docs/superpowers/specs/2026-08-02-reference-ui-redesign-design.md`。
