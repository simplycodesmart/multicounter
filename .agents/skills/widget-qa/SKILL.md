---
name: widget-qa
description: Procedures for testing, validating, and debugging Android Home Screen Widgets and in-app Widget Studio in MultiCounter. Use when modifying widget layouts, fixing alignment or spacing bugs, or testing pinning and refresh logic.
---

# Android Widget QA & Validation Guide

This skill details how to validate Android AppWidgets and their integration with Flutter in MultiCounter.

---

## 📱 Widget Layout Architecture

MultiCounter uses a two-row horizontal layout in [`multicounter_widget.xml`](file:///f:/project/multicounter/android/app/src/main/res/layout/multicounter_widget.xml):

```text
widget_time_container (vertical LinearLayout, gravity="center")
  ├── widget_digits_row (horizontal LinearLayout, baselineAligned="false")
  │     ├── widget_days (0dp, weight=1)
  │     ├── widget_sep_days (12dp fixed width, "·")
  │     ├── widget_hours (0dp, weight=1)
  │     ├── widget_colon_hm (14dp fixed width, ":")
  │     ├── widget_minutes (0dp, weight=1)
  │     ├── widget_colon_ms (14dp fixed width, ":")
  │     └── widget_seconds (0dp, weight=1)
  │
  └── widget_labels_container (horizontal LinearLayout, baselineAligned="false", layout_marginTop="2dp")
        ├── widget_days_label (0dp, weight=1, "DAYS")
        ├── widget_sep_days_spacer (12dp fixed width, empty text, 1dp height)
        ├── widget_hours_label (0dp, weight=1, "HRS")
        ├── widget_colon_hm_spacer (14dp fixed width, empty text, 1dp height)
        ├── widget_minutes_label (0dp, weight=1, "MINS")
        ├── widget_colon_ms_spacer (14dp fixed width, empty text, 1dp height)
        └── widget_seconds_label (0dp, weight=1, "SECS")
```

---

## 🔍 Validation Checklist

When reviewing or testing widget changes, verify the following:

1. **RemoteViews Safety**:
   - Only use RemoteViews-supported classes (`LinearLayout`, `TextView`, `ImageView`, `Button`).
   - Never use custom views or generic `<View>`. Use `<TextView>` with `android:text=""` for spacers.

2. **Vertical Alignment**:
   - Digits, colons (`:`), and middle dots (`·`) must share the same horizontal row (`widget_digits_row`) with `gravity="center"`.
   - Colons must never be vertically centered against the combined number + label block.

3. **Sub-Label Grouping**:
   - Sub-labels must remain strictly `2dp` below the digits even when the widget is resized to 4x3 or 4x4.
   - Spacers in the labels row must never receive font sizes or text that could distort the row height.
   - `android:baselineAligned="false"` must be present on both LinearLayouts.

4. **1:1 Flutter Studio Parity**:
   - Compare [`_WidgetPreview`](file:///f:/project/multicounter/lib/features/widgets/widget_studio_screen.dart) with the native layout.
   - Ensure color contrast, font scaling, and separator widths (`12px` and `14px`) match identically.

5. **MethodChannel IPC & Persistence**:
   - Method channel `multicounter/widget_config` routes calls between Flutter and `MainActivity.kt`.
   - Config is persisted in `SharedPreferences` under `multicounter.widget_studio.v1.widget.<id>`.
