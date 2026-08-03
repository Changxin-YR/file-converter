# 测试报告合理建议修复 QA

## 环境

- 日期：2026-08-03。
- 工程：HarmonyOS API 22，分支 `codex/test-report-remediation`。
- 设备端点：phone `127.0.0.1:5555`、2in1 `127.0.0.1:5557`。
- 产物：`entry/build/default/outputs/default/entry-default-unsigned.hap`，5797.8 KB。
- 安全边界：未新增网络权限，未修改包名、应用 ID、版本、签名或 AGC 元数据。

## 自动验证

| 场景 | 操作前状态 | 动作 | 操作后状态 | 结果 |
| --- | --- | --- | --- | --- |
| PDF 原始字节 | 提取器仅接收字符串 | 传入含 `0xFF/0xFE/0xFD` 的项目文本 PDF 字节 | 提取 `binary-safe`，受限失败路径保持 | `passed` |
| 文档批量保存 | 页面逐文件调用保存 Picker | 运行批量保存契约 | 一次提交全部文件名，严格映射 URI，统一清理缓存 | `passed` |
| 视频 Picker URI | 三个入口直接 `statSync(sourceUri)` | 运行视频三组契约 | 全部改为 `statSync(sourceFile.fd)` | `passed` |
| 音频同格式跳过 | 跳过分支不更新进度 | 运行音频跳过契约 | 跳过项更新进度并进入完成反馈 | `passed` |
| 收尾资源与反馈审查 | 复制失败和保存取消存在残留或误报风险 | 扩展文档、视频和音频契约 | 失败目标/临时产物清理，原始序号与混合结果反馈保留 | `passed` |
| 全量回归 | 基线 21 个契约 | 运行全部 `scripts/test-*.js` | 23 个契约全部通过 | `passed` |
| HarmonyOS 构建 | 首轮出现任意类型 `throw` 错误 | 转为标准 `Error` 后重建 | Native、ArkTS 与 HAP 打包成功 | `passed` |

## 设备验证

| 场景 | 操作前状态 | 用户动作 | 操作后状态 | 结果 |
| --- | --- | --- | --- | --- |
| 最新包安装 | 两个模拟器在线 | 对 phone、2in1 执行覆盖安装 | 两端均返回 `install bundle successfully` | `passed` |
| phone 启动 | 最新包已安装 | 启动 `EntryAbility` | 布局树前台为 `com.maxtools.formatconverter/pages/Index` | `passed` |
| phone 文档入口 | 首页可见 | 点击“文档转换”卡片 | 布局树进入 `pages/DocumentConvertPage`，选择、格式和编码控件可见 | `passed` |
| phone 批量保存 | 文档页可见且无已选文件 | 点击“选择文件” | 系统 Picker 未进入前台，布局树切回其他已安装应用，无法继续选择多文件 | `blocked` |

2in1 已完成最新 HAP 覆盖安装；本轮未把安装成功推断为批量保存交互通过。PDF、视频和音频设备级产物仍沿用既有能力证据，本轮修复由原始字节测试、API 契约和完整 ArkTS 构建覆盖。

## 结论

代码层四类修复均有 RED/GREEN 契约和完整构建证据。phone 的系统 DocumentViewPicker 前台跳转问题阻止真实多文件批量保存闭环，因此该项保持 `blocked`；这属于当前设备环境边界，不改写为应用通过或失败。
