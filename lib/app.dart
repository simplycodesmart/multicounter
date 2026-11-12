import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/counters/counter_editor_screen.dart';
import 'features/counters/counters_screen.dart';
import 'features/home/home_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/widgets/widget_studio_screen.dart';
import 'providers/counter_provider.dart';
import 'providers/settings_provider.dart';
import 'services/notification_service.dart';

class MultiCounterApp extends ConsumerStatefulWidget {
  const MultiCounterApp({super.key});

  @override
  ConsumerState<MultiCounterApp> createState() => _MultiCounterAppState();
}

class _MultiCounterAppState extends ConsumerState<MultiCounterApp> {
  static const MethodChannel _widgetChannel =
      MethodChannel('multicounter/widget_config');

  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/counters',
          builder: (context, state) => const CountersScreen(),
        ),
        GoRoute(
          path: '/widgets',
          builder: (context, state) => const WidgetStudioScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/counter/new',
          builder: (context, state) => const CounterEditorScreen(),
        ),
        GoRoute(
          path: '/counter/:id/edit',
          builder: (context, state) =>
              CounterEditorScreen(counterId: state.pathParameters['id']),
        ),
      ],
    );

    _widgetChannel.setMethodCallHandler((call) async {
      if (call.method == 'openCounterFromWidget') {
        _openCounterFromWidget(call.arguments);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _readInitialWidgetNavigation();
      NotificationService.instance.init();
    });
  }

  Future<void> _readInitialWidgetNavigation() async {
    try {
      final navigation = await _widgetChannel
          .invokeMapMethod<String, dynamic>('getPendingWidgetNavigation');
      if (navigation != null) _openCounterFromWidget(navigation);
    } on PlatformException catch (error) {
      debugPrint('Could not read widget launch data: ${error.message}');
    } on MissingPluginException {
      // Non-Android platforms do not provide the widget channel.
    }
  }

  void _openCounterFromWidget(dynamic arguments) {
    if (arguments is! Map) return;

    final counterId = arguments['counterId']?.toString();

    if (counterId == null || counterId.isEmpty) {
      debugPrint('Widget navigation: missing counterId');
      return;
    }

    ref.read(activeWidgetCounterProvider.notifier).setCounterId(counterId);

    final id = Uri.encodeComponent(counterId);

    // Push editor on top of the existing navigation stack.
    _router.push('/counter/$id/edit');
  }

  @override
  void dispose() {
    _widgetChannel.setMethodCallHandler(null);
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp.router(
      title: 'MultiCounter',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(
        accent: settings.accentColor,
        mode: settings.colorBlindMode,
      ),
      darkTheme: AppTheme.dark(
        accent: settings.accentColor,
        mode: settings.colorBlindMode,
      ),
      themeMode: settings.themeMode,
      routerConfig: _router,
    );
  }
}
