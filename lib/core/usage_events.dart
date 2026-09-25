/// Opt-in anonymous usage counts, sent to the Aleph proxy (proxy/worker.js).
///
/// Off unless the reader turns it on in Settings. Each event carries only its
/// name, interface language, platform and whole days since
/// install: no id, no text, nothing about what was read. Failures are
/// swallowed; counting must never get in the way of reading.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../features/explain/explain_service.dart';

const _enabledKey = 'usageSharingEnabled';
const _installKey = 'installDay';
const _lastOpenKey = 'lastOpenPingDay';

enum UsageEvent {
  appOpen('app_open'),
  dailySessionDone('daily_session_done'),
  pathStarted('path_started'),
  cardShared('card_shared'),
  reminderEnabled('reminder_enabled');

  const UsageEvent(this.wireName);
  final String wireName;
}

String _today() => DateTime.now().toIso8601String().substring(0, 10);

class UsageEvents {
  UsageEvents._();

  /// Sends [event] if the reader opted in and a proxy is configured.
  static Future<void> record(UsageEvent event) async {
    if (kAiProxyUrl.isEmpty || kIsWeb) return;
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

      final day = DateTime.now().difference(DateTime.parse(installDay)).inDays;
      await http
          .post(
            Uri.parse(kAiProxyUrl).resolve('/event'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'event': event.wireName,
              'language': prefs.getString('appLanguage') ?? 'en',
              'platform': Platform.operatingSystem,
              'day': day,
            }),
          )
          .timeout(const Duration(seconds: 5));
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
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }
}
