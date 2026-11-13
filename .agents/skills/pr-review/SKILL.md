---
name: pr-review
description: Comprehensive workflow to review pull requests, feature branches, and code changes in MultiCounter. Use when the user asks to review a PR, check changes before merging, inspect git diffs, or verify code quality.
---

# PR Review Workflow

This skill guides you through conducting a thorough, multi-phase Pull Request review for the **MultiCounter** project.

---

## 🛠 Step-by-Step Review Procedure

### Step 1: Inspect Changed Files & Git Diff
1. Check changed files against the target branch (default `origin/main`):
   ```powershell
   git status
   git diff origin/main...HEAD --stat
   ```
2. Review the detailed diff for key files:
   - Flutter logic: `lib/features/`, `lib/models/`, `lib/services/`
   - Android native widget: `android/app/src/main/res/layout/multicounter_widget.xml`, `MultiCounterWidgetProvider.kt`
   - App build configs: `pubspec.yaml`, `build.gradle.kts`

---

### Step 2: Run Code Quality & Verification Gates
Run the automated verification suite:

1. **Static Analysis**:
   ```powershell
   flutter analyze
   ```
   *Requirement*: 0 errors, 0 warnings.

2. **Automated Unit & Widget Tests**:
   ```powershell
   flutter test
   ```
   *Requirement*: All tests must pass. Check that new features include dedicated tests in `test/`.

---

### Step 3: Architecture & Invariant Checklist

Evaluate the changes against project rules:

- [ ] **Android AppWidget Compatibility**:
  - RemoteViews classes must be whitelisted (`LinearLayout`, `TextView`, `ImageView`).
  - `android:baselineAligned="false"` must be set on horizontal LinearLayouts.
  - Spacers in `widget_labels_container` must have fixed width (`12dp` or `14dp`) and `1dp` height without text.
  - Colons (`:`) and middle dots (`·`) must remain vertically centered with digits.
- [ ] **In-App Studio Preview Match**:
  - Does `_WidgetPreview` in `widget_studio_screen.dart` replicate the native widget layout 1:1?
- [ ] **State & Design Isolation**:
  - Confirm new counters do not inherit custom designs unless duplicated via clone.
- [ ] **Accessibility**:
  - Does the UI maintain high contrast and support the color-blind modes?
- [ ] **Battery & Alarms**:
  - Are alarm intervals safe (default 60s)? Are sub-minute alarms gated with battery warnings?

---

### Step 4: Generate Structured PR Review Report

Produce the review report following this format:

```markdown
## 🔍 Pull Request Review Report

### 🚦 Verdict: [APPROVED | CHANGES REQUESTED | COMMENT]

### 📋 Overview of Changes
- Summary of what this PR accomplishes.

### 🌟 Positive Highlights
- Clean architectural patterns, solid tests, good UX.

### ⚠️ Issues & Required Fixes (if any)
- **`path/to/file.dart#L123`**: Explanation of issue with recommended diff fix.

### 🧪 Verification Status
- Static Analysis (`flutter analyze`): PASS (0 issues)
- Test Suites (`flutter test`): PASS (16/16)
- Widget Parity: Verified
```
