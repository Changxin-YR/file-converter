# App Icon Replacement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace every user-visible application icon with the supplied square PNG and verify HarmonyOS packaging and device rendering.

**Architecture:** Keep existing `$media:app_icon` and `$media:ui_about_app_icon` references unchanged. Produce three deterministic PNG derivatives from the single supplied source, then validate signatures, dimensions, source identity and runtime display.

**Tech Stack:** HarmonyOS Stage model resources, PNG, Node.js contract tests, Hvigor, HDC.

---

### Task 1: Add icon resource contract

**Files:**
- Create: `scripts/test-app-icon-contract.js`

- [ ] Write a contract that checks all three PNG files exist, have expected dimensions, and match derivatives of the approved source image.
- [ ] Run `node scripts/test-app-icon-contract.js` and confirm RED because existing resources do not match the new source.

### Task 2: Replace application icons

**Files:**
- Modify: `AppScope/resources/base/media/app_icon.png`
- Modify: `entry/src/main/resources/base/media/app_icon.png`
- Modify: `entry/src/main/resources/base/media/ui_about_app_icon.png`

- [ ] Resize the approved source to 1024, 512 and 250 pixels with high-quality interpolation.
- [ ] Run `node scripts/test-app-icon-contract.js` and confirm GREEN.
- [ ] Run all `scripts/test-*.js` and `node scripts/_type_check.js`.

### Task 3: Build and device verification

**Files:**
- Create: `docs/qa/2026-08-03-app-icon-replacement.md`
- Create: `docs/qa/2026-08-03-app-icon-phone.jpeg`
- Create: `docs/qa/2026-08-03-app-icon-2in1.jpeg`
- Modify: `tasks.md`
- Modify: `changes.md`
- Modify: `design.md`
- Modify: `design-qa.md`
- Modify: `docs/开发文档.md`

- [ ] Run `scripts/check-standard.ps1` and `scripts/build-harmony.ps1`.
- [ ] Install the same HAP on phone and 2in1, launch the app, and capture icon evidence.
- [ ] Record verification evidence and mark `T-20260803-003` done.
- [ ] Commit, merge to `master`, verify, and push to `origin/master`.
