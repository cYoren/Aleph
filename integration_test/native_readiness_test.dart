import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:original_bible/main.dart' as app;
import 'package:original_bible/app/router.dart';
import 'package:original_bible/features/settings/settings_provider.dart';
import 'package:original_bible/features/reading/reading_screen.dart';
import 'package:original_bible/features/home/home_screen.dart';
import 'package:original_bible/data/database/daos/bible_dao.dart';
import 'package:original_bible/features/audio/embedded_tts_engine.dart';
import 'package:original_bible/features/audio/embedded_voices.dart';
import 'package:original_bible/features/audio/embedded_player.dart';
import 'package:original_bible/shared/widgets/tappable_word.dart';
import 'package:original_bible/shared/widgets/definition_sheet.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('offline first reading, core routes and native Greek audio', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasCompletedOnboarding', false);
    await prefs.setString('appLanguage', 'en');
    app.main();
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    if (Platform.isAndroid) {
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();
    }
    Future<void> shot(String name) async {
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await binding.takeScreenshot(name);
    }

    await shot('01-language');
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    await shot('02-first-word');
    await tester.tap(find.byType(TappableWord).first);
    await tester.pumpAndSettle();
    expect(find.byType(DefinitionSheet), findsOneWidget);
    expect(find.textContaining('7225'), findsOneWidget);
    await shot('03-definition');
    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await shot('04-tradition');
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(find.byType(ReadingScreen), findsOneWidget);
    await shot('05-reader');
    final dao = BibleDAO();
    expect(await dao.getSyntaxTreesForVerse('GEN', 1, 1), isNotNull);
    expect(await dao.search('beginning', translationId: 'KJV'), isNotEmpty);
    for (final route in ['/', '/bookmarks', '/search', '/settings']) {
      router.go(route);
      await tester.pumpAndSettle();
      await shot(route == '/' ? '06-home' : '07-${route.substring(1)}');
    }
    router.go('/');
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    );
    await container
        .read(settingsProvider.notifier)
        .setThemeMode(ThemeMode.dark);
    await shot('08-dark-home');
    await container
        .read(settingsProvider.notifier)
        .setThemeMode(ThemeMode.light);
    final engine = EmbeddedTtsEngine();
    final nativePlayer = AudioPlayer();
    await nativePlayer.setVolume(
      0,
    ); // Test completion without audible desktop playback.
    final player = EmbeddedPlayer(player: nativePlayer);
    try {
      expect(await engine.prepare(kEmbeddedGreekVoice), isTrue);
      final audio = await engine.synthesize('λόγος');
      expect(audio, isNotNull);
      expect(audio!.sampleRate, 16000);
      expect(audio.samples.any((sample) => sample.abs() > 0.01), isTrue);
      expect(
        await player.play(audio.toWav()).timeout(const Duration(seconds: 30)),
        isTrue,
      );
    } finally {
      await player.dispose();
      engine.dispose();
    }
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 5)));
}
