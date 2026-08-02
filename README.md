# 万能格式转换（FormatConverter）

本地单机文件格式转换工具,覆盖文档、图片、音频、视频与受限 PDF 转换。应用**不联网、无后端、不上传任何数据**,所有转换均在设备本地完成。

> 详细设计请参阅 [docs/开发文档.md](docs/开发文档.md)

---

## 产品定位

- 文档 / 图片 / 音频格式互转,全部本地完成
- 单机离线运行,飞行模式 / 无网环境可用
- 权限最小化,数据不出设备

## 核心能力

| 功能模块 | 定位 | 支持格式 |
| --- | --- | --- |
| 文档格式转换 | 主 | TXT / CSV / JSON / XML / HTML / Markdown 互转与文本 PDF 导出 |
| 图片格式转换 | 主 | PNG / JPG / JPEG / WEBP / BMP 互转,图片尺寸调整；HEIF 输出灰置 |
| 音频格式转换 | 辅助 | 16-bit PCM WAV → M4A（AAC LC） |
| 视频与音轨 | 辅助 | 视频转 MP4；含 AAC 音轨的 MP4 → M4A 无损重封装 |
| PDF 工具 | 辅助 | JPG/文本/HTML → PDF；项目自产未压缩文本 PDF → DOC/Markdown |

## 技术栈

| 项目 | 版本 |
| --- | --- |
| 开发语言 | ArkTS 5.0 |
| UI 框架 | ArkUI（声明式范式） |
| 应用模型 | Stage 模型（UIAbility） |
| SDK | HarmonyOS API 22 |
| 目标系统 | HarmonyOS 6.0.2 |
| 构建工具 | Hvigor |
| 目标设备 | phone、tablet、2in1 |

## 工程结构

```text
.
├── AppScope/                 # 应用级配置（API 22）
├── entry/
│   └── src/main/
│       ├── ets/
│       │   ├── entryability/ # UIAbility 入口
│       │   ├── pages/        # 页面（Index / DocumentConvert / ImageConvert / AudioConvert / About / VideoConvert / ImageTools / ArchiveTime / UnitConverter / PdfTools）
│       │   ├── components/   # 可复用 UI（FormatSelector / ProgressBar / ResultList）
│       │   ├── services/     # 转换 / 选择 / 保存服务
│       │   ├── engines/      # 转换引擎抽象层（IConvertEngine + 注册表）
│       │   └── common/       # 模型、常量、converters/ 文档转换核心
│       └── resources/        # 字符串 / 颜色 / 媒体资源 / 路由配置
├── docs/
│   ├── 开发文档.md           # 主开发文档（设计基线 v2.0）
│   └── qa/                   # QA 证据
├── scripts/
│   ├── build-harmony.ps1     # 构建脚本
│   └── check-standard.ps1   # 标准检查
├── design.md                 # 产品设计
├── AGENTS.md                 # AI 代理规则
├── tasks.md                  # 任务跟踪
├── changes.md                # 变更日志
├── build-profile.json5       # 工程构建配置（6.0.2(22)）
└── oh-package.json5          # 工程依赖
```

## 开发环境

- **IDE**：DevEco Studio 5.0+（需支持 API 22 的 SDK 6.0.2）
- **构建**：`scripts/build-harmony.ps1`（自动定位 DevEco Studio 自带的 Hvigor wrapper）
- **产物**：`entry/build/default/outputs/default/`

## 验证

```powershell
# 静态门禁
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check-standard.ps1

# 构建
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-harmony.ps1
```

## 设计红线

| 约束 | 说明 |
| --- | --- |
| 单机离线 | 不申请网络权限,不发起网络请求 |
| 无后端 | 无服务端、无云存储、无账号体系 |
| 权限最小化 | 系统 picker 临时授权为主 |
| 数据不出设备 | 不收集、不上传、不存储用户文件 |

## 已知限制

- HEIF、GIF 与 MP3 输出当前灰置,不进入执行路径
- PDF 反向转换不支持压缩流、加密、对象流、扫描件和复杂嵌入字体
- 当前 phone 模拟器缺少 AVC 视频编码器,MOV 等视频转 MP4 会在准备阶段失败；需真机复验
- 系统文件选择器在当前模拟器的“浏览”入口存在退回桌面的环境问题
- 应用为单机离线,不支持跨设备协同

## 规范依据

本项目遵循以下标准化规范：
- 项目标准规范：`harmonyos-project-standard-cn`
- 开发流程规范：`harmonyos-dev`
- ArkTS 语法规范：声明式 UI、Stage 模型、资源引用、状态管理等
