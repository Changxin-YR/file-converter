# Reference UI Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild every FormatConverter ArkUI page around the approved blue-white reference design while preserving offline conversion behavior and honest capability states.

**Architecture:** Introduce one shared visual token layer, a small set of reusable ArkUI presentation components, and a coherent PNG asset family. Pages keep their existing state and service methods but replace layout builders with the shared components. Source-contract tests, full ArkTS builds, and phone/2in1 screenshot checks gate each batch.

**Tech Stack:** HarmonyOS Stage model, ArkTS, ArkUI, ImageKit/CoreFileKit/MediaKit, Node.js contract tests, HDC UI automation, raster PNG assets.

**Repository note:** The workspace is attached to Gitee commit `0e00a98` on `master`. Because the remote originally contained only README files, the existing HarmonyOS project must first be imported on a protected baseline branch before UI work starts in an isolated worktree.

---

## File Map

**Create**

- `entry/src/main/ets/common/UiConstants.ets`: shared dimensions, breakpoints and animation durations.
- `entry/src/main/ets/components/AppPageHeader.ets`
- `entry/src/main/ets/components/PrimaryActionButton.ets`
- `entry/src/main/ets/components/FilePickerPanel.ets`
- `entry/src/main/ets/components/SegmentedControl.ets`
- `entry/src/main/ets/components/OptionChipGroup.ets`
- `entry/src/main/ets/components/ToolListItem.ets`
- `entry/src/main/ets/components/MetricInputField.ets`
- `entry/src/main/ets/components/StatusPanel.ets`
- `entry/src/main/ets/components/FunctionTile.ets`
- `scripts/test-ui-design-system-contract.js`
- `scripts/test-ui-assets-contract.js`
- `scripts/test-home-reference-ui-contract.js`
- `scripts/test-conversion-reference-ui-contract.js`
- `scripts/test-tools-reference-ui-contract.js`
- `scripts/test-reference-ui-responsive-contract.js`
- `docs/qa/2026-08-02-reference-ui-regression.md`

**Modify**

- `entry/src/main/resources/base/element/color.json`
- `entry/src/main/resources/base/element/string.json`
- `entry/src/main/ets/components/FormatSelector.ets`
- All files under `entry/src/main/ets/pages/`
- `design.md`, `design-qa.md`, `docs/开发文档.md`, `changes.md`, `tasks.md`

**Add raster resources**

- `ui_hero_home.png`, `ui_picker_image.png`, `ui_picker_document.png`, `ui_hero_pdf.png`, `ui_globe.png`
- `ui_tool_image.png`, `ui_tool_document.png`, `ui_tool_video.png`, `ui_tool_audio.png`
- `ui_tool_image_edit.png`, `ui_tool_archive.png`, `ui_tool_unit.png`, `ui_tool_pdf.png`
- `ui_pdf_image.png`, `ui_pdf_text.png`, `ui_pdf_html.png`, `ui_pdf_word.png`, `ui_pdf_markdown.png`

All raster resources live in `entry/src/main/resources/base/media/`, use transparent PNG backgrounds, and contain no embedded words.

---

### Task 0: Attach The Existing Workspace To Remote History

**Files:**
- Create: `.git/` metadata only
- Preserve: every existing workspace file

- [ ] **Step 1: Initialize and fetch without checking out files**

Run:

```powershell
git init -b master
git remote add origin https://gitee.com/YR23/file-converter.git
git fetch origin master
git reset origin/master
```

`git reset origin/master` is mixed mode: it establishes the remote commit as `HEAD` and updates the index while leaving the working tree unchanged. Do not use `--hard`, checkout paths, or remove untracked files.

- [ ] **Step 2: Audit the baseline**

Run:

```powershell
git status --short
git diff --stat
git ls-files --others --exclude-standard
```

Expected: local project work appears as modified or untracked relative to `origin/master`; no workspace file disappears. Record the remote baseline commit in the final QA report.

---

### Task 0.5: Import The Existing Project And Create An Isolated Worktree

**Files:**
- Create: `.gitignore`
- Stage: current HarmonyOS source, scripts, documentation and approved QA evidence
- Exclude: generated build output, IDE state, dependency caches and local logs

- [ ] **Step 1: Create the protected import branch**

Run: `git switch -c codex/project-import`

Expected: the dirty working tree is preserved on a named branch; `master` and `origin/master` remain at `0e00a98`.

- [ ] **Step 2: Add the repository ignore rules**

Create `.gitignore` with exactly these project-local exclusions:

```gitignore
.hvigor/
.idea/
.worktrees/
oh_modules/
entry/build/
entry/.cxx/
local.properties
*.log
*.tmp
```

Do not ignore `docs/qa/`, `entry/src/`, `AppScope/`, `scripts/` or project configuration.

- [ ] **Step 3: Audit and commit the existing baseline**

Run the full test suite, type check, standard gate and HarmonyOS build. Then stage `.gitignore`, project source, scripts, documentation, root configuration and QA evidence. Inspect `git status --short` before committing; no ignored directory may appear in the staged list.

Commit with: `git commit -m "chore: import HarmonyOS converter project"`

Expected: one baseline commit containing the existing working application and its evidence, with generated/cache directories excluded.

- [ ] **Step 4: Create the isolated UI worktree**

Verify `.worktrees/` is ignored with `git check-ignore -q .worktrees`. Then run:

```powershell
git worktree add .worktrees/reference-ui-redesign -b codex/reference-ui-redesign
```

Expected: the worktree starts from the project-import commit on branch `codex/reference-ui-redesign`. All remaining UI tasks run from the repository-relative `.worktrees/reference-ui-redesign` directory.

---

### Task 1: Visual Tokens And Baseline Contract

**Files:**
- Create: `scripts/test-ui-design-system-contract.js`
- Create: `entry/src/main/ets/common/UiConstants.ets`
- Modify: `entry/src/main/resources/base/element/color.json`

- [ ] **Step 1: Write the failing design-system contract**

Create a Node test that reads `color.json` and `UiConstants.ets` and asserts these exact resources/constants exist:

```js
const requiredColors = [
  'page_background', 'surface_primary', 'surface_secondary',
  'brand_primary', 'brand_strong', 'text_primary', 'text_secondary',
  'text_tertiary', 'text_disabled', 'border_subtle',
  'control_selected', 'control_disabled', 'success', 'error'
]
const requiredConstants = [
  'PAGE_PADDING_PHONE', 'PAGE_PADDING_LARGE', 'CONTENT_MAX_WIDTH',
  'CARD_RADIUS', 'CONTROL_RADIUS', 'ACTION_HEIGHT', 'TOUCH_MIN_HEIGHT',
  'BREAKPOINT_MEDIUM', 'BREAKPOINT_LARGE'
]
```

The test parses `color.json`, checks each color name, reads `UiConstants.ets`, and throws a named error for every missing constant.

- [ ] **Step 2: Run the test and verify RED**

Run: `node scripts/test-ui-design-system-contract.js`

Expected: FAIL because the new resource names and constants do not exist.

- [ ] **Step 3: Implement the token layer**

Create `UiConstants.ets` with this public API:

```ts
export class UiConstants {
  static readonly PAGE_PADDING_PHONE: number = 16
  static readonly PAGE_PADDING_LARGE: number = 24
  static readonly CONTENT_MAX_WIDTH: number = 840
  static readonly CARD_RADIUS: number = 14
  static readonly CONTROL_RADIUS: number = 10
  static readonly ACTION_HEIGHT: number = 44
  static readonly TOUCH_MIN_HEIGHT: number = 44
  static readonly BREAKPOINT_MEDIUM: number = 600
  static readonly BREAKPOINT_LARGE: number = 840
  static readonly HEADER_HEIGHT: number = 56
  static readonly SECTION_GAP: number = 16
}
```

Update `color.json` to use the approved palette: `#F7F9FD`, `#FFFFFF`, `#FAFCFF`, `#1769FF`, `#0A56E8`, `#101522`, `#5F6F8F`, `#8B98B2`, `#A8B1C2`, `#DFE7F3`, `#EAF1FF`, `#EEF2F8`, `#31B878`, `#E35D68`. Keep compatibility aliases for existing resource names until every page is migrated.

- [ ] **Step 4: Verify GREEN and compile**

Run:

```powershell
node scripts/test-ui-design-system-contract.js
node scripts/_type_check.js
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-harmony.ps1
```

Expected: contract passes, `TYPE OK`, HarmonyOS build succeeds.

---

### Task 2: Cohesive 3D Asset Family

**Files:**
- Create: the 18 PNG resources listed in File Map
- Create: `scripts/test-ui-assets-contract.js`
- Modify: `entry/src/main/resources/base/media/app_icon.png`

- [ ] **Step 1: Write the failing asset contract**

The Node test reads PNG IHDR bytes directly and asserts every required asset exists, is a valid PNG, has width and height at least 192px, and is larger than 2 KB. Assert `app_icon.png` is at least 512x512.

- [ ] **Step 2: Run the test and verify RED**

Run: `node scripts/test-ui-assets-contract.js`

Expected: FAIL listing missing resources and the current 48x48 placeholder icon.

- [ ] **Step 3: Generate and normalize the assets**

Use the `imagegen` skill with the user-provided reference image as style guidance. Generate original blue-white 3D icons with transparent backgrounds using this common direction:

```text
Polished translucent blue-and-white 3D utility icon, soft cool studio light,
subtle cobalt rim light, rounded geometry, slight isometric view, transparent
background, centered object, no words, no letters, no watermark, consistent
with a premium offline file-converter mobile app.
```

Generate the home hero as a document tile suspended inside two thin blue orbital rings. Generate the PDF hero as layered blue PDF-like folders without embedded text. Generate the globe as a pale blue-white hemisphere. Normalize icon canvases to 512x512 and hero canvases to 1024x512 without stretching.

- [ ] **Step 4: Verify asset quality**

Run: `node scripts/test-ui-assets-contract.js`

Then inspect all assets with a contact sheet. Reject blank, cropped, inconsistent, text-bearing or opaque-background icons before using them.

---

### Task 3: Shared ArkUI Presentation Components

**Files:**
- Create: the nine component files listed in File Map
- Modify: `entry/src/main/ets/components/FormatSelector.ets`
- Modify: `scripts/test-ui-design-system-contract.js`

- [ ] **Step 1: Extend the contract and verify RED**

Assert all nine components exist, import `UiConstants`, and use resource colors instead of raw hex values. Assert `PrimaryActionButton` accepts `label`, `enabled`, `loading`, and `onTap`; `FilePickerPanel` accepts `title`, `description`, `asset`, `buttonLabel`, `enabled`, and `onPick`; `SegmentedControl` and `OptionChipGroup` accept typed item arrays and callbacks.

Run: `node scripts/test-ui-design-system-contract.js`

Expected: FAIL because the components do not exist.

- [ ] **Step 2: Implement stable component APIs**

Use these public interfaces:

```ts
export interface SegmentItem { key: string; label: string; enabled: boolean }
export interface ChipItem { key: string; label: string; enabled: boolean; developing: boolean }
export interface ToolListData { key: string; title: string; description: string; asset: Resource; enabled: boolean }
```

Every component uses fixed minimum heights, explicit padding and stable widths. `PrimaryActionButton` renders the selected blue treatment only when enabled and a gray-blue background when disabled. `OptionChipGroup` renders `功能正在开发` inside disabled items and returns before invoking callbacks.

- [ ] **Step 3: Migrate FormatSelector without changing behavior**

Make `FormatSelector` adapt `FormatInfo[]` into `ChipItem[]` and delegate presentation to `OptionChipGroup`. Preserve `nativeSupported`, selected value, global disabled state and `selectCallback` behavior.

- [ ] **Step 4: Verify GREEN and build**

Run the design-system contract, existing disabled-format contract, type check and HarmonyOS build. Expected: all pass.

---

### Task 4: Reference Home Screen

**Files:**
- Create: `scripts/test-home-reference-ui-contract.js`
- Modify: `entry/src/main/ets/pages/Index.ets`
- Use: eight `ui_tool_*.png` assets and `ui_hero_home.png`

- [ ] **Step 1: Write the failing home contract**

Assert `Index.ets` uses `FunctionTile`, `ui_hero_home`, eight media icons, a two-column phone grid, a four-column large breakpoint, and the existing two tabs. Assert it contains no emoji icon literals and still advertises only verified capabilities.

- [ ] **Step 2: Run and verify RED**

Run: `node scripts/test-home-reference-ui-contract.js`

Expected: FAIL because the page still uses emoji and a fixed two-column grid.

- [ ] **Step 3: Rebuild Index layout**

Keep `functionCards` routes and capability descriptions, replace `iconText` with `Resource`, implement the `154vp` hero, responsive 2/4-column grid, `74vp` tiles and fixed bottom tabs. Use `onAreaChange` to derive phone/large layout state without computing inside `@Builder` blocks.

- [ ] **Step 4: Device checkpoint**

Build, install on phone and 2in1, capture `docs/qa/reference-home-phone.jpeg` and `docs/qa/reference-home-2in1.jpeg`. Confirm the phone composition matches the first reference panel and the 2in1 uses four columns without oversized empty cards.

---

### Task 5: Image And Document Conversion Pages

**Files:**
- Create: `scripts/test-conversion-reference-ui-contract.js`
- Modify: `entry/src/main/ets/pages/ImageConvertPage.ets`
- Modify: `entry/src/main/ets/pages/DocumentConvertPage.ets`

- [ ] **Step 1: Write the failing conversion-page contract**

Assert both pages use `AppPageHeader`, `FilePickerPanel`, `FormatSelector`, `PrimaryActionButton` and `StatusPanel`. Assert the image page retains quality, width/height and save behavior; assert the document page retains dynamic targets and UTF-8/GBK/UTF-16LE source encoding.

- [ ] **Step 2: Run and verify RED**

Run: `node scripts/test-conversion-reference-ui-contract.js`

Expected: FAIL because shared reference components are not yet used.

- [ ] **Step 3: Rebuild both layouts**

Match reference panels two and three: compact title bar, large picker panel, grouped chips, image quality slider or document encoding section, and one full-width action button. Keep all existing async methods and state transitions unchanged.

- [ ] **Step 4: Regression checkpoint**

Run document/image contract suites and complete a phone PNG→JPG and CSV→JSON device conversion. Confirm output dimensions/content remain valid, then capture both pages on phone and 2in1.

---

### Task 6: Audio And Video Conversion Pages

**Files:**
- Modify: `entry/src/main/ets/pages/AudioConvertPage.ets`
- Modify: `entry/src/main/ets/pages/VideoConvertPage.ets`
- Modify: `scripts/test-conversion-reference-ui-contract.js`

- [ ] **Step 1: Extend the contract and verify RED**

Assert both pages use the same conversion shell and preserve M4A/MP4 execution allowlists. Assert AAC/MP3/FLAC/WAV/OGG and video MP3 remain gray developing items.

- [ ] **Step 2: Implement inferred reference layouts**

Use the document/image page composition with audio/video-specific picker assets, bitrate or output controls, progress and result panels. Do not advertise formats outside current verified paths.

- [ ] **Step 3: Regression checkpoint**

Run all audio/video contracts, build, and verify MP4→M4A plus MOV→MP4 on 2in1. Capture normal empty, selected and success states.

---

### Task 7: PDF And Archive/Timezone Pages

**Files:**
- Create: `scripts/test-tools-reference-ui-contract.js`
- Modify: `entry/src/main/ets/pages/PdfToolsPage.ets`
- Modify: `entry/src/main/ets/pages/ArchiveTimePage.ets`

- [ ] **Step 1: Write the failing tools contract**

Assert PDF list mode uses `ToolListItem` and `ui_hero_pdf`; archive/time uses `SegmentedControl`, `FilePickerPanel`, `PrimaryActionButton`, and `ui_globe`. Assert ZIP is enabled while 7Z/TAR.GZ/RAR are disabled and labeled developing.

- [ ] **Step 2: Run and verify RED**

Run: `node scripts/test-tools-reference-ui-contract.js`

Expected: FAIL because the pages still use bespoke rows and selectors.

- [ ] **Step 3: Rebuild both pages**

Match reference panels four, five and six. Preserve all five supported PDF workflows, ZIP compression/decompression, CST→EST calculations, invalid minute validation and recursive extraction behavior.

- [ ] **Step 4: Regression checkpoint**

Run PDF contracts, build, test TXT→PDF, PDF→Markdown, ZIP compress/extract, `01:30` CST→EST and invalid minute `60`. Capture phone/2in1 screenshots.

---

### Task 8: Unit Converter And Image Tools

**Files:**
- Modify: `entry/src/main/ets/pages/UnitConverterPage.ets`
- Modify: `entry/src/main/ets/pages/ImageToolsPage.ets`
- Modify: `scripts/test-tools-reference-ui-contract.js`

- [ ] **Step 1: Extend the contract and verify RED**

Assert unit page uses a responsive category grid, `MetricInputField` and `OptionChipGroup`; image tools uses `SegmentedControl`, `FilePickerPanel`, `MetricInputField` and `PrimaryActionButton`. Assert all existing categories and image operations remain present.

- [ ] **Step 2: Rebuild both pages**

Match reference panels seven and eight. Use fixed category tile dimensions, stable field grids, explicit selected states and no nested decorative cards.

- [ ] **Step 3: Regression checkpoint**

Verify `1 °C = 33.8 °F`, image resize dimensions, crop bounds and color extraction value. Capture phone/2in1 screenshots for each tab.

---

### Task 9: About And Cross-Page Responsive Contract

**Files:**
- Create: `scripts/test-reference-ui-responsive-contract.js`
- Modify: `entry/src/main/ets/pages/AboutPage.ets`
- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `entry/src/main/ets/pages/ImageConvertPage.ets`
- Modify: `entry/src/main/ets/pages/DocumentConvertPage.ets`
- Modify: `entry/src/main/ets/pages/AudioConvertPage.ets`
- Modify: `entry/src/main/ets/pages/VideoConvertPage.ets`
- Modify: `entry/src/main/ets/pages/ImageToolsPage.ets`
- Modify: `entry/src/main/ets/pages/ArchiveTimePage.ets`
- Modify: `entry/src/main/ets/pages/UnitConverterPage.ets`
- Modify: `entry/src/main/ets/pages/PdfToolsPage.ets`

- [ ] **Step 1: Write the failing responsive contract**

Assert all independent pages retain `NavigationMode.Stack`, use a shared maximum-width container or responsive layout state, and contain no placeholder email/domain. Assert every page uses new surface/background resources and no emoji presentation icons.

- [ ] **Step 2: Run and verify RED**

Run: `node scripts/test-reference-ui-responsive-contract.js`

Expected: FAIL until every page is migrated.

- [ ] **Step 3: Rebuild About and close cross-page gaps**

Use the home visual language for About, keep only verifiable offline privacy and version text, and remove unreachable placeholder contact data. Apply safe-area, max-width and keyboard/scroll behavior consistently across all pages.

- [ ] **Step 4: Verify GREEN**

Run every `test-*.js`, type check, standard gate and full build. Expected: zero failures.

---

### Task 10: Visual And Functional Acceptance

**Files:**
- Create: `docs/qa/2026-08-02-reference-ui-regression.md`
- Modify: `design.md`
- Modify: `design-qa.md`
- Modify: `docs/开发文档.md`
- Modify: `changes.md`
- Modify: `tasks.md`

- [ ] **Step 1: Prepare reference crops**

Crop the user-provided 1450x1092 composite into eight reference panels under `docs/qa/reference-ui/` without modifying the original clipboard file.

- [ ] **Step 2: Capture all phone states**

Install the latest HAP and capture home, image, document, PDF, archive, timezone, unit and image-tools screens at the phone viewport. Also capture inferred audio, video, about, loading, success, error and disabled states.

- [ ] **Step 3: Capture all 2in1 states**

Use live `dumpLayout` bounds before every click because the 2in1 window can move. Verify no overlap, truncation, automatic split navigation or blank asset canvas.

- [ ] **Step 4: Run final functional matrix**

Re-run representative document, image, audio, video, PDF, ZIP, time, unit and image-tool workflows. Validate output headers, tracks, hashes, dimensions or pixels as applicable.

- [ ] **Step 5: Run final gates**

```powershell
Get-ChildItem .\scripts\test-*.js | Sort-Object Name | ForEach-Object { node $_.FullName }
node .\scripts\_type_check.js
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check-standard.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-harmony.ps1
```

Expected: all contract tests pass, `TYPE OK`, static gate reports `PASSED (0 warning)`, and `BUILD SUCCESSFUL` produces the unsigned HAP.

- [ ] **Step 6: Record evidence and close the task**

The QA report lists each screen and workflow as `passed`, `fixed` or `blocked`, references screenshots/layout dumps, and explicitly retains tablet device coverage plus release signing as external gaps. Update T-20260802-005 to `done` only after these checks pass.

---

### Task 11: Commit And Push The Verified Result

**Files:**
- Stage: only project source, tests, approved visual resources and QA/documentation evidence
- Exclude: `.hvigor/`, `entry/build/`, IDE state, temporary layout probes and secrets

- [ ] **Step 1: Inspect the final change set**

Run:

```powershell
git status --short
git diff --check
git diff --stat
git fetch origin master
git rev-parse origin/master
```

Expected: no whitespace errors, no credentials or build cache staged, and remote `master` is still an ancestor of the local work.

- [ ] **Step 2: Stage and commit**

Run:

```powershell
git add AppScope entry/src scripts docs README.md AGENTS.md tasks.md changes.md design.md design-qa.md build-profile.json5 hvigorfile.ts oh-package.json5 oh-package-lock.json5
git status --short
git commit -m "feat: rebuild converter UI from reference design"
```

Before committing, inspect the staged list and unstage any build output, IDE file, credential, private key or temporary probe. Expected: one commit containing the verified UI redesign and its tests/evidence.

- [ ] **Step 3: Rebase only if the remote advanced**

If `origin/master` changed after the baseline fetch, run `git rebase origin/master`, resolve conflicts without discarding local or remote work, and rerun all final gates. Do not force-push.

- [ ] **Step 4: Push normally and verify**

Run:

```powershell
git push origin master
git status --short
git log -1 --oneline
```

Expected: ordinary fast-forward push succeeds, the working tree contains no unintended staged changes, and the final commit hash is reported to the user. If authentication is unavailable, stop after the local commit and report the exact authentication blocker without exposing credentials.
