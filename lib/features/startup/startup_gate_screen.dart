import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/onboarding/first_run.dart';
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

  @override
  void initState() {
    super.initState();
    // The clock for "your first verse in N minutes" starts at the first launch
    // of the app, not when the reader reaches the reading screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(firstRunProvider.notifier).touchLaunch();
    });
  }

  void _navigateIfReady(SettingsState settings, FirstRunState firstRun) {
    if (_navigated || !settings.isLoaded || !firstRun.isLoaded || !mounted) {
      return;
    }

    _navigated = true;
    final nextRoute = (kDebugMode && _startRoute.isNotEmpty)
        ? _startRoute
        : (settings.hasCompletedOnboarding
              ? (firstRun.isComplete ? '/' : '/start')
              : '/language');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.go(nextRoute);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final firstRun = ref.watch(firstRunProvider);
    _navigateIfReady(settings, firstRun);

    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
