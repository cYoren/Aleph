import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/features/paths/daily_session.dart';

void main() {
  final today = DateTime(2026, 10, 1, 20);

  test('first session starts a streak', () {
    expect(nextStreak(lastDay: null, count: 0, today: today), 1);
  });

  test('yesterday extends it, across a month boundary', () {
    expect(nextStreak(lastDay: '2026-09-30', count: 4, today: today), 5);
  });

  test('a second session the same day changes nothing', () {
    expect(nextStreak(lastDay: '2026-10-01', count: 5, today: today), 5);
  });

  test('a missed day resets to one', () {
    expect(nextStreak(lastDay: '2026-09-28', count: 9, today: today), 1);
  });
}
