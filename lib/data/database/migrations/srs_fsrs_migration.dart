/// Version 6 of the user database: FSRS replaced SM-2 as the vocabulary
/// scheduler.
///
/// The columns are additive and the backfill writes nothing but FSRS state, so
/// a reader's mastery, exposure count, due date and SM-2 history all survive the
/// upgrade unchanged. Kept out of [UserDatabaseHelper] so the migration can be
/// run against a fixture database in a test.
library;

import 'package:sqflite/sqflite.dart';

import '../../../shared/utils/fsrs_scheduler.dart';
import '../../models/srs_progress.dart';

/// Adds the FSRS columns, in place, to whatever version of the schema is there.
///
/// Written as a read-then-add step rather than a fixed list of `ALTER TABLE`s,
/// because a fresh install creates the table before this runs and an upgrade
/// from any earlier version reaches it with a different set of columns.
Future<void> addFsrsColumns(Database db) async {
  final srsColumns = await _columnNames(db, 'srs_progress');
  final additions = <String, String>{
    'fsrs_stability': 'REAL',
    'fsrs_difficulty': 'REAL',
    'fsrs_state': 'INTEGER NOT NULL DEFAULT 1',
    'fsrs_step': 'INTEGER',
    'fsrs_reps': 'INTEGER NOT NULL DEFAULT 0',
    'fsrs_lapses': 'INTEGER NOT NULL DEFAULT 0',
    'fsrs_migrated': 'INTEGER NOT NULL DEFAULT 0',
  };
  for (final entry in additions.entries) {
    if (srsColumns.contains(entry.key)) continue;
    await db.execute(
      'ALTER TABLE srs_progress ADD COLUMN ${entry.key} ${entry.value}',
    );
  }

  final reviewColumns = await _columnNames(db, 'srs_reviews');
  if (reviewColumns.isNotEmpty && !reviewColumns.contains('rating')) {
    await db.execute('ALTER TABLE srs_reviews ADD COLUMN rating INTEGER');
  }
}

/// Seeds FSRS state from every SM-2 row, in place.
Future<void> backfillFsrsState(Database db) async {
  final rows = await db.query('srs_progress');
  for (final row in rows) {
    final progress = SrsProgress.fromMap(row);
    final migrated = migrateSm2ProgressToFsrs(progress);
    await db.update(
      'srs_progress',
      {
        'fsrs_stability': migrated.fsrsStability,
        'fsrs_difficulty': migrated.fsrsDifficulty,
        'fsrs_state': migrated.fsrsState,
        'fsrs_step': migrated.fsrsStep,
        'fsrs_reps': migrated.fsrsReps,
        'fsrs_lapses': migrated.fsrsLapses,
        'fsrs_migrated': migrated.fsrsMigrated ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [progress.id],
    );
  }
}

/// The whole version 6 step.
Future<void> migrateSrsToFsrs(Database db) async {
  await addFsrsColumns(db);
  await backfillFsrsState(db);
}

Future<Set<String>> _columnNames(Database db, String table) async {
  final rows = await db.rawQuery('PRAGMA table_info($table)');
  return rows
      .map((row) => row['name']?.toString() ?? '')
      .where((name) => name.isNotEmpty)
      .toSet();
}
