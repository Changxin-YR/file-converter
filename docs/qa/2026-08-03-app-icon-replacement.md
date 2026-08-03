# 应用图标替换 QA

## 范围

- 源图：用户提供的 1254x1254 PNG。
- 目标：统一桌面、启动窗口和关于页图标，满足项目上架资源基线。
- 安全边界：不修改包名、应用 ID、版本、签名身份、AGC 元数据或权限。

## 资源验证

| 检查项 | 结果 | 证据 |
| --- | --- | --- |
| PNG 可解析 | `passed` | `scripts/test-app-icon-contract.js` |
| 尺寸 | `passed`，三处均为 1024x1024 | 图标契约 |
| 色彩类型 | `passed`，RGBA PNG | 图标契约 |
| 入口一致性 | `passed`，三份资源字节一致 | 图标契约 |
| 原设计保真 | `passed`，仅高质量缩放，无重绘 | 设备截图 |

## 设备交互验证

| 设备与场景 | 操作前状态 | 用户动作 | 操作后状态 | 结果 | 证据 |
| --- | --- | --- | --- | --- | --- |
| phone 关于页 | 安装旧图标版本 | 安装最新 HAP，打开关于页 | 显示新蓝色环形箭头文件图标 | `passed` | `2026-08-03-app-icon-phone.jpeg` |
| phone 桌面 | 系统可能保留旧图标缓存 | 返回桌面并刷新安装缓存 | 桌面显示新图标，系统遮罩正常 | `passed` | `2026-08-03-app-icon-launcher-phone.jpeg` |
| 2in1 关于页 | 最新 HAP 已启动在首页 | 点击“关于”标签 | 关于页显示新图标，主体完整 | `passed` | `2026-08-03-app-icon-2in1.jpeg` |
| 2in1 系统入口 | 应用窗口位于前景 | 返回系统桌面/任务区 | 底部任务栏显示新应用图标 | `passed` | `2026-08-03-app-icon-launcher-2in1.jpeg` |

## 自动与构建验证

- 21 个 `scripts/test-*.js` 契约全部通过。
- ArkTS 类型检查通过：28 个文件。
- `scripts/check-standard.ps1`：`PASSED (0 warning)`。
- `scripts/build-harmony.ps1`：`BUILD SUCCESSFUL`。
- 同一最新 HAP 已安装到 phone `127.0.0.1:5555` 和 2in1 `127.0.0.1:5557`。

## 发布边界

- 图标资源本身已通过本项目可自动验证的上架基线；HarmonyOS 系统会按设备形态施加桌面遮罩。
- 构建仍有既有 API 弃用/异常处理提示，不是本次图标替换引入。
- 当前产物为 unsigned HAP；正式上架仍需发布方提供 release 签名、开发者主体和商店材料。
