import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Desktop-only local testing path: the SQLite FFI factory that stands in for
// the native sqflite plugin on Linux/Windows. It stays a dev dependency because
// no shipped mobile/macOS build ever imports it, so the analyzer's
// `depend_on_referenced_packages` hint is intentionally silenced here.
// ignore: depend_on_referenced_packages
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:original_bible/shared/constants/app_identity.dart';
import 'l10n/generated/app_localizations.dart';
import '../app/router.dart';
import 'core/review_reminder.dart';
import 'core/usage_events.dart';
import 'core/licenses.dart';
import '../app/theme.dart';
import '../features/settings/settings_provider.dart';
import '../providers/translations_provider.dart';

// Public by design: it ships inside the app and cannot read anything.
const _sentryDsn =
    'https://e39562958e8e46bfef713a8c56fd91b5@o4510739590742016.ingest.us.sentry.io/4512405014183936';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerContentLicenses();
  // Desktop (local testing) has no native sqflite; use the FFI factory.
  if (!kIsWeb && (Platform.isLinux || Platform.isWindows)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  await SentryFlutter.init(
    (options) {
      // Release only. A debug build reports from the simulator, from a local
      // device run and from every test that boots the app, and none of that is a
      // user. Sentry ALEPH-3 and ALEPH-4 were exactly that: one debug simulator
      // pass on 1.0.8+31 whose app hangs were our own launch and terminate calls.
      // A null DSN turns the SDK into a no-op.
      options.dsn = kReleaseMode ? _sentryDsn : null;
      options.environment = kReleaseMode ? 'production' : 'debug';
      // 10% of sessions: enough to see a slow screen without paying for all of them.
      options.tracesSampleRate = 0.1;
      // Never attach IPs or account emails on its own.
      options.sendDefaultPii = false;
    },
    appRunner: () {
      ReviewReminder.init(router.push).then((_) => ReviewReminder.reschedule());
      // Recount due words whenever the learner leaves, so tonight's reminder
      // reflects the reviews they just did.
      AppLifecycleListener(
        onPause: ReviewReminder.reschedule,
        onResume: () => UsageEvents.record(UsageEvent.appOpen),
      );
      UsageEvents.record(UsageEvent.appOpen);
      runApp(const ProviderScope(child: OriginalBibleApp()));
    },
  );
}

class OriginalBibleApp extends ConsumerWidget {
  const OriginalBibleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    ref.listen(translationsProvider, (previous, next) {
      if (!ref.read(settingsProvider).isLoaded) return;
      final translations = next.valueOrNull;
      if (translations == null || translations.isEmpty) return;
      final enabledIds = translations.map((t) => t.id).toSet();
      ref
          .read(settingsProvider.notifier)
          .ensureEnabledTranslationSelection(enabledIds);
    });

    ref.listen<SettingsState>(settingsProvider, (previous, next) {
      if (!next.isLoaded) return;
      final translations = ref.read(translationsProvider).valueOrNull;
      if (translations == null || translations.isEmpty) return;
      final enabledIds = translations.map((t) => t.id).toSet();
      ref
          .read(settingsProvider.notifier)
          .ensureEnabledTranslationSelection(enabledIds);
    });

    return MaterialApp.router(
      onGenerateTitle: (context) =>
          AppLocalizations.of(context)?.appTitle ?? AppIdentity.publicAppName,

      // Localization
      locale: Locale(settings.appLanguage),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,

      // Theme
      themeMode: settings.themeMode,
      theme: AppTheme.light(settings.appLanguage),
      darkTheme: AppTheme.dark(settings.appLanguage),

      // Keep edge-to-edge status icons legible on pages without an AppBar.
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: Theme.of(context).brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: child ?? const SizedBox.shrink(),
      ),

      // Router - use static router
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
