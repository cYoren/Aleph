import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/core/review_reminder.dart';

void main() {
  test('reminder fires tonight when 7 pm is at least two hours away', () {
    expect(
      nextReminderTime(DateTime(2026, 9, 24, 9, 30)),
      DateTime(2026, 9, 24, 19),
    );
  });

  test('evening study pushes the reminder to tomorrow', () {
    expect(
      nextReminderTime(DateTime(2026, 9, 24, 17, 30)),
      DateTime(2026, 9, 25, 19),
    );
  });

  test('rolls over month ends', () {
    expect(
      nextReminderTime(DateTime(2026, 9, 30, 22)),
      DateTime(2026, 10, 1, 19),
    );
  });
}
