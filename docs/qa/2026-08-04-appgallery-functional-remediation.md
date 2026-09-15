# 2026-08-04 AppGallery 审核功能下架与字号整改

## 目标

消除审核发现的未验证转换能力和低于 10fp 的“开发中”文字，使当前发布包只呈现已验证的离线功能。

## 审核反馈与处理

| 审核项 | 处理结果 | 代码证据 |
| --- | --- | --- |
| 图片转换 HEIF 显示开发中 | 移除 HEIF/GIF 目标格式 | `FormatTypes.ets`、`ImageConvertPage.ets` |
| 视频转换 MP3 显示开发中 | 移除 MP3 目标格式和说明 | `VideoConvertPage.ets` |
| 音频 M4A 转换失败，其他格式显示开发中 | 下架音频首页入口、页面、路由和服务 | `Index.ets`、`main_pages.json` |
| 档案 7Z/TAR.GZ/RAR 显示开发中 | 档案格式仅保留 ZIP | `ArchiveTimePage.ets` |
| “功能正在开发”字体为 9fp | 删除开发中状态模型；全量字号契约要求最低 10fp | `OptionChipGroup.ets`、`test-disabled-format-status-contract.js` |

## 自动化验证

操作前：旧代码仍保留 HEIF、MP3、音频页面、档案占位和 `fontSize(9)`。

用户动作：将专项契约改为验证下架项不存在和最小字号要求，先运行确认失败；再执行最小下架修改。

操作后：以下 29 个 Node 契约均通过，包括发布边界、图片、视频、ZIP、响应式、无障碍和 PDF 回归：

```powershell
$tests = Get-ChildItem .\scripts\test-*.js | Sort-Object Name
foreach ($test in $tests) { node $test.FullName }
```

静态门禁通过：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check-standard.ps1
# RESULT: PASSED (0 warning(s))
```

## HarmonyOS 构建状态

ArkTS 编译、Native 构建、资源处理、HAP 打包均已完成，并生成 `entry-default-unsigned.hap`。后续签名阶段因现有 `build-profile.json5` 指向的本机证书文件不存在而失败。

- 状态：`blocked`
- 未修改：包名、应用 ID、版本、签名身份、签名口令或 AGC 配置。
- 恢复条件：发布方提供当前签名配置可访问的证书，或明确授权更新签名配置；随后重新执行 `scripts/build-harmony.ps1`。

## 待设备复验

在签名构建恢复后，使用待上架 HAP 在目标设备执行：打开首页确认无音频入口；进入图片、视频、档案页确认下架格式不出现；分别执行一个保留能力的转换或 ZIP 流程，并保存操作前、用户动作和操作后截图至本目录。
