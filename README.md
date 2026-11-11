<div align="center">

# ⏱️ MultiCounter

### The Ultra-Lightweight, Privacy-First Multi-Timer, Countdown, Habit Tally & Home Screen Widget App for Android

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white&style=for-the-badge)](https://flutter.dev)
[![Kotlin](https://img.shields.io/badge/Kotlin-Android_Native-7F52FF?logo=kotlin&logoColor=white&style=for-the-badge)](https://kotlinlang.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)
[![APK Size](https://img.shields.io/badge/APK_Size-~20MB-success?style=for-the-badge&logo=android)](https://github.com/simplycodesmart/multicounter/releases)
[![Zero Bloat](https://img.shields.io/badge/Tracking%20%2F%20Ads-Zero%20Bloat-brightgreen?style=for-the-badge)](https://github.com/simplycodesmart/multicounter)
[![Buy Me A Coffee](https://img.shields.io/badge/Buy_Me_A_Coffee-Support_Project-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/KrishnaKanthLatya)

<p align="center">
  <b>Track important life events, days since milestones, habit tallies, and upcoming celebrations with independent, responsive native Android home-screen widgets.</b>
</p>

<p align="center">
  <a href="https://buymeacoffee.com/KrishnaKanthLatya" target="_blank">
    <img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="42">
  </a>
</p>

[⬇️ **Download Latest APK**](https://github.com/simplycodesmart/multicounter/releases) •
[✨ **Features**](#-features) •
[📱 **Home Widgets**](#-independent-home-screen-widgets) •
[🎨 **Widget Studio**](#-widget-studio) •
[👁️ **Accessibility**](#-accessibility--inclusivity) •
[☕ **Support Project**](#-support-the-project) •
[🚀 **Quick Start**](#-quick-start) •
[🤝 **Contributing**](CONTRIBUTING.md)

</div>

---

## 🌟 Why MultiCounter?

Most countdown and counter apps are either cluttered with intrusive advertisements, bundle 60MB+ of unused native libraries, drain battery in the background, or limit home-screen widgets behind paywalls. 

**MultiCounter** was engineered from the ground up to be:
- ⚡ **Featherlight (~20MB APK)**: No unneeded native C binaries, full R8 code shrinking and resource optimization enabled.
- 🛡️ **100% Private & Offline**: No analytics, no accounts, no telemetry, zero tracking, zero ads.
- 📱 **Multi-Widget Launcher Support**: Pin **multiple different counters** to your Android home screen independently with duplicate prevention and duplicate widget options.
- 📐 **Dynamic Responsive Typography**: Main counter digits automatically calculate launcher bounds and resize dynamically with widget bounds, while sub-labels remain static.
- 🔋 **Battery-Aware Refresh Engine**: Select background refresh frequency from live 1s tickers to daily 24h battery saver mode with real-time consumption indicators.
- 👁️ **Accessibility First**: Designed with color-blindness palettes (Red-Green safe, Blue-Yellow safe, WCAG AAA 7:1 High Contrast) and multi-pulse tactile vibration alerts for deaf/hard-of-hearing users.

---

## ✨ Features

### ⏳ 1. Precision Countdown Timers
- 🎯 **Live Event Tracking**: Real-time ticker counting down days, hours, minutes, and seconds.
- 💍 **Smart Event Presets**: Automatic category icons and themes for:
  - 💍 **Weddings** • 👶 **Baby Births & Due Dates** • 🥂 **Anniversaries** • 💼 **Work Milestones**
  - 🎂 **Birthdays** • 🏖️ **Vacations & Trips** • 🎓 **Graduations** • 🚀 **Product Launches**
- 🔁 **Custom Recurring Intervals & Rollover**:
  - `Every Hour` • `Twice Daily (Every 12h)` • `Thrice Daily (Every 8h)` • `Custom Hours`
  - `Daily` • `Weekly` • `Monthly` • `Yearly (Anniversary)` • `Custom Days`
  - Automatically advances to the next cycle once an event arrives.
- 🔔 **Alarms & Reminders**:
  - Reminders (*at event, 1h before, 1 day before, 1 week before*) with celebratory chimes or gentle tactile vibration.
- 📋 **Duplicate Counter & Collision Guard**:
  - Duplicate any existing counter with one tap (`Title (Copy)`).
  - Built-in validator prevents duplicate counter titles and accidental double-clicks.

### 📈 2. Count-Up & Streak Trackers
- ⏳ Track elapsed time since life milestones:
  - *"Days since quitting smoking"*, *"Sober streak"*, *"Days since starting fitness routine"*, *"Tenure at company"*.
- ⏱️ Quick start-date presets (*1 Week Ago*, *30 Days Ago*, *1 Year Ago*, or custom date/time).

### 🔢 3. Interactive Tally Counters
- 📊 Track daily water glasses, workout reps, meditation sessions, books read, prayer tallies, or inventory counts.
- ➕ Configurable step increments (`+1`, `+5`, `+10`) and optional target goals.
- 🏆 Visual progress bar with completed milestone celebration status.

---

## 📱 Independent Home Screen Widgets

MultiCounter features a robust native Android widget engine (`MultiCounterWidgetProvider.kt`) powered by bidirectional Kotlin-Flutter channels:

| Feature | Icon | Description |
| :--- | :---: | :--- |
| **Multi-Instance Support** | 📑 | Place 1, 5, or 10 widgets on your home screen simultaneously—each independently bound to its own counter. |
| **Duplicate Prevention** | 🛡️ | Warns if a widget for a counter is already installed; gives an explicit "Duplicate Widget" option. |
| **One-Tap Pinning** | 📌 | Tap the widget icon on any counter card, counter editor, or inside Widget Studio to place instantly (Android 8.0+). |
| **Launcher Drawer Integration** | 📲 | Drag widgets directly from your launcher drawer; interactive picker lets you choose which counter to track. |
| **Responsive Typography** | 📐 | Auto-scales main counter digits based on actual widget dimensions and orientation on your launcher. |
| **Goal Reached Banner** | 🎉 | Switches to celebratory status with `"EVENT ARRIVED! 🎉"` or `"GOAL REACHED! 🎉"` upon milestone completion. |
| **Tap to Launch** | 🚀 | Tapping any widget opens directly to that specific counter in the app. |

---

## 🎨 Widget Studio

Customize every aspect of your home screen widgets with a real-time live preview canvas:

- 📐 **Layout Templates**:
  - **Classic**: Balanced horizontal layout with unit labels.
  - **Minimal**: Ultra-clean streamlined numbers without clutter.
  - **Bold**: High-impact typography with signature accent bar.
- 📏 **Proportional Sizes**:
  - **Small (2x1)** • **Medium (3x2)** • **Large (4x2)**
- 🪟 **Glassmorphism & Opacity**:
  - Choose 100% opaque, 80% frosted glass, 20% dark glass, or **100% transparent** to blend seamlessly with any wallpaper.
- 🎨 **Per-Counter Design Isolation**:
  - Each counter retains its own custom widget design or clean default options; fresh counters never inherit previous customizations unless duplicated.
- 🔋 **Update Frequency & Battery Guidance**:
  - `1 sec` — ⚡ High battery consumption (live seconds ticker)
  - `1 min` — 🟢 Balanced battery (Recommended)
  - `15 min` — 🔋 Low battery impact
  - `1 hour` — 🍃 Very low battery usage
  - `24 hours` — ⭐ Ultra battery saver (midnight update)
- 👁️ **Live Preview Toggle**: Test your design in both normal running state and finished `"Goal Reached / Expired"` state before applying!

---

## 👁️ Accessibility & Inclusivity

MultiCounter is built from the foundation to be inclusive and accessible to all users:

- 🟡 **Color Vision Deficiencies (CUD)**:
  - 🟡 **Red-Green Safe (Protanopia & Deuteranopia)**: Avoids confusing red/green hues, using high-visibility ambers, cyans, and blues.
  - 🟣 **Blue-Yellow Safe (Tritanopia)**: Uses distinct magentas, teals, and corals.
  - ⚪ **High Contrast (WCAG AAA 7:1)**: Stark pure blacks (`#000000`) and pure whites with 2.0-width high-luminosity borders.
- 📳 **Deaf & Hard-of-Hearing Tactile Alerts**:
  - Multi-pulse distinct vibration patterns (`[0, 600, 250, 600, 250, 800]`) on notifications and alarms so alerts are felt tactilely even without sound.
  - Gentle haptic feedback on counter taps and button clicks.
- 🗣️ **TalkBack & Screen Reader Ready**:
  - Full semantic labels on counter values, progress percentages, and status banners.

---

## ⚡ Tiny APK & Zero-Bloat Architecture

```
Split Release APKs (R8 Code + Resource Shrinking Enabled):
├── app-armeabi-v7a-release.apk  -> 19.4 MB
├── app-arm64-v8a-release.apk    -> 21.8 MB  (Recommended for 95%+ of modern phones)
└── app-x86_64-release.apk       -> 23.3 MB
```

- **Framework**: [Flutter](https://flutter.dev) (Dart 3.x) with [Riverpod](https://riverpod.dev)
- **Storage**: Clean JSON serialization with `SharedPreferences` (zero native C database overhead)
- **Notifications**: Exact & inexact Android alarm management with vector drawables
- **Native Android**: Kotlin `AppWidgetProvider`, `RemoteViews`, `AlarmManager`

---

## ☕ Support the Project

MultiCounter is **100% free, open-source, and privacy-respecting**—no advertisements, no tracking, and no paywalls.

If MultiCounter brings clarity to your days, helps you track meaningful milestones, or keeps you on track with your habits, please consider supporting continued open-source development!

<p align="center">
  <a href="https://buymeacoffee.com/KrishnaKanthLatya" target="_blank">
    <img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="54">
  </a>
</p>

<p align="center">
  ☕ <b><a href="https://buymeacoffee.com/KrishnaKanthLatya">buymeacoffee.com/KrishnaKanthLatya</a></b><br>
  <i>Every cup of coffee powers new widget layouts, performance optimizations, and keeps MultiCounter completely ad-free! Thank you! 💛</i>
</p>

---

## 🚀 Quick Start

### 📥 Download Prebuilt APK
Grab the latest release from the [Releases page](https://github.com/simplycodesmart/multicounter/releases) and install `app-arm64-v8a-release.apk` on your Android device.

### 🛠️ Build from Source

```bash
# 1. Clone the repository
git clone https://github.com/simplycodesmart/multicounter.git
cd multicounter

# 2. Install dependencies
flutter pub get

# 3. Run on connected device
flutter run

# 4. Build optimized release split APKs (<25MB)
flutter build apk --split-per-abi --release --no-tree-shake-icons
```

---

## 💾 Backup & Data Portability

Never lose your streaks or countdowns:
- 📋 **One-Tap JSON Export**: Copies your entire counter dataset to clipboard.
- 📥 **Instant JSON Import**: Paste from clipboard or backup to restore counters on any device.
- 💡 **Sample Counters**: Pre-loaded samples to get started in seconds.

---

## 🤝 Contributing

Contributions, bug reports, and feature suggestions are warmly welcomed! Please read our [Contributing Guide](CONTRIBUTING.md) to get started.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feat/amazing-feature`)
3. Commit your Changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the Branch (`git push origin feat/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

Distributed under the **MIT License**. See [`LICENSE`](LICENSE) for details.

---

<div align="center">
  <b>Made with ❤️ for productivity, minimalism, and focus.</b><br>
  <i>If you enjoy MultiCounter, please consider starring ⭐ the repository and sharing it with friends!</i><br><br>
  <a href="https://buymeacoffee.com/KrishnaKanthLatya" target="_blank">
    <img src="https://img.shields.io/badge/Buy_Me_A_Coffee-KrishnaKanthLatya-FFDD00?style=flat-square&logo=buy-me-a-coffee&logoColor=black" alt="Buy Me A Coffee">
  </a>
</div>
