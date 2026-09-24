/// Evening reminder that brings a learner back when vocabulary is due.
///
/// There is one pending notification at most, always for the next 7 pm. It is
/// rescheduled every time the app goes to the background, so its count is
/// recomputed from the latest reviews instead of going stale the way a fixed
/// daily repeat would ("12 words due" after the learner cleared them all).
library;

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../data/database/daos/srs_dao.dart';
import '../l10n/generated/app_localizations.dart';

const _prefsKey = 'reviewReminderEnabled';
const _notificationId = 1;
const _reminderHour = 19;

/// Route opened when the reminder is tapped.
const kReviewReminderRoute = '/vocabulary';

/// Next 7 pm that is at least two hours away, so a learner who studies in the
/// early evening is not pinged about the session they just finished.
DateTime nextReminderTime(DateTime now) {
  final today = DateTime(now.year, now.month, now.day, _reminderHour);
  if (today.difference(now) >= const Duration(hours: 2)) return today;
  return DateTime(now.year, now.month, now.day + 1, _reminderHour);
}

class ReviewReminder {
  ReviewReminder._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// Call once at startup. [onOpen] receives the route to show on tap.
  static Future<void> init(void Function(String route) onOpen) async {
    if (kIsWeb || _initialized) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
          macOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (response) =>
            onOpen(response.payload ?? kReviewReminderRoute),
      );
      _initialized = true;
      // ponytail: a tap that cold-starts the app lands on Home, not on
      // vocabulary; read getNotificationAppLaunchDetails() if that matters.
    } catch (e) {
      if (kDebugMode) debugPrint('ReviewReminder init failed: $e');
    }
  }

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? false;
  }

  /// Asks for permission when turning on. Returns the resulting state.
  static Future<bool> setEnabled(bool enabled) async {
    if (enabled && !await _requestPermission()) enabled = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, enabled);
    await reschedule();
    return enabled;
  }

  static Future<bool> _requestPermission() async {
    if (!_initialized) return false;
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, sound: true) ?? false;
    }
    final macos = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    if (macos != null) {
      return await macos.requestPermissions(alert: true, sound: true) ?? false;
    }
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    return false;
  }

  /// Replaces the pending reminder with one for the next 7 pm, or clears it
  /// when reminders are off.
  static Future<void> reschedule() async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(id: _notificationId);
      if (!await isEnabled()) return;

      final prefs = await SharedPreferences.getInstance();
      final l10n = lookupAppLocalizations(
        Locale(prefs.getString('appLanguage') ?? 'en'),
      );
      final when = nextReminderTime(DateTime.now());
      final due = await SrsDao().countDueBy(when);

      await _plugin.zonedSchedule(
        id: _notificationId,
        // An absolute instant: UTC avoids needing the device's zone name.
        scheduledDate: tz.TZDateTime.from(when, tz.UTC),
        title: due > 0 ? l10n.reminderDueTitle(due) : l10n.reminderReadTitle,
        body: due > 0 ? l10n.reminderDueBody : l10n.reminderReadBody,
        payload: due > 0 ? kReviewReminderRoute : '/reading',
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'review_reminder',
            l10n.reviewReminderSetting,
            importance: Importance.defaultImportance,
          ),
          iOS: const DarwinNotificationDetails(),
          macOS: const DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('ReviewReminder schedule failed: $e');
    }
  }
}

/// Whether the evening reminder is on, for the Settings switch.
final reviewReminderProvider =
    StateNotifierProvider<ReviewReminderNotifier, bool>(
      (ref) => ReviewReminderNotifier(),
    );

class ReviewReminderNotifier extends StateNotifier<bool> {
  ReviewReminderNotifier() : super(false) {
    ReviewReminder.isEnabled().then((value) {
      if (mounted) state = value;
    });
  }

  Future<void> set(bool enabled) async {
    state = enabled;
    final result = await ReviewReminder.setEnabled(enabled);
    if (mounted) state = result;
  }
}
