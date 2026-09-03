import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/database/database_helper.dart';
import '../../l10n/generated/app_localizations.dart';
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

/// Waits for settings, then for the database to be ready.
///
/// The database is opened here rather than lazily inside the reader because
/// the first launch after an install copies 234 MB out of the app bundle.
/// That used to happen behind a bare spinner with nothing said about it, which
/// is indistinguishable from a hang — and it happens again on any update that
/// bumps `kBundledDatabaseVersion`. Doing it here means there is a screen to
/// explain the wait and show how far along it is.
class StartupGateScreen extends ConsumerStatefulWidget {
  const StartupGateScreen({super.key});

  @override
  ConsumerState<StartupGateScreen> createState() => _StartupGateScreenState();
}

class _StartupGateScreenState extends ConsumerState<StartupGateScreen> {
  bool _started = false;
  bool _navigated = false;
  bool _copyFailed = false;

  Future<void> _prepare(SettingsState settings) async {
    if (_started) return;
    _started = true;

    // Whether a copy actually began, so a failure can be reported with the
    // advice that applies to it (free space) rather than generically.
    var copying = false;
    void watch() {
      if (databaseCopyProgress.value != null) copying = true;
    }

    databaseCopyProgress.addListener(watch);
    try {
      await DatabaseHelper.instance.database;
    } catch (_) {
      // A failure here is not fatal to navigation. Every screen that reads the
      // database now has an error state with a retry, so the reader gets a way
      // forward rather than a dead end — except when the first-run copy itself
      // failed, which needs its own explanation and is worth stopping for.
      if (mounted && copying) {
        setState(() => _copyFailed = true);
        return;
      }
    } finally {
      databaseCopyProgress.removeListener(watch);
    }
    if (!mounted) return;
    _navigate(settings);
  }

  void _navigate(SettingsState settings) {
    if (_navigated || !mounted) return;
    _navigated = true;

    final nextRoute = (kDebugMode && _startRoute.isNotEmpty)
        ? _startRoute
        : (settings.hasCompletedOnboarding ? '/' : '/language');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go(nextRoute);
    });
  }

  void _retry() {
    setState(() {
      _started = false;
      _copyFailed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context);

    if (settings.isLoaded && !_started) {
      // Kicked off after this frame so the screen paints first.
      WidgetsBinding.instance.addPostFrameCallback((_) => _prepare(settings));
    }

    if (_copyFailed && l10n != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.somethingWentWrong,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.databasePrepareFailed,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.tryAgain),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: ValueListenableBuilder<double?>(
          valueListenable: databaseCopyProgress,
          builder: (context, progress, _) {
            // Nothing to copy: the ordinary launch, and it stays a spinner.
            if (progress == null || l10n == null) {
              return const CircularProgressIndicator();
            }
            return _PreparingDatabase(progress: progress, l10n: l10n);
          },
        ),
      ),
    );
  }
}

/// Shown only on a first launch, or after an update that ships new data.
class _PreparingDatabase extends StatelessWidget {
  const _PreparingDatabase({required this.progress, required this.l10n});

  final double progress;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_outlined, size: 44, color: scheme.primary),
          const SizedBox(height: 24),
          Text(
            l10n.databasePreparingTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Text(
            l10n.databasePreparingBody,
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5),
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${(progress * 100).round()}%',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
