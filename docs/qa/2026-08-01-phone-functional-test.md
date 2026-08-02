# Phone 功能逐项验证

## 环境

- 日期：2026-08-01
- 设备：HarmonyOS Emulator（phone，1320 x 2856）
- 系统：API 22
- 包名 / Ability：`com.maxtools.formatconverter` / `EntryAbility`
- 安装包：`entry/build/default/outputs/default/entry-default-unsigned.hap`
- 测试数据：`sample.txt`、`sample.csv`、`sample.html`、`sample.wav`、`sample.zip`

## 结果摘要

| 模块 | 结论 | 说明 |
| --- | --- | --- |
| 安装、启动、首页 | `passed` | HAP 安装和 Ability 启动成功，首页 8 个工具入口正常显示。 |
| 首页路由与返回 | `passed` | 8 个工具页均可进入并通过页面内返回按钮返回。 |
| 关于页与离线声明 | `passed` | 显示单机离线、数据不出设备及 API 22 信息。 |
| 文档转换 TXT -> TXT | `passed` | 选择 `sample.txt`，转换、保存成功。 |
| 文档转换 TXT -> PDF | `passed` | 生成 PDF、系统保存选择器和落盘均成功。 |
| PDF 工具箱 Word转PDF | `passed` | 以 `sample.txt` 验证，设备端 `sample.pdf` 为 1095 字节。 |
| 单位换算 | `passed` | 输入 `1` 后切换到温度，立即显示 `1 °C = 33.8 °F`。 |
| 时区换算 | `passed` | CST 08:30 -> EST 19:30（-1 天）正确。 |
| ZIP 解压 | `passed` | 解压并保存 1 个文件，设备端 `sample.txt` 为 67 字节。 |
| ZIP 压缩 | `passed` | `sample.txt` 可见、可选，保存的 `archive.zip` 为 190 字节。 |
| 音频 WAV -> M4A | `passed` | Native AudioCodec + AVMuxer 转换并保存成功；`sample.m4a` 为 12589 字节，文件头为 `ftyp M4A / isom`。 |
| 图片转换 / 图片工具 | `blocked` | HDC 注入的 JPEG 未进入模拟器 MediaLibrary，无法执行真实转换。 |
| 视频转换 | `blocked` | 未选择文件时按钮正确禁用；设备中没有合法视频样本。 |

## 关键交互证据

| 场景 | 操作前状态 | 用户动作 | 操作后状态 | 结论 | 证据 |
| --- | --- | --- | --- | --- | --- |
| 启动与首页 | 应用未启动 | 安装 HAP，启动 `EntryAbility` | 首页显示 8 个工具卡片 | `passed` | `formatconverter-home.jpeg` |
| 全部工具路由 | 首页 | 逐个进入工具页并点击页面内返回 | 8 个目标页均渲染且可返回 | `passed` | `phone-*.jpeg` |
| PDF 工具箱 | Word转PDF 页，无文件 | 选择 `sample.txt`，转换并保存 | 显示“已将 1 个文档转换为PDF” | `passed` | `pdf-toolbox-word2pdf-pass.jpeg` |
| 单位分类重算 | 重量页已输入 `1` | 切换到温度 | 立即显示 `1 摄氏度 (°C) = 33.8 华氏度 (°F)` | `passed` | `unit-category-recalculate-pass.jpeg` |
| ZIP 压缩 | 压缩模式，无文件 | 选择 `sample.txt`，压缩并保存 | 显示“已将 1 个文件压缩为 ZIP 并保存” | `passed` | `zip-compress-pass.jpeg` |
| 音频转码 | 音频页，无文件 | 选择 `sample.wav`，执行 WAV -> M4A 并保存 | 显示“转换完成 1 个文件”，外部 M4A 为 12589 字节 | `passed` | `audio-wav-m4a-pass.jpeg` |
| 图片选择 | 图片转换页，无文件 | 打开图片选择器 | 无已索引图片，仅可取消 | `blocked` | `image-picker-empty.jpeg` |
| ZIP 解压 | 解压模式，已选择 `sample.zip` | 选择新目录并确认解压 | 显示“已解压并保存 1 个文件” | `passed` | `zip-extract-pass.jpeg` |

## 缺陷与环境问题

1. 已修复：单位分类切换改为调用 `calculate()`。
2. 已修复：ZIP 压缩使用明确的普通文件后缀列表，解压仍限定 `.zip`。
3. 已修复：PCM WAV→M4A 改用同步 Native AudioCodec + AVMuxer，不再走失败的 `AVTranscoder.prepare()`。
4. 系统 File Manager 日志仍有 cloud/DataShare 等模拟器噪声，不影响明确后缀的文档、音频和 ZIP 选择。
5. 图片和视频真实转换仍受测试样本环境阻塞；tablet / 2in1 尚无可用设备。

## 多设备覆盖

| 设备类型 | 状态 | 说明 |
| --- | --- | --- |
| phone | `partial` | 三个已知缺陷全部回归通过；图片/视频仍受样本环境阻塞。 |
| tablet | `blocked` | 当前无 tablet 设备或模拟器。 |
| 2in1 | `blocked` | 当前无 2in1 设备或模拟器。 |

T-20260801-012 已完成；整体验证任务仍因图片/视频样本和 tablet / 2in1 覆盖保持 `in_progress`。

## 回归门禁

- `scripts/check-standard.ps1`：`PASSED`，0 warning。
- `scripts/build-harmony.ps1`：`BUILD SUCCESSFUL`，`CompileArkTS` 和 `PackageHap` 成功。
- 构建产物：`entry/build/default/outputs/default/entry-default-unsigned.hap`，3324.1 KB（含 arm64-v8a / x86_64 native_audio）。
- 遗留构建警告：弃用 API、可能抛出异常的调用、重复 `app_name` 和未配置签名；均为已有问题，未阻断构建。
