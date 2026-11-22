/// Opt-in anonymous usage counts, sent to the Aleph proxy (proxy/worker.js)
/// and mirrored to PostHog by `posthog.dart`.
///
/// Off unless the reader turns it on in Settings. Each event carries only its
/// name, interface language, platform and whole days since
/// install: no id, no text, nothing about what was read. Failures are
/// swallowed; counting must never get in the way of reading.
///
/// The Settings switch is the only gate, and it is opt-in: default off, and
/// both destinations stay silent until the reader turns it on. Turning it off
/// sends `settings_analytics_opt_out` first, then stops everything.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../features/explain/explain_service.dart';
import 'posthog.dart';

const _enabledKey = 'usageSharingEnabled';
const _installKey = 'installDay';
const _lastOpenKey = 'lastOpenPingDay';

enum UsageEvent {
  appOpen('app_open', 'app_opened'),
  dailySessionDone('daily_session_done', 'daily_session_done'),
  pathStarted('path_started', 'path_started'),
  cardShared('card_shared', 'card_shared'),
  reminderEnabled('reminder_enabled', 'reminder_enabled'),

  /// The on-ramp, counted at the two points that decide whether a beginner
  /// stays: the first verse they could read, and the first review they
  /// finished. No text, no timing — the minutes themselves stay on the device.
  firstVerseRead('first_verse_read', 'first_verse_read'),
  firstReviewDone('first_review_done', 'first_review_done'),

  /// The tip jar, opened, started and completed. Counted like everything
  /// else here: only if the reader opted in, and never tied to an account
  /// because there are no accounts. The tier is a name, never a price the
  /// store did not say.
  supportOpened('support_opened', 'support_opened'),
  supportStarted('support_started', 'purchase_started'),
  supportCompleted('support_completed', 'purchase_completed'),

  /// Store-side failure, so a funnel can tell "did not finish" from "broke".
  supportFailed('support_failed', 'purchase_failed'),

  /// Onboarding reached the reader screen, however they left it (finished or
  /// skipped). No answers: the tradition they picked stays on the device.
  onboardingCompleted('onboarding_completed', 'onboarding_completed'),

  /// A chapter on screen. The book is an enum id (`GEN`, `JHN`) plus which
  /// testament; the chapter and verse numbers are never sent, and neither is
  /// anything the reader looked up while they were there.
  chapterRead('chapter_read', 'chapter_read'),

  /// The first chapter ever read on this device: the moment the product
  /// delivers. Sent once.
  firstValue('first_value', 'first_value'),

  /// A depth pane under a tapped word that the reader actively opened:
  /// `senses`, `root`, `forms` or `syntax_tree`. A layer name, nothing else.
  /// The panes that are simply always shown (participants, qere/ketiv) do not
  /// count, because nobody chose them.
  depthLayerOpened('depth_layer_opened', 'depth_layer_opened'),

  /// Every occurrence of a word, for concordance work.
  wordStudyOpened('word_study_opened', 'word_study_opened'),

  /// A step of the beginner on-ramp (`/start`) finished: letters, first verse,
  /// first review.
  beginnerLessonCompleted('beginner_lesson_completed', 'beginner_lesson_completed'),

  /// Sent once, before the switch takes effect, so an opt-out is visible.
  analyticsOptOut('analytics_opt_out', 'settings_analytics_opt_out');

  const UsageEvent(this.wireName, this.postHogName);

  /// The name the Aleph proxy counts.
  final String wireName;

  /// The name PostHog stores. Some differ so PostHog funnels read the same
  /// across every product.
  final String postHogName;
}

String _today() => DateTime.now().toIso8601String().substring(0, 10);

class UsageEvents {
  UsageEvents._();

  /// Sends [event] if the reader opted in.
  ///
  /// Two destinations, one gate: the proxy (when this build has one) and
  /// PostHog (always, since its key ships in the app). Either can fail alone
  /// without affecting the other, and neither can affect reading.
  ///
  /// The network work is dispatched, not awaited. Callers await this method
  /// before opening the tip jar sheet or marking a purchase in progress, and a
  /// slow analytics endpoint must never be visible as the app hanging. Both
  /// senders swallow their own failures and time out at 5 s.
  static Future<void> record(
    UsageEvent event, {
    Map<String, Object?> properties = const {},
  }) async {
    if (kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final installDay = prefs.getString(_installKey) ?? _today();
      await prefs.setString(_installKey, installDay);
      if (!(prefs.getBool(_enabledKey) ?? false)) return;

      if (event == UsageEvent.appOpen) {
        // One open per day, so the counts mean "people", not "launches".
        if (prefs.getString(_lastOpenKey) == _today()) return;
        await prefs.setString(_lastOpenKey, _today());
      }

      final language = prefs.getString('appLanguage') ?? 'en';
      final day = DateTime.now().difference(DateTime.parse(installDay)).inDays;

      if (kAiProxyUrl.isNotEmpty) {
        unawaited(_sendToProxy(event, language, day));
      }
      unawaited(
        sendToPostHog(
          optedIn: true, // checked above: nothing gets here otherwise
          event: event.postHogName,
          properties: {...properties, 'days_since_install': day},
          locale: language,
        ),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('UsageEvents: $e');
    }
  }

  static Future<void> _sendToProxy(
    UsageEvent event,
    String language,
    int day,
  ) async {
    if (kAiProxyUrl.isEmpty) return;
    try {
      await http
          .post(
            Uri.parse(kAiProxyUrl).resolve('/event'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'event': event.wireName,
              'language': language,
              'platform': Platform.operatingSystem,
              'day': day,
            }),
          )
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      if (kDebugMode) debugPrint('UsageEvents: $e');
    }
  }

  /// True when the app has anywhere to send counts. The Settings switch shows
  /// only then, so it is never a dead control.
  static bool get isConfigured => kAiProxyUrl.isNotEmpty || postHogEnabled();

  /// The first chapter ever read. Stamped once per device; `firstValue` is the
  /// one event in here that must never repeat.
  static const _firstChapterKey = 'firstChapterReadAt';

  /// Records a chapter on screen, and `first_value` the first time.
  static Future<void> recordChapterRead({
    required String bookId,
    required bool isOldTestament,
  }) async {
    await record(
      UsageEvent.chapterRead,
      properties: {'book': bookId, 'testament': isOldTestament ? 'ot' : 'nt'},
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getInt(_firstChapterKey) != null) return;
      await prefs.setInt(_firstChapterKey, DateTime.now().millisecondsSinceEpoch);
      await record(UsageEvent.firstValue);
    } catch (e) {
      if (kDebugMode) debugPrint('UsageEvents: $e');
    }
  }
}

/// The Settings switch.
final usageSharingProvider = StateNotifierProvider<UsageSharingNotifier, bool>(
  (ref) => UsageSharingNotifier(),
);

class UsageSharingNotifier extends StateNotifier<bool> {
  UsageSharingNotifier() : super(false) {
    SharedPreferences.getInstance().then((prefs) {
      if (mounted) state = prefs.getBool(_enabledKey) ?? false;
    });
  }

  Future<void> set(bool enabled) async {
    // Announce the decision while it is still allowed through the gate, then
    // close it. No further event leaves this device after this line.
    if (!enabled && state) {
      await UsageEvents.record(UsageEvent.analyticsOptOut);
    }
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }
}
