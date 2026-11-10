import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:multicounter/app.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Bottom navigation switches between all screens', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MultiCounterApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Initially Home Screen
    expect(find.text('MultiCounter'), findsWidgets);

    // Tap Counters tab (index 1)
    await tester.tap(find.byIcon(Icons.timer_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('All Counters'), findsOneWidget);

    // Tap Widgets tab (index 2)
    await tester.tap(find.byIcon(Icons.widgets_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Widget Studio'), findsOneWidget);

    // Tap Settings tab (index 3)
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Settings'), findsWidgets);
    expect(find.text('APPEARANCE & THEME'), findsOneWidget);
    expect(find.text('Theme Mode'), findsOneWidget);

    // Tap Home tab (index 0)
    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('MultiCounter'), findsWidgets);
  });
}
