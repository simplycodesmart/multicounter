# MultiCounter ⏱️

A modern, simple, and highly customizable multi-counter Flutter application with independent native Android home-screen widget support.

---

## ✨ Features

- **⏳ Countdown Timers**:
  - Track upcoming milestones, vacations, exams, and events.
  - Real-time 1-second live ticker down to days, hours, minutes, and seconds.
  - Quick presets: *+1 Day*, *+1 Week*, *+1 Month*, and *New Year*.
  - Completion badge when your target arrives.

- **📈 Count-Up Timers**:
  - Track elapsed time since important milestones (e.g. days since quitting a bad habit, fitness streak, project start).
  - Set past dates and times or use quick presets (*1 Week Ago*, *30 Days Ago*, *1 Year Ago*).

- **🔢 Tally Counters**:
  - Track daily habits, water glasses, workout reps, and inventory.
  - Interactive increment (`+step`), decrement (`-step`), and reset controls directly on the card.
  - Configurable step sizes and target goals with visual progress bars.

- **📱 Independent Home Screen Widgets**:
  - Place **multiple different counters** on your Android home screen simultaneously.
  - Each widget independently tracks its assigned counter.
  - One-tap **"Add to Home Screen"** pinning directly from any counter card or Widget Studio.
  - Also supports dragging widgets directly from the Android Launcher widgets drawer with an interactive counter chooser.
  - Tap any home-screen widget to open and edit that specific counter in the app.

- **🎨 Widget Studio**:
  - Live interactive preview of your home-screen widget.
  - Select any counter to preview and customize its appearance.
  - Multiple layout styles: **Classic**, **Minimal**, and **Bold**.
  - Proportional sizing: **Small (2x1)**, **Medium (3x2)**, and **Large (4x2)**.
  - Customizable number font size (16px to 36px) and visible units toggle (Days, Hours, Minutes, Seconds, Labels, Title).
  - Matches dark or light wallpaper themes with custom background and accent colors.

- **🌓 Theming & Settings**:
  - **Dark Mode**, **Light Mode**, and **System Auto** themes.
  - Curated accent color palette (Gold, Cyan, Emerald, Coral, Violet, Sky Blue, Pink).
  - Tactile haptic feedback on counter taps and button presses.
  - Default counter type preference.

- **💾 Data Backup & Restore**:
  - One-tap **Export** all counters to formatted JSON (copy to clipboard).
  - **Import** JSON backups to restore your data anytime.
  - **Load Sample Counters** for quick exploration.

---

## 🛠️ Architecture & Tech Stack

- **Framework**: [Flutter](https://flutter.dev) (Dart 3.x)
- **State Management**: [Riverpod](https://riverpod.dev) (`Notifier`, `AsyncNotifier`)
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router)
- **Persistence**: `shared_preferences`
- **Native Android Widgets**:
  - Kotlin `AppWidgetProvider` (`MultiCounterWidgetProvider.kt`)
  - `WidgetConfigureActivity.kt` for launcher and pin configuration
  - Bi-directional Flutter-to-Android `MethodChannel` (`multicounter/widget_config`)
  - Automatic periodic background refresh and on-demand syncing

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.13+ or newer)
- Android Studio / Android SDK (API 26+ for widget pinning)

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/simplycodesmart/multicounter.git
   cd multicounter
   ```

2. Fetch dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

4. Run tests:
   ```bash
   flutter test
   ```

---

## 📦 Building the Release APK

To build a standalone production release APK:

```bash
flutter build apk --release
```

The compiled APK will be located at:
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## 📄 License

This project is open-source and available under the [MIT License](LICENSE).
