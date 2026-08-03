# 主工作区 UI 版本错位修复

日期：2026-08-03

## 现象

DevEco 从 `C:\Users\27363\Desktop\max\transform` 运行应用后，首页显示参考 UI 重构前的灰白卡片界面。

## 根因

| 位置 | 修复前提交 | 状态 |
| --- | --- | --- |
| DevEco 打开的项目根目录 | `d80645a` / `codex/project-import` | 旧 UI |
| 参考 UI 隔离工作树 | `3c67edf` / `codex/reference-ui-redesign` | 新 UI |
| Gitee `origin/master` | `3c67edf` | 新 UI |

两个工作树使用相同包名 `com.maxtools.formatconverter`。从旧根目录运行时，旧 HAP 会覆盖模拟器中昨天安装的新版 HAP，所以表现为“第二天 UI 恢复旧版”；源代码和远端提交没有丢失。

## 修复与验证

| 操作前状态 | 用户动作 | 操作后状态 | 结果 |
| --- | --- | --- | --- |
| 根目录 HEAD 为 `d80645a` | 验证祖先关系后将本地 `master` 快进到 `origin/master` 并切换 | 根目录 HEAD、`master`、`origin/master` 均为 `3c67edf` | `passed` |
| 根目录旧构建缓存存在 | 从根目录运行全部测试、类型检查、标准门禁和完整构建 | 19 个契约通过，`TYPE OK (28 files)`，标准门禁 0 warning，HAP 构建成功 | `passed` |
| Phone 可能安装旧 HAP | 覆盖安装并重启 `EntryAbility` | `pages/Index` 显示新版文案、插画与文件图标卡片 | `passed` |
| 2in1 可能安装旧 HAP | 覆盖安装同一 HAP 并重启 `EntryAbility` | 宽屏首页显示新版四列卡片与主插画 | `passed` |

设备截图：

- `docs/qa/2026-08-03-workspace-version-fix-phone.jpeg`
- `docs/qa/2026-08-03-workspace-version-fix-2in1.jpeg`

构建产物：`entry/build/default/outputs/default/entry-default-unsigned.hap`，3957.8 KB。构建仍有既有 API 弃用、异常处理、重复 `app_name` 和未配置签名警告，均未阻断本次构建；发布签名仍需发布方配置。
