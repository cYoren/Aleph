/// "Today's 5 minutes": due reviews first, then the next words of the active
/// path. Finishing it extends a streak; walking away mid-session does not.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/database_provider.dart';
import '../vocabulary/vocabulary_item_tile.dart';
import '../vocabulary/vocabulary_provider.dart';
import 'book_path.dart';

const _maxDue = 10;
const _maxNew = 3;
const _streakDayKey = 'streakLastDay';
const _streakCountKey = 'streakCount';

String _day(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Streak after completing a session on [today], given the last completed day.
int nextStreak({
  required String? lastDay,
  required int count,
  required DateTime today,
}) {
  if (lastDay == _day(today)) return count;
  final yesterday = DateTime(today.year, today.month, today.day - 1);
  return lastDay == _day(yesterday) ? count + 1 : 1;
}

/// Current streak, or 0 when the last session was before yesterday.
final streakProvider = StateNotifierProvider<StreakNotifier, int>(
  (ref) => StreakNotifier(),
);

class StreakNotifier extends StateNotifier<int> {
  StreakNotifier() : super(0) {
    SharedPreferences.getInstance().then((prefs) {
      final count = prefs.getInt(_streakCountKey) ?? 0;
      final last = prefs.getString(_streakDayKey);
      final today = DateTime.now();
      final alive =
          last == _day(today) ||
          last == _day(DateTime(today.year, today.month, today.day - 1));
      if (mounted) state = alive ? count : 0;
    });
  }

  Future<void> completeToday() async {
    final prefs = await SharedPreferences.getInstance();
    final next = nextStreak(
      lastDay: prefs.getString(_streakDayKey),
      count: prefs.getInt(_streakCountKey) ?? 0,
      today: DateTime.now(),
    );
    await prefs.setInt(_streakCountKey, next);
    await prefs.setString(_streakDayKey, _day(DateTime.now()));
    state = next;
  }
}

/// Runs the session. Returns true when every card was answered.
Future<bool> runDailySession(BuildContext context, WidgetRef ref) async {
  final srs = ref.read(srsDaoProvider);
  final due = await ref.refresh(dueVocabularyProvider.future);
  final active = ref.read(activePathProvider);
  final path = active == null
      ? null
      : await ref.read(bookPathProvider(active).future);

  final queue = <VocabularyDeckItem>[
    ...due.take(_maxDue),
    ...?path?.nextWords.take(_maxNew),
  ];

  for (final item in queue) {
    if (!context.mounted) return false;
    final before = await srs.getProgress(item.lexiconKey);
    if (!context.mounted) return false;
    await reviewDeckItem(context, item);
    final after = await srs.getProgress(item.lexiconKey);
    // Closing the sheet without answering leaves the record untouched.
    if (after == null || after.lastReviewedAt == before?.lastReviewedAt) {
      return false;
    }
  }

  await ref.read(streakProvider.notifier).completeToday();
  ref.invalidate(dueVocabularyProvider);
  if (active != null) ref.invalidate(bookPathProvider(active));
  return true;
}
