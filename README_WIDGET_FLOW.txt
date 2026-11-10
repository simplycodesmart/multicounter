MULTICOUNTER - SIMPLIFIED ADD-TO-HOME-SCREEN FLOW

User experience
1. Open Home or All Counters.
2. Tap the small widget icon on the counter card.
3. Android opens its native pin-widget confirmation/placement flow.
4. When the user places the widget, the selected counter is already assigned.
5. Widget Studio is optional and saves a default appearance template for future widgets.

Files in this patch (copy preserving these relative paths):
- lib/services/home_screen_widget_service.dart
- lib/shared/counter_card.dart
- lib/features/home/home_screen.dart
- lib/features/counters/counters_screen.dart
- lib/features/widgets/widget_studio_screen.dart
- android/app/src/main/AndroidManifest.xml
- android/app/src/main/kotlin/com/multicounter/multicounter/MainActivity.kt
- android/app/src/main/kotlin/com/multicounter/multicounter/WidgetConfigureActivity.kt
- android/app/src/main/kotlin/com/multicounter/multicounter/MultiCounterWidgetProvider.kt
- android/app/src/main/res/xml/multicounter_widget_info.xml
- android/app/src/main/res/layout/multicounter_widget.xml

Important:
- Android 8.0 (API 26) or newer and a launcher that supports pinned widgets are required for the in-app Add to Home Screen action.
- Android still displays its own confirmation/placement UI. The app cannot silently place a widget.
- On unsupported launchers/devices, add MultiCounter from the launcher Widgets panel.
- If your current AndroidManifest already declares MultiCounterWidgetProvider, keep only one receiver declaration and merge the WidgetConfigureActivity declaration.
- This patch includes the current independent-unit widget layout/provider. Do not combine it with the older Chronometer layout.


BUILD FIX INCLUDED
- The duplicate _resetDesign() method has been removed from _WidgetPreview; the stateful method remains in _WidgetStudioScreenState.
- HomeScreenWidgetService now includes getInstalledWidgetIds(), sync(), syncCounter(), and requestPinWidget().
- MainActivity now refreshes only installed widget configs whose counterId matches the updated counter.
