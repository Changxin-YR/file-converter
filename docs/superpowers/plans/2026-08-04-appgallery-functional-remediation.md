# AppGallery Functional Remediation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove all AppGallery-audited unsupported conversion capabilities and make the release UI free of text smaller than 10fp.

**Architecture:** The published capability list becomes the sole UI source of truth: format arrays contain only executable targets, and the shared chip/tile components no longer support a “developing” state. Audio conversion is removed at the route and source level, while the native module remains because verified video M4A extraction imports it.

**Tech Stack:** HarmonyOS API 22, ArkTS, ArkUI, Node.js contract scripts, PowerShell Hvigor build.

---

### Task 1: Establish release-boundary contracts

**Files:**
- Modify: `scripts/test-image-capability-contract.js`
- Modify: `scripts/test-video-capability-contract.js`
- Modify: `scripts/test-video-audio-extract-contract.js`
- Modify: `scripts/test-disabled-format-status-contract.js`
- Modify: `scripts/test-conversion-reference-ui-contract.js`
- Modify: `scripts/test-navigation-stack-contract.js`
- Modify: `scripts/test-reference-ui-responsive-contract.js`
- Modify: `scripts/test-tools-reference-ui-contract.js`
- Modify: `scripts/test-audio-skip-progress-contract.js`

- [x] **Step 1: Replace the old “gray developing item” assertions with failing absence assertions.**

```javascript
for (const removed of ['heif', 'gif', 'mp3', '7z', 'tar.gz', 'rar', '功能正在开发']) {
  assert(!source.includes(removed), `${removed} must not be present in the published UI`)
}
assert(!fs.existsSync(audioPagePath), 'AudioConvertPage must be removed from the release')
```

Each script retains assertions for its verified neighbour: image BMP, video MP4/M4A, ZIP staging, responsive Stack navigation, and the native M4A extraction interface.

- [x] **Step 2: Add the global text-size check to `test-disabled-format-status-contract.js`.**

```javascript
const matches = source.matchAll(/\.fontSize\((\d+(?:\.\d+)?)\)/g)
for (const match of matches) {
  assert(Number(match[1]) >= 10, `fontSize(${match[1]}) is below the 10fp release minimum`)
}
```

The script reads every `.ets` file recursively below `entry/src/main/ets` and also verifies that no source retains the `developing` property.

- [x] **Step 3: Run the rewritten contracts and confirm they fail against the pre-remediation source.**

Run:
```powershell
node scripts/test-disabled-format-status-contract.js
node scripts/test-image-capability-contract.js
node scripts/test-video-capability-contract.js
node scripts/test-conversion-reference-ui-contract.js
```

Expected: failure reporting a retained unsupported capability, `AudioConvertPage`, “功能正在开发”, or `fontSize(9)`.

### Task 2: Remove unsupported UI capabilities and the failed audio feature

**Files:**
- Modify: `entry/src/main/ets/common/FormatTypes.ets`
- Modify: `entry/src/main/ets/pages/ImageConvertPage.ets`
- Modify: `entry/src/main/ets/pages/VideoConvertPage.ets`
- Modify: `entry/src/main/ets/pages/ArchiveTimePage.ets`
- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `entry/src/main/ets/components/FunctionTile.ets`
- Modify: `entry/src/main/ets/components/OptionChipGroup.ets`
- Modify: `entry/src/main/ets/pages/UnitConverterPage.ets`
- Modify: `entry/src/main/resources/base/profile/main_pages.json`
- Delete: `entry/src/main/ets/pages/AudioConvertPage.ets`
- Delete: `entry/src/main/ets/services/AudioConvertService.ets`

- [x] **Step 1: Limit data models to verified formats.**

```typescript
export const IMAGE_FORMATS: FormatInfo[] = [
  { extension: 'png', /* ... */ nativeSupported: true },
  { extension: 'jpg', /* ... */ nativeSupported: true },
  { extension: 'webp', /* ... */ nativeSupported: true },
  { extension: 'bmp', /* ... */ nativeSupported: true }
]
```

Remove `AUDIO_FORMATS`; remove HEIF/GIF from shared and image-page target arrays; remove MP3 from video targets and change its explanatory text to only describe MP4 and M4A; make the archive list contain one enabled ZIP item.

- [x] **Step 2: Remove the generic developing-state rendering path.**

```typescript
export interface ChipItem {
  key: string
  label: string
  enabled: boolean
}
```

Remove `developing` from `FunctionTile`, `OptionChipGroup`, Index card invocation, archive data and unit-chip construction. Keep disabled-parent handling in `OptionChipGroup`, but make `isEnabled` depend only on `!this.disabled && item.enabled`.

- [x] **Step 3: Remove the audio feature from all reachable application surfaces.**

Delete the audio card from `Index.functionCards`, remove `pages/AudioConvertPage` from `main_pages.json`, and delete the page and its `AudioConvertService`. Do not delete `entry/src/main/cpp/native_audio.cpp`, its CMake configuration or type declarations, because `VideoAudioExtractService` and `VideoRemuxService` still use them.

- [x] **Step 4: Run all capability contracts and type/build gates.**

Run:
```powershell
node scripts/test-disabled-format-status-contract.js
node scripts/test-image-capability-contract.js
node scripts/test-video-capability-contract.js
node scripts/test-video-audio-extract-contract.js
node scripts/test-third-round-video-archive-contract.js
node scripts/test-conversion-reference-ui-contract.js
node scripts/test-navigation-stack-contract.js
node scripts/test-reference-ui-responsive-contract.js
node scripts/test-tools-reference-ui-contract.js
```

Expected: every command prints its `... PASSED` result.

### Task 3: Synchronize product and QA evidence

**Files:**
- Modify: `README.md`
- Modify: `design.md`
- Modify: `docs/开发文档.md`
- Modify: `changes.md`
- Modify: `design-qa.md`
- Modify: `tasks.md`
- Create: `docs/qa/2026-08-04-appgallery-functional-remediation.md`

- [x] **Step 1: Replace historical release-facing claims with the published capability boundary.**

Document the retained image targets, removal of audio conversion, MP4/M4A-only video support, ZIP-only archive support, and the policy that unreleased capabilities are absent rather than shown as “开发中”. Keep historical change-log entries intact; append a new dated entry instead of rewriting history.

- [x] **Step 2: Record reproducible QA evidence.**

Create the QA record with the audit-trigger mapping, exact contract commands, standard-check/build commands, outcomes, and the remaining need to manually re-run the retained flows on the release device before resubmission.

- [x] **Step 3: Run the mandatory project verification.**

Run:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check-standard.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-harmony.ps1
```

Expected: static gate `RESULT: PASSED`; Hvigor produces a debug HAP without ArkTS or native-build errors.

- [ ] **Step 4: Fill verification results and complete the task.**

Set `T-20260804-001` to `done` only after all contract, static, and build results have been recorded in `changes.md`, `design-qa.md`, and the dated QA evidence file.

## Self-review

- Spec coverage: Task 1 guards every removed capability and the minimum font size; Task 2 removes the user-facing and executable surfaces; Task 3 updates all project-mandated documents and verification evidence.
- Placeholder scan: no TBD/TODO markers or unspecified implementation actions remain.
- Type consistency: `ChipItem` no longer carries `developing`; every planned caller is listed, and native audio is explicitly preserved for the remaining video services.
