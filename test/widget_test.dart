import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:multicounter/app.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('MultiCounter app launches', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MultiCounterApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('MultiCounter'), findsWidgets);
  });
}

