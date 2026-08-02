# Disabled Format Status Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make every unsupported format visibly say "功能正在开发" while remaining disabled.

**Architecture:** Keep capability truth in `FormatInfo.nativeSupported`. Render the status inside the shared `FormatSelector`, so image, audio, and video pages cannot drift apart; preserve the existing no-op click guard.

**Tech Stack:** HarmonyOS ArkTS/ArkUI, Node.js source-contract tests.

---

### Task 1: Add The Failing Contract

**Files:**
- Create: `scripts/test-disabled-format-status-contract.js`
- Test: `entry/src/main/ets/components/FormatSelector.ets`

- [ ] **Step 1: Write the failing test**

Read `FormatSelector.ets` and assert that unsupported formats render the exact text `功能正在开发`, use `nativeSupported` to determine the state, retain disabled opacity, and return before invoking `selectCallback`.

- [ ] **Step 2: Run test to verify it fails**

Run: `node scripts/test-disabled-format-status-contract.js`

Expected: FAIL because the status text is not rendered yet.

### Task 2: Render The Shared Status

**Files:**
- Modify: `entry/src/main/ets/components/FormatSelector.ets`
- Test: `scripts/test-disabled-format-status-contract.js`

- [ ] **Step 1: Write minimal implementation**

Inside each selector chip, keep the format name and add a small secondary `Text('功能正在开发')` only when `format.nativeSupported` is false. Do not change the callback or capability matrix.

- [ ] **Step 2: Run test to verify it passes**

Run: `node scripts/test-disabled-format-status-contract.js`

Expected: `DISABLED FORMAT STATUS CONTRACT PASSED`.

- [ ] **Step 3: Run all regression tests and build gates**

Run all `scripts/test-*.js`, `node scripts/_type_check.js`, `scripts/check-standard.ps1`, and `scripts/build-harmony.ps1`. Expect zero failures and a generated unsigned HAP.

### Task 3: Device And Documentation Regression

**Files:**
- Modify: `docs/qa/2026-08-02-developed-functions-regression.md`
- Modify: `design-qa.md`
- Modify: `changes.md`
- Modify: `tasks.md`

- [ ] **Step 1: Install the rebuilt HAP on phone and 2in1**

Verify disabled formats visibly show `功能正在开发`, empty conversion buttons remain disabled, and the previously verified timezone and unit results still render.

- [ ] **Step 2: Record evidence and final status**

Document automated results, device actions, artifact checks, and external limitations. Mark the task `done` only after every required verification command passes.
