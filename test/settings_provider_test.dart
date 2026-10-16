import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:original_bible/features/settings/settings_provider.dart';

Future<void> _waitUntilLoaded(SettingsNotifier notifier) async {
  for (var i = 0; i < 50; i++) {
    if (notifier.state.isLoaded) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('SettingsNotifier did not finish loading in time.');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Settings language/translation behavior', () {
    test('recognizes regional and script language codes', () {
      expect(normalizeAppLanguage('pt-BR'), 'pt');
      expect(normalizeAppLanguage(' es_MX '), 'es');
      expect(normalizeAppLanguage('zh-Hant-TW'), 'zh');
      expect(normalizeAppLanguage('xx-YY'), 'en');
    });

    test('uses the first supported device language', () {
      expect(
        appLanguageForDevice([const Locale('it'), const Locale('pt', 'BR')]),
        'pt',
      );
      expect(appLanguageForDevice([const Locale('it')]), 'en');
      expect(appLanguageForDevice([]), 'en');
    });

    test('new installs start in the device language with its Bible', () async {
      final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher;
      dispatcher.localesTestValue = [const Locale('pt', 'BR')];
      addTearDown(dispatcher.clearLocalesTestValue);
      SharedPreferences.setMockInitialValues({});
      final notifier = SettingsNotifier();
      addTearDown(notifier.dispose);
      await _waitUntilLoaded(notifier);

      expect(notifier.state.appLanguage, 'pt');
      expect(notifier.state.translation, 'ALMEIDA');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('appLanguage'), 'pt');
      expect(prefs.getString('translation'), 'ALMEIDA');
    });

    test('saved language takes precedence over device language', () async {
      final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher;
      dispatcher.localesTestValue = [const Locale('pt', 'BR')];
      addTearDown(dispatcher.clearLocalesTestValue);
      SharedPreferences.setMockInitialValues({'appLanguage': 'fr'});
      final notifier = SettingsNotifier();
      addTearDown(notifier.dispose);
      await _waitUntilLoaded(notifier);

      expect(notifier.state.appLanguage, 'fr');
      expect(notifier.state.translation, 'OSTERVALD');
    });

    test(
      'repairs an obsolete edition using the saved regional language',
      () async {
        SharedPreferences.setMockInitialValues({
          'appLanguage': 'pt-BR',
          'translation': 'ACF',
          'hasManuallySelectedTranslation': true,
        });
        final notifier = SettingsNotifier();
        addTearDown(notifier.dispose);
        await _waitUntilLoaded(notifier);

        expect(notifier.state.appLanguage, 'pt');
        expect(notifier.state.translation, 'ALMEIDA');
        expect(notifier.state.hasManuallySelectedTranslation, isTrue);
      },
    );

    test(
      'onboarding applies default translation only before manual selection',
      () async {
        SharedPreferences.setMockInitialValues({
          'translation': 'KJV',
          'appLanguage': 'en',
          'hasManuallySelectedTranslation': false,
        });

        final notifier = SettingsNotifier();
        await _waitUntilLoaded(notifier);

        await notifier.applyLanguageDefaultTranslation('de');
        expect(notifier.state.appLanguage, 'de');
        expect(notifier.state.translation, 'LUTHER1912');
        expect(notifier.state.hasManuallySelectedTranslation, isFalse);

        await notifier.setTranslation('KJV');
        expect(notifier.state.hasManuallySelectedTranslation, isTrue);

        await notifier.setAppLanguageOnly('ru');
        await notifier.applyLanguageDefaultTranslation('ru');

        // Manual translation choice should be preserved.
        expect(notifier.state.appLanguage, 'ru');
        expect(notifier.state.translation, 'KJV');
      },
    );

    test('changing app language does not force translation change', () async {
      SharedPreferences.setMockInitialValues({
        'translation': 'SYNODAL',
        'appLanguage': 'ru',
        'hasManuallySelectedTranslation': true,
      });

      final notifier = SettingsNotifier();
      await _waitUntilLoaded(notifier);

      await notifier.setAppLanguageOnly('de');

      expect(notifier.state.appLanguage, 'de');
      expect(notifier.state.translation, 'SYNODAL');
    });

    test(
      'normalizes disabled translation to enabled language default',
      () async {
        SharedPreferences.setMockInitialValues({
          'translation': 'KOUGO',
          'appLanguage': 'fr',
          'hasManuallySelectedTranslation': true,
        });

        final notifier = SettingsNotifier();
        await _waitUntilLoaded(notifier);

        await notifier.ensureEnabledTranslationSelection({
          'KJV',
          'LUTHER1912',
          'SYNODAL',
          'ALMEIDA',
          'VALERA1909',
          'OSTERVALD',
        });

        expect(notifier.state.translation, 'OSTERVALD');
        expect(notifier.state.hasManuallySelectedTranslation, isTrue);
      },
    );

    test('onboarding applies CUVS and KOREAN defaults for zh and ko', () async {
      SharedPreferences.setMockInitialValues({
        'translation': 'KJV',
        'appLanguage': 'en',
        'hasManuallySelectedTranslation': false,
      });

      final notifier = SettingsNotifier();
      await _waitUntilLoaded(notifier);

      await notifier.applyLanguageDefaultTranslation('zh');
      expect(notifier.state.appLanguage, 'zh');
      expect(notifier.state.translation, 'CUVS');

      await notifier.applyLanguageDefaultTranslation('ko');
      expect(notifier.state.appLanguage, 'ko');
      expect(notifier.state.translation, 'KOREAN');
    });
  });
}
