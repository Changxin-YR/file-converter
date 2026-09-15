# 2026-08-03 应用名称变更验证

## 范围

- 将用户可见名称从“万能格式转换”改为“文件格式盒”。
- 保持 `bundleName`、应用 ID、版本、签名、权限、路由与 1024x1024 RGBA 应用图标不变。

## 自动验证

| 检查 | 结果 | 证据 |
| --- | --- | --- |
| 名称契约 RED | 通过 | 修改前运行 `node scripts/test-app-name-contract.js`，断言显示 `万能格式转换 !== 文件格式盒`。 |
| 名称与全量 Node 契约 | 通过 | 29 项脚本全部输出 `PASSED`，其中包含 `APP NAME CONTRACT PASSED`。 |
| ArkTS 类型检查 | 通过 | `node scripts/_type_check.js` 输出 `TYPE OK (28 files)`。 |
| 标准门禁 | 通过 | `scripts/check-standard.ps1` 输出 `RESULT: PASSED (0 warning(s))`。 |
| HarmonyOS 构建 | 通过 | `scripts/build-harmony.ps1` 输出 `BUILD SUCCESS`；产物为 `entry/build/default/outputs/default/entry-default-unsigned.hap`。 |

## phone 交互验证

- 操作前：工程资源中的 `app_name` 为旧名称；设备存在同包名的调试安装版本。
- 用户动作：在 phone `127.0.0.1:5555` 覆盖安装新 HAP，启动 `EntryAbility`，在首页查看标题，再点击“关于”。
- 操作后：首页标题显示“文件格式盒”；关于页布局树的可见标题节点 `originalText` 与 `text` 均为“文件格式盒”。
- 截图：[首页](2026-08-03-file-format-box-home.jpeg)。关于页截图受设备当前画面旋转输出影响，名称节点的可复现证据保存在 [布局树](2026-08-03-file-format-box-about-layout.json)。

## 发布边界

- HAP 仍是 unsigned 开发构建；上架前须使用发布签名。
- 客户端显示名已替换，但商店名称是否可注册、是否与商标冲突，仍以 AppGallery Connect 提交时的实时校验及发布方完成的商标检索为准。
