---
name: release-manager
description: End-to-end workflow to audit, build, and publish releases for MultiCounter. Use when preparing a new version release, verifying split APK binary sizes, tagging releases, or drafting release notes.
---

# Release Manager Workflow

This skill outlines the standard release lifecycle for MultiCounter.

---

## 🚀 Release Lifecycle Steps

### Step 1: Version Bumping
1. Open `pubspec.yaml` and increment the version string:
   ```yaml
   version: 1.0.1+2 # <semantic-version>+<build-number>
   ```
2. Verify that `versionCode` in Android is automatically driven by the build number (`+2`).

---

### Step 2: Quality Sign-Off
Execute all local quality checks before starting the release build:
```powershell
flutter analyze
flutter test
```

---

### Step 3: Build Release Split APKs
Run the release build command:
```powershell
flutter build apk --split-per-abi --release --no-tree-shake-icons
```

---

### Step 4: Verify APK Sizes (<25MB Budget)
Check the file sizes of the generated APKs in `build/app/outputs/flutter-apk/`:
```powershell
Get-ChildItem build\app\outputs\flutter-apk\*.apk | Select-Object Name, @{Name="SizeMB"; Expression={[math]::round($_.Length / 1MB, 2)}}
```

**Threshold**:
- Each APK **must** be under **25MB**. If any APK exceeds 25MB, audit assets and dependencies before proceeding.

---

### Step 5: Draft Release Notes & Tag
Generate release notes highlighting:
- 🌟 **New Features**: Event selection, duplication, color-blind modes, etc.
- 🛠 **Bug Fixes**: Widget colon alignment, spacing, label visibility.
- 📦 **Download Links**: Split APKs by architecture (`arm64-v8a`, `armeabi-v7a`, `x86_64`).
