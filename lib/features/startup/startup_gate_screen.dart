import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/settings/settings_provider.dart';

/// Jump straight to a screen on launch, for development and store screenshots:
///
///     flutter run --dart-define=START=/reading
///     flutter run --dart-define=START=/search
///
/// This is the same escape hatch Cirdoku, Tessera and Binar.io use, and it is
/// what makes screenshot capture scriptable without driving the UI. Empty in
/// every normal build, and guarded by kDebugMode so a release that somehow
/// carried the define still routes players through onboarding.
const String _startRoute = String.fromEnvironment('START');

class StartupGateScreen extends ConsumerStatefulWidget {
  const StartupGateScreen({super.key});

  @override
  ConsumerState<StartupGateScreen> createState() => _StartupGateScreenState();
}

class _StartupGateScreenState extends ConsumerState<StartupGateScreen> {
  bool _navigated = false;

  void _navigateIfReady(SettingsState settings) {
    if (_navigated || !settings.isLoaded || !mounted) return;

    _navigated = true;
    final nextRoute = (kDebugMode && _startRoute.isNotEmpty)
        ? _startRoute
        : (settings.hasCompletedOnboarding ? '/' : '/language');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.go(nextRoute);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    _navigateIfReady(settings);

    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
