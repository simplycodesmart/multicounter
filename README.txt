MultiCounter widget content + tap navigation patch

Copy the folders into the Flutter project root and replace matching files.

Files:
- android/app/src/main/kotlin/com/multicounter/multicounter/MainActivity.kt
- android/app/src/main/kotlin/com/multicounter/multicounter/MultiCounterWidgetProvider.kt
- android/app/src/main/kotlin/com/multicounter/multicounter/WidgetConfigureActivity.kt
- lib/services/home_screen_widget_service.dart (same service as the corrected pin-flow patch)
- lib/app.dart

Fixes:
1. Stages the selected counter config in native SharedPreferences before Android's pin request.
2. WidgetConfigureActivity reads the launch extras first and falls back to the staged config, then stores it under the actual widget ID.
3. Widget taps pass both widget_id and counter_id to MainActivity.
4. MainActivity handles both cold-start and already-running-app taps and forwards the counter ID to Flutter.
5. Flutter opens the matching counter's existing edit screen. The widgetId is retained as a query parameter.

After copying, run:
  flutter clean
  flutter pub get
  flutter run -d emulator-5554

Note: Android launcher widgets do not update every second continuously using AppWidgetProvider alone. This patch ensures values are populated and refreshed through existing widget refresh calls; periodic live ticking requires a separate scheduled update strategy and is subject to Android background limits.
