# 应用图标替换设计

## 目标

将用户提供的 `codex-clipboard-17d2b6c6-c7f9-4150-bd52-0c4ab9847cf2.png` 作为万能格式转换的新应用图标，并满足当前 HarmonyOS Stage 模型工程的资源与上架检查要求。

## 范围

- 替换 `AppScope/resources/base/media/app_icon.png`，供应用级桌面图标使用。
- 替换 `entry/src/main/resources/base/media/app_icon.png`，供 EntryAbility 图标与启动窗口使用。
- 替换 `entry/src/main/resources/base/media/ui_about_app_icon.png`，保证关于页品牌图标一致。
- 不修改包名、应用 ID、版本号、签名身份、权限、路由或任何转换功能。

## 资源处理

- 原图是正方形 PNG，保留图形主体、颜色、光影与圆角造型，不重新生成或重绘。
- 三个目标资源使用相同像素内容，避免桌面、启动页和关于页出现品牌不一致。
- 输出保持正方形 PNG、有效 RGBA/RGB 像素和完整边缘留白，不拉伸、不裁掉箭头或文件主体。
- HarmonyOS 系统最终会依据设备桌面图标遮罩显示圆角；项目不额外叠加文字或水印。

## 验证

- 新增自动契约，检查三份图标存在、PNG 签名正确、尺寸相同且文件内容一致。
- 执行全部 `scripts/test-*.js`、ArkTS 类型检查、标准门禁和 HarmonyOS 构建。
- 将最终 HAP 覆盖安装到 phone 与 2in1，验证启动、桌面图标及关于页图标显示，并保存截图到 `docs/qa/`。

## 已知发布边界

- 图标资源合规不等同于完成商店发布；正式上架仍需要发布签名、开发者主体和商店素材配置。
- 本任务不改变当前 unsigned HAP 的签名状态。
