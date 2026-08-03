# Home And About Reference UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the HarmonyOS home and about tabs to match the two approved phone references while preserving all existing routes and offline behavior.

**Architecture:** Keep `Index.ets` as the tab owner, reuse `FunctionTile` for all eight routes, and keep `AboutPage.ets` visually consistent for direct route use. Add four bundled privacy icon assets and a Node contract that checks the observable UI source contract before device verification.

**Tech Stack:** HarmonyOS API 22, ArkTS, ArkUI, Node contract tests, HDC UI test.

---

### Task 1: Reference Contract And Assets

**Files:**
- Create: `scripts/test-home-about-v2-reference-ui-contract.js`
- Create: `entry/src/main/resources/base/media/ui_privacy_local.png`
- Create: `entry/src/main/resources/base/media/ui_privacy_offline.png`
- Create: `entry/src/main/resources/base/media/ui_privacy_storage.png`
- Create: `entry/src/main/resources/base/media/ui_privacy_access.png`

- [ ] Write a contract asserting the approved title sizes, 96vp tile height, icon backdrop, four unique privacy resources, and selected-tab underline.
- [ ] Run `node scripts/test-home-about-v2-reference-ui-contract.js` and confirm it fails because the v2 structure is absent.
- [ ] Copy the approved source references into `docs/qa/reference-ui-v2/` and deterministically crop the four privacy icons.

### Task 2: Home And About ArkUI

**Files:**
- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `entry/src/main/ets/pages/AboutPage.ets`
- Modify: `entry/src/main/ets/components/FunctionTile.ets`

- [ ] Update home title, hero sizing, grid spacing, tile typography and rounded bottom navigation to the approved reference.
- [ ] Update embedded and standalone about layouts to share the icon, four privacy rows, dividers, version line and responsive width.
- [ ] Run the new contract and all existing `scripts/test-*.js` files; expect all to pass.

### Task 3: Build And Device QA

**Files:**
- Modify: `tasks.md`
- Modify: `changes.md`
- Modify: `design.md`
- Modify: `design-qa.md`
- Modify: `docs/开发文档.md`
- Create: `docs/qa/2026-08-03-home-about-reference-ui.md`

- [ ] Run `node scripts/_type_check.js`, `scripts/check-standard.ps1`, and `scripts/build-harmony.ps1`.
- [ ] Install the same HAP on phone and 2in1, verify the home/about tab transition, and capture both states.
- [ ] Record exact evidence and remaining environmental limitations, mark the task complete only after gates pass, then commit and push normally.
