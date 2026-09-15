# 文件格式盒应用名称变更 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 HarmonyOS 应用的全部当前用户可见名称统一为“文件格式盒”，不改变应用身份与发布配置。

**Architecture:** 应用名仍由 Stage 与 entry 两套 `app_name` 资源提供，现有配置和页面继续引用 `$string:app_name`，仅修正少数与旧名称绑定的无障碍文案。用独立 Node.js 契约脚本锁定资源、配置、页面与现行产品文档，避免未来资源重新分叉。

**Tech Stack:** HarmonyOS Stage、ArkTS/ArkUI、JSON 资源、Node.js 契约测试、PowerShell 构建脚本。

---

### Task 1: 建立名称一致性回归契约

**Files:**
- Create: `scripts/test-app-name-contract.js`

- [x] **Step 1: 写入失败测试**

```js
const expectedName = '文件格式盒'
assert.strictEqual(readAppName('AppScope/resources/base/element/string.json'), expectedName)
assert.strictEqual(readAppName('entry/src/main/resources/base/element/string.json'), expectedName)
assert.ok(!read('entry/src/main/ets/pages/Index.ets').includes('万能格式转换'))
assert.ok(!read('entry/src/main/ets/pages/AboutPage.ets').includes('万能格式转换'))
```

- [x] **Step 2: 运行测试并确认当前失败**

Run: `node scripts/test-app-name-contract.js`

Expected: FAIL，因为两份 `app_name` 资源当前仍是“万能格式转换”。

- [x] **Step 3: 保持测试文件为最小只读契约**

```js
console.log('APP NAME CONTRACT PASSED')
```

- [x] **Step 4: 后续资源更新后重新运行测试**

Run: `node scripts/test-app-name-contract.js`

Expected: `APP NAME CONTRACT PASSED`。

### Task 2: 更新显示名称与可访问性文案

**Files:**
- Modify: `AppScope/resources/base/element/string.json:4-6`
- Modify: `entry/src/main/resources/base/element/string.json:12-14`
- Modify: `entry/src/main/ets/pages/Index.ets:138`
- Modify: `entry/src/main/ets/pages/AboutPage.ets:17`

- [x] **Step 1: 修改两份资源的 `app_name` 值**

```json
{
  "name": "app_name",
  "value": "文件格式盒"
}
```

- [x] **Step 2: 更新旧应用名无障碍标签**

```ts
.accessibilityText('文件格式盒应用图标')
```

- [x] **Step 3: 运行名称契约**

Run: `node scripts/test-app-name-contract.js`

Expected: `APP NAME CONTRACT PASSED`。

### Task 3: 同步当前产品文档并完成验证

**Files:**
- Modify: `README.md:1`
- Modify: `docs/开发文档.md:1,39`
- Modify: `tasks.md:T-20260803-006`
- Modify: `changes.md:末尾`
- Create: `docs/qa/2026-08-03-app-name-change.md`

- [x] **Step 1: 将当前产品文档标题与简介改为“文件格式盒”**

```markdown
# 文件格式盒（FormatConverter）
```

历史规格保留其撰写时名称，不作追溯性改写。

- [x] **Step 2: 执行静态、契约与构建验证**

Run: `node scripts/test-app-name-contract.js; node scripts/_type_check.js; powershell -NoProfile -ExecutionPolicy Bypass -File .\\scripts\\check-standard.ps1; powershell -NoProfile -ExecutionPolicy Bypass -File .\\scripts\\build-harmony.ps1`

Expected: 名称契约、类型检查、标准门禁与 HarmonyOS 构建全部通过；签名配置缺失警告如仍存在，记录为既有发布环境提示。

- [x] **Step 3: 安装最新 HAP 到已连接 phone 并核验显示名**

操作前：设备安装旧名称版本。用户动作：安装构建生成的 HAP 并在桌面、首页和关于页查看。操作后：三处均显示“文件格式盒”。将截图或可复现的设备检查记录写入 QA 文档。

- [x] **Step 4: 回填任务与变更记录**

在 `tasks.md` 将 `T-20260803-006` 改为 `done`，并附 QA 文件路径；在 `changes.md` 写明只改显示名，未修改 bundleName、app ID、版本、签名、权限或图标。

## 自检

- 规格中的显示名、资源统一、无障碍标签、现行文档、契约、构建与 phone 验收均映射到 Task 1–3。
- 本计划不含 TODO/TBD 或未定义的接口；所有修改文件与命令均明确列出。
- 本次只处理一个显示名边界，未拆分或重构业务模块。
