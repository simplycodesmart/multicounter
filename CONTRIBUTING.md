# Contributing to MultiCounter ⏱️✨

First off, thank you for considering contributing to **MultiCounter**! 🚀 It's open-source contributors like you that make MultiCounter an awesome, lightweight, and community-driven tool for tracking life events, habits, and goals.

Whether you're fixing a typo, designing new widget styles, proposing a feature, or optimizing performance, your help is warmly welcomed.

---

## 📑 Table of Contents

- [Code of Conduct](#-code-of-conduct)
- [How Can I Contribute?](#-how-can-i-contribute)
  - [Reporting Bugs](#-reporting-bugs)
  - [Suggesting Features & Enhancements](#-suggesting-features--enhancements)
  - [Submitting a Pull Request](#-submitting-a-pull-request)
- [🛠️ Development Setup](#️-development-setup)
- [🏗️ Project Architecture](#️-project-architecture)
- [⚡ The Minimal APK & Zero-Bloat Philosophy](#-the-minimal-apk--zero-bloat-philosophy)
- [📏 Code Standards & Verification](#-code-standards--verification)
- [💬 Commit Message Conventions](#-commit-message-conventions)
- [🌟 Support & Stargazers](#-support--stargazers)

---

## 🤝 Code of Conduct

We are committed to providing a welcoming, inclusive, and harassment-free environment for everyone. Please be respectful, constructive, and kind in all issues, pull requests, and discussions.

---

## 💡 How Can I Contribute?

### 🐛 Reporting Bugs

If you find a bug or unexpected behavior:
1. Check existing [GitHub Issues](https://github.com/simplycodesmart/multicounter/issues) to ensure it hasn't already been reported.
2. If it's a new issue, open a bug report detailing:
   - Your Android version and device model (e.g., Pixel 8, Android 14).
   - Clear steps to reproduce the issue.
   - Expected vs. actual behavior.
   - Screenshots or logcat outputs if relevant.

### 💡 Suggesting Features & Enhancements

Have an idea for a new widget layout, accessibility preset, or timer repeat pattern?
1. Open an issue under **Feature Request**.
2. Describe your use case and why it would be helpful to users.
3. If proposing a visual change, mockups or wireframes are always appreciated!

### 📥 Submitting a Pull Request

1. **Fork** the repository and create a branch from `main`:
   ```bash
   git checkout -b feat/my-awesome-feature
   ```
2. Keep changes focused and atomic. Avoid large refactors alongside bug fixes.
3. Ensure the project analyzes with **0 issues** and all tests pass:
   ```bash
   flutter analyze
   flutter test
   ```
4. Push to your fork and submit a **Pull Request** targeting `main` with a clear description of the change.

---

## 🛠️ Development Setup

### Prerequisites

- **Flutter SDK**: 3.16+ (Dart 3.x) — [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Java**: JDK 17 (recommended for modern Android Gradle builds)
- **Android Studio / Android SDK**: API Level 26+ (Android 8.0+) for native launcher widget pinning.

### Quick Start

```bash
# 1. Clone your fork
git clone https://github.com/<your-username>/multicounter.git
cd multicounter

# 2. Install dependencies
flutter pub get

# 3. Run on an Android device or emulator
flutter run

# 4. Run tests
flutter test
```

---

## 🏗️ Project Architecture

MultiCounter follows a clean, feature-driven structure powered by **Flutter Riverpod**:

```
lib/
├── core/                  # Design system, themes & color blindness palettes
│   └── theme/app_theme.dart
├── features/
│   ├── counters/          # Counter list, creation, editor, event presets
│   ├── widgets/           # Widget Studio, live customization canvas, preview
│   └── settings/          # Theming, accessibility, data backup & export
├── models/                # Immutable models (CounterModel, repeat intervals)
├── providers/             # Riverpod notifiers & state management
├── services/              # MethodChannel native bridge & notification scheduler
└── shared/                # Accessible reusable widgets (CounterCard, chips)

android/
└── app/src/main/
    ├── kotlin/com/multicounter/multicounter/
    │   ├── MainActivity.kt               # MethodChannel handler & widget intent router
    │   ├── MultiCounterWidgetProvider.kt # Native AppWidgetProvider with dynamic font scaling
    │   └── WidgetConfigureActivity.kt    # Launcher widget configuration picker
    └── res/layout/
        └── multicounter_widget.xml       # Native RemoteViews XML layout with auto-size text
```

---

## ⚡ The Minimal APK & Zero-Bloat Philosophy

MultiCounter's mission is to be the **fastest, cleanest, and most lightweight counter app** on Android:

- ❌ **No Heavy Native C Binaries**: Avoid dependencies that bundle massive unneeded `.so` dynamic libraries (e.g., SQLite C bindings when `SharedPreferences` handles JSON safely).
- ❌ **No Bloat SDKs**: No intrusive telemetry, analytics, ad networks, or background battery drains.
- ✅ **R8 Minification Enabled**: Proguard rules strip unused code and resources (`isMinifyEnabled = true`, `isShrinkResources = true`).
- ✅ **Target APK Size**: Every ABI split APK (`arm64-v8a`) must remain strictly under **25MB**.

---

## 📏 Code Standards & Verification

Before submitting your code:

```bash
# 1. Format code nicely
dart format lib test

# 2. Verify static analysis (must report zero warnings/errors)
flutter analyze

# 3. Run all automated unit and model tests
flutter test

# 4. (Optional) Verify release build compiles cleanly
flutter build apk --split-per-abi --release --no-tree-shake-icons
```

---

## 💬 Commit Message Conventions

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

- `feat:` A new user-facing feature (e.g., `feat(widget): add battery saver refresh interval selector`)
- `fix:` A bug fix (e.g., `fix(notifications): ensure exact alarm permission fallback`)
- `perf:` A performance or APK size optimization (e.g., `perf(build): enable R8 resource shrinking`)
- `docs:` Documentation improvements (e.g., `docs(readme): add interactive feature badges`)
- `style:` Formatting or cosmetic changes without code logic updates
- `test:` Adding or updating tests

---

## 🌟 Support & Stargazers

If you love MultiCounter, don't forget to **give the project a star ⭐ on GitHub** and share it with friends! Your support drives new updates and helps others find a fast, privacy-respecting counter app.
