# 已开发功能回归测试

## 环境

- phone 模拟器：`127.0.0.1:5555`，HarmonyOS API 22。
- 2in1 模拟器：`127.0.0.1:5557`，HarmonyOS API 22。
- 安装包：`entry-default-unsigned.hap`，3419.3 KB，两台设备均重新安装成功。
- 安全边界：未申请网络权限，未接入后端，测试文件只在本机和模拟器之间流转。

## 本轮结论

已启用的 1.0 功能未发现新的转换逻辑缺陷。自动契约、ArkTS 类型检查、静态门禁和 HarmonyOS 完整构建均通过；phone 与 2in1 的首页入口、独立页面、空输入状态和禁用格式状态完成回归。

本轮发现并修复一项用户可见问题：未支持格式原先只灰置，没有统一显示状态。共享 `FormatSelector` 现对 HEIF、AAC、MP3、FLAC、WAV、OGG 等禁用项显示“功能正在开发”，并继续阻止选择回调。

## 设备交互证据

| 场景 | 操作前状态 | 用户动作 | 操作后状态 | 结果 | 证据 |
| --- | --- | --- | --- | --- | --- |
| phone/2in1 禁用格式 | 图片、音频、视频页未选择文件 | 查看目标格式 | 图片 1 项、音频 5 项、视频 1 项显示“功能正在开发”；开始转换按钮禁用 | `passed` | `current-*-disabled-labels.json`、`current-disabled-phone.jpeg`、`current-disabled-2in1.jpeg` |
| 时区跨日 | 2in1 时区页，默认 CST→EST | 输入 `01:30` | 显示 `CST (北京时间) 01:30 = EST (美东) 12:30 (-1天)` | `passed` | `current-2in1-timezone-valid-result.json` |
| 时区非法分钟 | 2in1 时区页，默认 CST→EST | 输入 `01:60` | 显示 `分钟需在 0-59 之间`，不产生换算结果 | `passed` | `current-2in1-timezone-invalid-result.json` |
| 温度换算 | 2in1 重量页 | 切换温度并输入 `1` | 显示 `1 摄氏度 (°C) = 33.8 华氏度 (°F)` | `passed` | `layout-current-2in1-unit-temp.json` |
| 页面入口 | phone 与 2in1 首页 | 逐项进入 9 个入口/页签 | phone 9/9；2in1 9/9，图片/视频早点击重试后通过 | `passed` | `layout-current-*-route-*.json` |

## 真实产物复核

| 能力 | 复核结果 | 结果 |
| --- | --- | --- |
| PNG→BMP | 320x200；源 PNG 与 BMP 共 64,000 像素逐像素一致；BMP 头为 `BM` | `passed` |
| MP4→M4A | 包含 `ftyp/moov/mdat/soun/mp4a`，不包含视频轨标记 | `passed` |
| MOV→MP4 | 包含 `ftyp/moov/mdat/vide/soun/avc1/mp4a` | `passed` |
| TXT→PDF | 文件头 `%PDF-1.4` | `passed` |
| PDF→Markdown | 与源 TXT 均为 143 字节，SHA-256 完全一致 | `passed` |
| PDF→Word | 包含 Office HTML、UTF-8 meta 和 body | `passed` |
| ZIP 压缩/解压 | ZIP 文件头 `PK`，归档含 `sample.txt`；解压产物可读取 | `passed` |

本轮重新从模拟器取回的副本以 `docs/qa/current-*` 命名。完整转换点击、系统选择器和保存闭环的同生产逻辑证据见 `2026-08-02-2in1-functional-test.md` 与 `2026-08-02-full-functional-audit.md`。

## 自动验证

- 13 个 `scripts/test-*.js`：全部通过。
- `node scripts/_type_check.js`：`TYPE OK (27 files)`。
- `scripts/check-standard.ps1`：`PASSED (0 warning)`。
- `scripts/build-harmony.ps1`：`BUILD SUCCESSFUL`，HAP 3419.3 KB。

## 未计入 1.0 通过矩阵

- HEIF/GIF、通用 MP3/AAC/FLAC/OGG 转码、非 H.264/AAC 通用视频转码、复杂 PDF/OCR 和二进制 Office 仍需要随包离线引擎，当前统一禁用并显示“功能正在开发”。
- 独立 tablet 模拟器/真机尚不可用；已有 phone 和 2in1 证据不能冒充 tablet 证据。
- 当前产物为 unsigned HAP；发布签名、真实开发者主体、支持邮箱和公开隐私政策 URL 必须由发布者提供，不能由代码测试解决。

