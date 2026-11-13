# MultiCounter Developer & Agent Guidelines

Welcome to the MultiCounter project! This document outlines coding standards, architectural guidelines, and validation rules for human developers and autonomous AI coding agents working in this repository.

---

## 🏗 Project Architecture & Tech Stack

MultiCounter is a high-performance, battery-friendly, cross-platform event & tally counter application built with **Flutter** and **native Android AppWidgets**.

- **Frontend / UI**: Flutter (Dart 3.x) with Material 3 styling and high-contrast dark theme.
- **State Management**: `Provider` with clean domain models (`CounterModel`).
- **Persistence**: `SharedPreferences` with isolated keys per counter (`multicounter.widget_studio.v1.counter.<id>`).
- **Native Android Widget**:
  - `MultiCounterWidgetProvider.kt`: Kotlin `AppWidgetProvider` managing updates, alarms, and options.
  - `res/layout/multicounter_widget.xml`: Clean 2-row layout (`widget_digits_row` + `widget_labels_container`).
  - `MainActivity.kt`: Handles widget configuration and pinning via Flutter MethodChannels (`multicounter/widget_config`).
- **Notifications**: `flutter_local_notifications` (`NotificationService`).

---

## 🚨 Critical Engineering Invariants

Whenever making changes to this codebase, you **must** adhere to these invariants:

### 1. Android Native Widget (`RemoteViews`) Constraints
- **Allowed Views**: Only use whitelisted Android `RemoteViews` classes (`LinearLayout`, `TextView`, `ImageView`, `Button`). Do **not** use custom views, arbitrary `<View>`, or unapproved layouts.
- **Fixed Separator Widths**: Colons and dot separators in Row 1 have fixed widths (`12dp` for `widget_sep_days`, `14dp` for colons). Spacers in Row 2 must match the identical widths with `1dp` height and empty text.
- **No Baseline Shifting**: Always maintain `android:baselineAligned="false"` on `widget_digits_row` and `widget_labels_container`. Never set font size on spacers in Row 2.
- **Preview 1:1 Parity**: Any changes made to [`multicounter_widget.xml`](file:///f:/project/multicounter/android/app/src/main/res/layout/multicounter_widget.xml) must be mirrored 1:1 in [`lib/features/widgets/widget_studio_screen.dart`](file:///f:/project/multicounter/lib/features/widgets/widget_studio_screen.dart) (`_WidgetPreview`).

### 2. State & Design Isolation
- Each counter's widget styling (background color, accent, font size, layout, unit visibility) is stored independently under its own storage key.
- Duplicating/cloning a counter copies the design, but creating a fresh counter must **never** inherit another counter's custom design.

### 3. Battery Efficiency & Refresh Cadence
- Home screen widgets must not poll aggressively.
- Default refresh is 1 minute (`60,000ms`). Sub-minute intervals (e.g. 1s) must display background battery drain warnings to the user.

### 4. Binary Footprint (<25MB)
- MultiCounter must remain lightweight and fast.
- Releases are built using split APKs (`flutter build apk --split-per-abi --release --no-tree-shake-icons`).
- ProGuard rules (`android/app/proguard-rules.pro`) strip unused symbols. Each ABI APK must stay below 25MB.

---

## 🧪 Testing & Verification Protocol

Before submitting or pushing any changes:
1. Run `flutter analyze` — 0 errors, 0 warnings.
2. Run `flutter test` — All tests must pass (16+ tests across `counter_model_test.dart`, `accessibility_and_duplicate_test.dart`, `widget_navigation_test.dart`, `widget_test.dart`).
3. Ensure git branch rules and signed commit requirements are respected.
