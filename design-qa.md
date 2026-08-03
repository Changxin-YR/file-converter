# 设计与交互 QA

状态仅使用 `passed`、`blocked` 或明确失败描述。

## 2026-08-01｜文档重设计（未运行设备验证）

### 运行环境

- 设备/模拟器：无（未连接设备或模拟器）。
- 系统版本：目标 HarmonyOS 6.0.2（API 22）,未实机验证。
- 包名与 Ability：`com.example.formatconverter` / `EntryAbility`。
- 构建产物：无（构建未执行,需本机 API 22 SDK）。

### 检查结果

| 场景 | 操作前状态 | 用户动作 | 操作后状态 | 结果 | 证据 |
| --- | --- | --- | --- | --- | --- |
| 首屏 | 未运行 | 启动应用 | 未观察 | `blocked` | 无设备证据 |
| 文档转换 | 未运行 | 选择文件并转换 | 未观察 | `blocked` | 代码已落地,未编译验证 |
| 图片转换 | 未运行 | 选择图片并转换 | 未观察 | `blocked` | 代码已落地,未编译验证 |
| 音频转换 | 未运行 | 选择音频并转换 | 未观察 | `blocked` | 代码已落地,未编译验证 |

> 本次涉及 T-20260801-001（文档）与 T-20260801-007（代码实现）两个任务;运行与交互验证尚未执行,如实标记 `blocked`,不把设计目标写成已完成。

### 多设备覆盖

| 设备类型 | 状态 | 说明 |
| --- | --- | --- |
| phone | `blocked` | 待设备验证 |
| tablet | `blocked` | 待设备验证 |
| 2in1 | `blocked` | 待设备验证 |

### 静态检查结论（文档转换核心实现后复测）

- `check_harmonyos_standard.py`：通过,22 项通过、0 失败、0 警告。
- `scripts/check-standard.ps1`：通过,0 警告。
- 纯逻辑文件语法：common/converters、services、engines、common 共 **21 个文件**通过 DevEco SDK 捆绑 TypeScript `transpileModule` 检查,0 错误。
- 资源引用一致性：页面全部 `$r('app.color.*')` / `$r('app.string.*')` 引用均已在 `color.json` / `string.json` 中定义;页面未引用任何 `$r('app.media.*')`（图标以 emoji 文本替代）。
- 路由一致性：`Index.ets` 的 `router.pushUrl` 目标与 `main_pages.json` 注册的五个页面一一对应。
- 状态刷新：`@State` 数组统一采用重新赋值方式更新（避免 `push()` 不触发刷新）。
- ArkTS 编译：用户实测反馈的两个错误（`fdSrc` 不属于 `AVTranscoderConfig`、`AUDIO_MPEG` 不存在）已对照本机 SDK 类型定义修复（`fdSrc`/`fdDst` 为实例属性、`AUDIO_MP3`、容器枚举修正）;**待用户重新编译确认**。
- 构建脚本实测：`build-harmony.ps1` 依赖 `hvigorw` 包装器与 API 22 SDK;用户已在本机编译,说明 SDK 已具备。

### 结论与风险

- 文档与配置已按 API 22 / 6.0.2 对齐;五个页面、图片/音频/文档服务、文档转换核心均已落地。
- 编译错误已修复但**未经重新编译确认**;pages/components 的 ArkUI 语法（struct、组件闭包）无法用标准 TS 检查,依赖实际编译。
- 运行、交互与多设备验证仍为 `blocked`,待编译通过、具备设备后补测。

## 2026-08-01｜ArkTS / ArkUI 语法修复 QA

### 编译验证

| 场景 | 操作前状态 | 用户动作 | 操作后状态 | 结果 | 证据 |
| --- | --- | --- | --- | --- | --- |
| ArkTS 完整编译 | 2 个阻断错误 | 执行 API 22 `assembleHap` | `CompileArkTS` 失败 | 预期失败 | `PdfGenerator.ets:70` 未声明 `header`;`VideoConvertPage.ets:22` 缺少 `ConvertType.VIDEO` |
| PDF 生成器修复 | 2 个阻断错误 | 声明 PDF 1.4 文件头后重新构建 | PDF 错误消失,仅余视频枚举错误 | `passed` | Hvigor 第二轮编译输出 |
| 视频枚举修复 | 1 个阻断错误 | 补充 `ConvertType.VIDEO` 后重新构建 | ArkTS 编译与 HAP 打包成功 | `passed` | `docs/qa/2026-08-01-arkts-build.md` |
| 干净构建 | 已有增量构建缓存 | 执行 Hvigor `clean`,再运行标准构建脚本 | `CompileArkTS` 重新执行并成功 | `passed` | `docs/qa/2026-08-01-arkts-build.md` |

### 设备验证

- 本次仅修复编译类型与构建脚本探测,没有用户可见交互变更,因此不新增设备交互用例。
- 既有转换流程的 phone / tablet / 2in1 验证仍为 `blocked`,原因是当前未连接可用设备或模拟器。

## 2026-08-01｜Phone 功能逐项验证

- phone 模拟器 API 22 已连接，实际包名为 `com.maxtools.formatconverter`。
- `passed`：启动、首页、关于页、8 个工具路由、TXT 文档转换、TXT -> PDF、PDF 工具箱 Word转PDF、单位/时区换算、ZIP 压缩/解压、PCM WAV -> M4A。
- `fixed`：WAV -> M4A 改用 Native AudioCodec + AVMuxer；ZIP 使用明确后缀过滤；单位分类切换即时重算。
- `blocked`：图片功能缺少 MediaLibrary 已索引图片；视频转换缺少合法样本；tablet / 2in1 无可用设备。
- 逐项操作和截图索引见 `docs/qa/2026-08-01-phone-functional-test.md`。

## 2026-08-01｜Phone 缺陷修复回归

| 场景 | 操作前状态 | 用户动作 | 操作后状态 | 结果 | 证据 |
| --- | --- | --- | --- | --- | --- |
| 温度重算 | 重量页输入 `1` | 切换温度分类 | 显示 `1 °C = 33.8 °F` | `passed` | `unit-category-recalculate-pass.jpeg` |
| ZIP 压缩 | 压缩模式无文件 | 选择 `sample.txt`，压缩并保存 | `archive.zip` 190 字节 | `passed` | `zip-compress-pass.jpeg` |
| WAV→M4A | 音频页无文件 | 选择 `sample.wav`，转换并保存 | `sample.m4a` 12589 字节，标准 M4A 文件头 | `passed` | `audio-wav-m4a-pass.jpeg` |

- 静态门禁：`scripts/check-standard.ps1` 通过，0 warning。
- 完整构建：`scripts/build-harmony.ps1` 通过，ArkTS、arm64-v8a/x86_64 C++、HAP 打包均成功。
- 应用始终保持单机离线，未新增网络权限、包名、签名或发布配置变更。

## 2026-08-01｜生成资产真实转换回归

| 场景 | 操作前状态 | 用户动作 | 操作后状态 | 结果 | 证据 |
| --- | --- | --- | --- | --- | --- |
| CSV→JSON | 90 字节 CSV 已导入下载目录 | 选择 JSON 并保存 | 270 字节、3 条完整记录 | `passed` | `docs/qa/qa-matrix-readfix-converted.json` |
| UTF-16LE→HTML | 232 字节 UTF-16LE 文本 | 选择 UTF-16LE、HTML 并保存 | 中文正确，真实 `<br/>`，特殊字符安全转义 | `passed` | `docs/qa/qa-plain-utf16le-brfix-converted.html` |
| PNG→JPG | 320x200 PNG | 选 JPG、质量 90、允许保存 | 7447 字节 JFIF，320x200，关键颜色保留 | `passed` | `docs/qa/qa-color-grid-converted.jpg` |
| 图片缩放 | 320x200 PNG | 输入宽 160、关闭保持比例并保存 | PNG 160x200，中心 RGB `(0,255,0)` | `passed` | `docs/qa/qa-resized-output.png` |
| 颜色提取 | 中心带文字的绿色区域 | 提取中心 5x5 平均色 | `#009A00`，与离线像素计算一致 | `passed` | `docs/qa/image-color-pick-pass.jpeg` |

- 完整证据和缺陷根因：`docs/qa/2026-08-01-generated-assets-conversion-test.md`。
- phone 代表性文档和图片主流程已通过；视频、tablet、2in1 仍为 `blocked`。

## 2026-08-02 全功能审计补充

- `passed`：全部自动契约、ArkTS 类型检查、API 22 Native/ArkTS 构建；首页与视频 M4A/MP3 状态设备显示正确。
- `fixed`：BMP 输出改为项目内编码器；视频伪 MP3、PDF 虚假反向能力和颜色提取虚假复制提示已移除。
- `implemented`：MP4 AAC→M4A 无损重封装；项目自产未压缩文本 PDF→DOC/Markdown。
- `blocked`：当前模拟器 DocumentViewPicker 的“浏览”入口退回桌面且“最近”不索引 HDC 测试资产,导致新增能力设备闭环未完成；MOV→MP4 受 AVC 编码器缺失阻塞；tablet/2in1 无设备。
- 完整矩阵与证据：`docs/qa/2026-08-02-full-functional-audit.md`。

## 2026-08-02 2in1 复测补充

- `passed`：2in1 首页/路由、系统文件选择器、PNG→BMP、MP4→M4A、TXT→PDF、PDF→Markdown、PDF→Word。
- `fixed`：9 个独立工具页固定 `NavigationMode.Stack`，消除 2in1 自动分栏窄侧栏；H.264/AAC MOV 通过 Native 无损重封装成功输出 MP4。
- `blocked`：非 H.264/AAC 的通用视频转码、复杂 PDF/Office、HEIF/GIF/MP3 仍需随包离线引擎；tablet 尚无独立设备。
- 完整设备证据：`docs/qa/2026-08-02-2in1-functional-test.md`。

## 2026-08-02 已开发功能回归

- `passed`：13 个自动契约、27 个 ArkTS 文件类型检查、标准门禁、HarmonyOS 完整构建；phone/2in1 已安装 3419.3 KB 最新 HAP。
- `passed`：phone 与 2in1 的图片、音频、视频禁用格式均显示“功能正在开发”，空输入转换按钮保持禁用，未支持项不能触发选择回调。
- `passed`：2in1 时区 `CST 01:30 → EST 12:30 (-1天)`；分钟 `60` 显示范围错误；温度 `1 °C = 33.8 °F`。
- `passed`：BMP 像素、M4A/MP4 轨道标记、PDF/Word 文件头、Markdown 哈希及 ZIP 内容复核通过。
- `fixed`：共享 `FormatSelector` 原先只用透明度表达禁用状态，现增加明确文字状态。
- `blocked`：独立 tablet 设备、发布签名、真实开发者主体/邮箱/隐私政策 URL 仍需外部输入；未开发引擎不计入 1.0 通过矩阵。
- 完整证据：`docs/qa/2026-08-02-developed-functions-regression.md`。

## 2026-08-02 参考图全界面 UI 回归

- 用户提供的八屏合成图已按实际 1448×1086 尺寸拆分为 8 张 362×543 PNG，保存在 `docs/qa/reference-ui/`，原图未修改。
- Phone 已覆盖首页、全部工具入口、PDF、档案、时区、单位、图片工具三个页签和关于页；关键交互包含正常结果、非法输入和未开发能力灰置状态。
- 2in1 已有本分支最新首页、图片、文档和视频页面截图，独立页使用 `NavigationMode.Stack` 且内容宽度受 `CONTENT_MAX_WIDTH` 约束。
- 本轮收尾时 2in1 HDC 端点离线，未重复安装最终包；沿用同一分支此前的 2in1 截图与真实转换产物证据，并将其记录为设备可用性限制。
- Tablet 仍无独立设备；发布签名、主体和法务元数据仍需发布方输入，不纳入 UI 回归通过范围。
- 完整映射、操作前后状态和证据索引：`docs/qa/2026-08-02-reference-ui-regression.md`。

## 2026-08-03 首页与关于页新版参考图回归

- `passed`：新增参考 UI 契约先失败后通过，约束首页标题、插画高度、卡片结构、底栏选中线、关于页图标及四枚隐私图标。
- `fixed`：phone 首轮截图显示最后一行功能卡被底栏部分遮挡，收敛主插画占高后八张卡片完整显示。
- `passed`：phone 首页、phone 关于页、2in1 首页、2in1 关于页均安装同一 HAP 实测，内容无裁切，标签切换和选中态正常。
- `passed`：静态契约覆盖 600–839vp tablet 三列分支；本轮无独立 tablet 模拟器，因此未声明 tablet 设备截图通过。
- 完整操作前后状态与截图索引：`docs/qa/2026-08-03-home-about-reference-ui.md`。

## 2026-08-03 应用图标替换回归

- `passed`：图标契约先以旧 512x512 entry 资源复现失败，替换后确认三处资源均为 1024x1024 RGBA PNG 且字节一致。
- `passed`：phone 关于页、phone 桌面、2in1 关于页与 2in1 任务栏均显示新蓝色环形箭头文件图标，主体完整且未被应用布局裁切。
- `passed`：21 个自动契约、28 个 ArkTS 文件类型检查、标准门禁和 HarmonyOS 完整构建通过。
- `boundary`：系统会对桌面图标施加设备形态遮罩；发布签名和商店材料不属于图片资源替换范围，当前仍生成 unsigned HAP。
- 完整证据：`docs/qa/2026-08-03-app-icon-replacement.md`。

## 2026-08-03 测试报告合理建议修复

- `passed`：PDF 原始字节输入、文档单次批量保存、三个视频 fd 状态读取和音频跳过进度均先由失败契约复现，再完成最小修复。
- `passed`：23 个自动契约、标准门禁和 HarmonyOS Native/ArkTS 完整构建；phone 与 2in1 均安装最新 unsigned HAP。
- `passed`：phone 启动后布局树确认前台为 `com.maxtools.formatconverter/pages/Index`，点击文档卡后进入 `pages/DocumentConvertPage`。
- `blocked`：phone 文档页点击“选择文件”后系统 Picker 未进入前台，布局树切回其他已安装应用，无法完成真实多文件选择与单次批量保存闭环；不以契约测试替代该设备证据。
- 完整证据：`docs/qa/2026-08-03-test-report-remediation.md`。
