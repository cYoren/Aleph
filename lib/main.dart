import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:original_bible/shared/constants/app_identity.dart';
import 'l10n/generated/app_localizations.dart';
import '../app/router.dart';
import '../features/settings/settings_provider.dart';
import '../providers/translations_provider.dart';

void main() {
  runApp(const ProviderScope(child: OriginalBibleApp()));
}

class OriginalBibleApp extends ConsumerWidget {
  const OriginalBibleApp({super.key});

  String? _fontFamilyForLanguage(String appLanguage) {
    final normalized = appLanguage.trim().toLowerCase();
    if (normalized == 'zh' || normalized == 'ko') {
      return null;
    }
    return 'Roboto';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final themeFontFamily = _fontFamilyForLanguage(settings.appLanguage);
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
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        fontFamily: themeFontFamily,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.indigo,
        fontFamily: themeFontFamily,
      ),

      // Router - use static router
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
