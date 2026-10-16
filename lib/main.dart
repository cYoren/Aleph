import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:original_bible/shared/constants/app_identity.dart';
import 'l10n/generated/app_localizations.dart';
import '../app/router.dart';
import 'core/review_reminder.dart';
import 'core/usage_events.dart';
import '../app/theme.dart';
import '../features/settings/settings_provider.dart';
import '../providers/translations_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Desktop (local testing) has no native sqflite; use the FFI factory.
  if (!kIsWeb && (Platform.isLinux || Platform.isWindows)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  ReviewReminder.init(router.push).then((_) => ReviewReminder.reschedule());
  // Recount due words whenever the learner leaves, so tonight's reminder
  // reflects the reviews they just did.
  AppLifecycleListener(
    onPause: ReviewReminder.reschedule,
    onResume: () => UsageEvents.record(UsageEvent.appOpen),
  );
  UsageEvents.record(UsageEvent.appOpen);
  runApp(const ProviderScope(child: OriginalBibleApp()));
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

      // Router - use static router
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
