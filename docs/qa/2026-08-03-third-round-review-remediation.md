# 2026-08-03 第三轮审查建议核实与修复

## 范围

依据“资源完整性、组件模式、ArkTS 合规性”审查报告，逐项核实当前工作区，而非将报告中的历史结论直接套用。应用保持单机离线、零网络权限；未改包名、签名、版本或发布配置。

## 根因与处置

| 审查项 | 处置 | 证据 |
| --- | --- | --- |
| C1 深色主题缺少 10 个颜色 | `passed`：补齐深色资源对浅色 21 个资源名的完整覆盖，避免浅色回退；同步提高浅色 `text_tertiary` 对比度。 | `test-third-round-theme-contract.js` |
| C2 视频直接 `statSync(uri)` | `passed`（报告基于旧代码）：普通转码、MOV 重封装、M4A 提取均已打开 picker fd 后再取状态。 | 既有三项视频 fd 契约 |
| C3 非 MP4 输入可走 M4A UI | `passed`：M4A 仅在全部输入为 MP4 时可执行；不符合时按钮禁用并展示明确提示。 | `test-third-round-video-archive-contract.js` |
| H2 PDF 用 `codePointAt` | `passed`（建议不适用）：PDF UTF-16BE 应写入 surrogate pair 代码单元，`😀` 的 `D83DDE00` 已由专项契约确认。 | `test-pdf-utf16-surrogate-contract.js` |
| H3 文档批量逐项保存 | `passed`（报告基于旧代码）：现有实现使用一次批量保存 Picker 并清理暂存输出。 | `test-document-batch-save-contract.js` |
| H4 隐私声明重复 | `passed`：首页与独立关于页复用 `PrivacyNoticeSection`，参考 UI 契约同步为共享实现。 | `test-third-round-component-contract.js`、`test-home-about-v2-reference-ui-contract.js` |
| H5 ZIP 同名源文件覆盖 | `passed`：沙箱暂存名按序号去重，写入失败抛出错误。 | `test-document-targets.js`、`test-third-round-video-archive-contract.js` |
| H6 HEIF 被执行路径接受 | `passed`（报告基于旧代码）：HEIF 已是 `nativeSupported: false` 的开发中项。 | `test-image-capability-contract.js` |
| M2/M3 | `passed`：CSV 支持 CR；HTML→Markdown 支持单引号链接与普通段落行内元素。 | `test-document-targets.js` |
| M4/M6 | `passed`：本轮图片及返回按钮补充读屏语义；浅色三级文本对比度达到 AA。 | `test-third-round-accessibility-contract.js`、`test-third-round-theme-contract.js` |
| L3/L4/L5、结果列表 key | `passed`：禁用项不能呈品牌选中态；进度条统一品牌令牌；文件面板可随大字体增长；结果列表 key 引入稳定索引。 | `test-third-round-component-contract.js`、`test-ui-design-system-contract.js` |
| L7 无原生源码 | `passed`（报告基于旧代码）：Native Audio 源码、类型声明与 CMake 已在项目内，既有视频/音频契约持续覆盖。 | `test-video-audio-extract-contract.js`、`test-video-remux-contract.js` |

## 未在本轮扩大处理的边界

- `STSong-Light` 的 CJK 显示依赖目标 PDF 查看器的 CIDFont 支持。未提供可发布、可嵌入字体资产，故不引入来源或许可证未知的二进制字体；发布前需以目标阅读器复验中文 PDF。
- 深色资源完整性已经自动验证，但本轮未切换模拟器系统深色主题，深色视觉截图为 `blocked`。
- 取消在途转换、键盘避让、超大 PDF 图像批处理和复杂 XML/Markdown 语义属于跨页/引擎改造，未在没有可复现缺陷的情况下扩展本轮范围；保留为后续专项验证项。

## 自动验证

| 项目 | 结果 | 证据 |
| --- | --- | --- |
| 全部 Node 契约 | `passed` | 28/28 个 `scripts/test-*.js` 通过 |
| 纯逻辑 ArkTS 类型检查 | `passed` | `TYPE OK (28 files)` |
| 标准门禁 | `passed` | `check-standard.ps1`：0 failure、0 warning |
| HarmonyOS 完整构建 | `passed` | `assembleHap` / `CompileArkTS` 成功；`entry-default-unsigned.hap`，5804.4 KB |

构建保留项目既有 API 弃用、异常处理和重复 `app_name` 警告；本轮未新增编译错误。

## Phone 设备回归

设备：API 22 phone 模拟器 `127.0.0.1:5555`；安装本轮 unsigned HAP。

| 场景 | 操作前状态 | 用户动作 | 操作后状态 | 结果 | 证据 |
| --- | --- | --- | --- | --- | --- |
| 视频页能力状态 | 首页 | 点击“视频转换” | MP4、M4A 可见，MP3 显示“功能正在开发”；无输入时“开始转换”禁用 | `passed` | `2026-08-03-third-round-video-page.png`、布局树 |
| 关于页隐私说明 | 首页 | 点击底栏“关于” | 4 条共享隐私说明、图标与版本信息完整显示，无裁切 | `passed` | `2026-08-03-third-round-about-page.png` |
| 非 MP4 的 M4A Picker 交互 | 无可用可选样本 | 本轮未能经系统 Picker 选入非 MP4 文件 | 代码与专项契约已覆盖前置禁用与提示；不将其替代为设备闭环 | `blocked` | `test-third-round-video-archive-contract.js` |
