# 万能格式转换（FormatConverter）项目规则

本文件适用于本项目根目录及全部子目录。更深目录存在独立 `AGENTS.md` 时,以更具体的规则为准。

## 项目边界

- 项目类型：独立 HarmonyOS Stage 模型 ArkTS / ArkUI 工程。
- 业务源码：`entry/src/main/ets/`。
- 页面位于 `pages/`,复用 UI 位于 `components/`,业务服务位于 `services/`,转换引擎抽象位于 `engines/`,模型与工具位于 `common/`,页面状态适配位于 `viewmodel/`。
- 应用资源：`entry/src/main/resources/`。
- 不修改本项目范围外的文件或相邻工程。

## 产品红线（不可违背）

- **单机离线**：应用不得联网、无后端,不申请任何网络权限。
- **权限最小化**：仅申请完成转换所需的存储访问权限,按需动态申请。
- **数据不出设备**：不收集、不上传、不存储用户文件。

## 标准流程

1. 开始前阅读 `README.md`、`docs/开发文档.md`、`tasks.md`、`changes.md`、`design.md` 和 `design-qa.md`。
2. 在 `tasks.md` 登记任务,状态只使用 `pending`、`in_progress`、`done`、`blocked`。
3. 保持改动与用户需求一致,不顺带重构无关模块。
4. 用户可见交互变更同步更新 `design.md` 与 `docs/开发文档.md`。
5. 完成后执行静态检查、HarmonyOS 构建和与风险相称的设备验证。
6. 回填变更与 QA 证据后,才能把任务标记为 `done`。

## ArkTS 与 ArkUI

- 保持声明式 UI 代码合法,使用明确的 ArkTS 类型。
- 页面负责组合和交互;规则、存储与系统能力放入对应服务与引擎。
- `@Builder` 块内只写声明式 UI 语法;临时计算放入私有方法。
- 共享颜色、间距、尺寸与常量集中到 `common/`,禁止页面散落硬编码。
- 状态更新要能触发界面刷新,避免不可观察的嵌套直接修改。
- 路由、资源名和 `$r('app.xxx.xxx')` 引用必须与资源目录一致。
- 原生能力与三方引擎的边界通过 `IConvertEngine` 抽象隔离,禁止页面直接耦合具体引擎。

## 多设备与设计

- 支持范围：phone、tablet、2in1。
- 使用断点、相对尺寸和安全区适配,不只针对单一截图尺寸。
- 可交互控件应清晰、可点击并具有明确状态反馈。
- 加载、空、错误、禁用、完成状态必须有明确反馈;未支持能力灰置并提示。
- 宣传设计图与设备运行截图分别管理。

## 验证

至少执行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check-standard.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-harmony.ps1
```

交互验证必须包含操作前状态、用户动作和操作后状态。设备证据保存至 `docs/qa/`。静态门禁定义见 `docs/开发文档.md` 与项目 QA 门禁。

## 安全

- 不在代码、文档、日志、截图或聊天输出中复制签名口令、私钥、令牌或用户隐私。
- 未经用户明确要求,不修改包名、应用 ID、版本发布状态、签名身份或 AGC 元数据。
- 不提交构建缓存、IDE 本地配置和临时文件。
