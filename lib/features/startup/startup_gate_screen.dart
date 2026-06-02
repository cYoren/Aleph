import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/settings/settings_provider.dart';

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
    final nextRoute = settings.hasCompletedOnboarding ? '/' : '/language';
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
