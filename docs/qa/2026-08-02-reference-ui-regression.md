# 参考图全界面 UI 回归

日期：2026-08-02

## 范围与基准

- 视觉基准：用户提供的 1448×1086 八屏合成图；原图未修改。
- 独立切片：`docs/qa/reference-ui/01-home.png` 至 `08-image-tools.png`，均为 362×543 PNG。
- 运行范围：首页、图片、文档、音频、视频、PDF、档案与时间、单位、图片工具、关于。
- 产品边界：应用保持单机离线、无网络权限；未开发格式灰色禁用并显示“功能正在开发”。

## 参考页对照

| 参考页 | 实现证据 | 核对结果 |
| --- | --- | --- |
| 首页 | `reference-home-phone.jpeg`、`reference-home-2in1.jpeg` | 品牌头图、两列工具入口、底部导航和宽屏列数适配符合统一视觉系统 |
| 图片格式转换 | `reference-image-phone.jpeg`、`reference-image-2in1.jpeg` | 文件选择、目标格式、质量、主操作和结果区层级完整 |
| 文档格式转换 | `reference-document-phone.jpeg`、`reference-document-2in1.jpeg` | 文件选择、动态格式、源编码和转换操作完整 |
| PDF 工具箱 | `reference-pdf-phone.jpeg` | 工具列表、能力说明和进入箭头完整；能力声明与实际引擎一致 |
| 档案转换 | `reference-archive-phone.jpeg` | ZIP 可用；7Z、TAR.GZ、RAR 灰置并显示“功能正在开发” |
| 时区转换 | `reference-timezone-pass-phone.jpeg`、`reference-timezone-invalid-phone.jpeg` | 正常换算和分钟范围错误均有明确结果反馈 |
| 单位换算器 | `reference-unit-phone.jpeg`、`reference-unit-temperature-pass-phone.jpeg` | 类型、输入、单位选择和即时计算布局完整 |
| 图片工具 | `reference-image-tools-resize-phone.jpeg`、`reference-image-tools-crop-phone.jpeg`、`reference-image-tools-color-phone.jpeg` | 缩放、裁剪、颜色三个分段页均可达且状态清晰 |

## 相似风格扩展页

| 页面 | 运行证据 | 结果 |
| --- | --- | --- |
| 音频转换 | `reference-audio-phone.jpeg` | WAV→M4A 保持可用；其他输出格式灰色禁用 |
| 视频转换 | `reference-video-phone.jpeg`、`reference-video-2in1.jpeg` | MOV→MP4、MP4→M4A 保持可用；MP3 灰色禁用 |
| 关于 | `reference-about-phone.jpeg` | 仅显示可验证的离线、隐私和版本信息，无占位邮箱或网址 |

## 交互验证

| 场景 | 操作前状态 | 用户动作 | 操作后状态 | 结果 |
| --- | --- | --- | --- | --- |
| 档案禁用态 | 档案页未选择格式 | 点击 7Z / TAR.GZ / RAR | 控件不进入选择或转换路径，显示“功能正在开发” | `passed` |
| 时区正常输入 | CST、01:30、目标 EST | 执行换算 | 显示 `12:30 (-1天)` | `passed` |
| 时区非法输入 | 分钟输入 60 | 执行换算 | 显示“分钟需在 0-59 之间” | `passed` |
| 温度换算 | 输入 1 摄氏度 | 选择华氏度 | 显示 `33.8 华氏度 (°F)` | `passed` |
| 图片工具切换 | 图片工具默认缩放页 | 切换裁剪、颜色 | 两个页面均显示对应控件且无重叠 | `passed` |
| 关于页 | 从首页进入关于 | 查看声明与版本 | 离线、隐私、版本信息可见且无虚假联系方式 | `passed` |

已开发转换能力的真实文件产物继续采用既有回归证据：`2026-08-02-developed-functions-regression.md` 与 `2026-08-02-2in1-functional-test.md`。本轮只重构 UI，不改变通过验证的转换引擎和文件格式边界。

## 多设备与发布边界

- Phone：API 22 模拟器 `127.0.0.1:5555` 可用，完成本轮主要页面和交互截图。
- 2in1：本轮收尾时 `127.0.0.1:5557` 离线，`hdc tconn` 返回 `Connect failed`；本分支仅有首页、图片、文档和视频的最新 2in1 截图及既有真实转换证据。最终 HAP 未重新安装，PDF、档案/时区、单位、图片工具、音频和关于缺少改版后的 2in1 证据，因此多设备验收保持 `blocked`，不将其误报为应用失败或已通过。
- Tablet：没有独立设备证据，不能声明通过。
- 发布签名、开发者主体、客服邮箱、隐私政策 URL 和 AppGallery Connect 材料需要发布方提供，项目没有伪造或修改。
- HEIF/GIF/MP3、复杂 PDF/Office、通用音视频转码等仍需要随包离线引擎；当前保持灰色“功能正在开发”，不纳入 1.0 已通过能力。

## 自动验证

- 全部 `scripts/test-*.js`：19/19 通过。
- `node scripts/_type_check.js`：`TYPE OK (28 files)`。
- `scripts/check-standard.ps1`：`PASSED (0 warning(s))`。
- `scripts/build-harmony.ps1`：`BUILD SUCCESSFUL`，生成 `entry-default-unsigned.hap`，3957.8 KB。
- 构建仅报告未配置 release 签名；该项需要发布方身份和证书，未修改项目签名配置。
