import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:original_bible/data/database/migrations/srs_fsrs_migration.dart';
import 'package:original_bible/shared/utils/async_once.dart';

/// Separate database for user-generated content (bookmarks, notes, highlights)
/// This keeps the Bible data read-only and enables future sync capabilities
class UserDatabaseHelper {
  static final UserDatabaseHelper instance = UserDatabaseHelper._init();
  static final AsyncOnce<Database> _databaseLoader = AsyncOnce<Database>();

  UserDatabaseHelper._init();

  Future<Database> get database async {
    return _databaseLoader.getOrCreate(() => _initDB('user_data.db'));
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final dbFilePath = path.join(dbPath, fileName);

    // Ensure directory exists
    await Directory(path.dirname(dbFilePath)).create(recursive: true);

    return await openDatabase(
      dbFilePath,
      version: 6,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Per-review history, one row per answered card.
  ///
  /// Nothing schedules from this — FSRS keeps its own state on `srs_progress`.
  /// It exists because fitting the FSRS weights to a reader needs the rating and
  /// the elapsed interval of every past review, and history cannot be
  /// reconstructed after the fact.
  Future<void> _createReviewLogTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS srs_reviews (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        strongs_id TEXT NOT NULL,
        reviewed_at INTEGER NOT NULL,
        grade INTEGER NOT NULL,
        rating INTEGER,
        repetitions_before INTEGER NOT NULL DEFAULT 0,
        easiness_before REAL NOT NULL DEFAULT 2.5,
        interval_before REAL NOT NULL DEFAULT 0.0
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_srs_reviews_strongs '
      'ON srs_reviews(strongs_id)',
    );
  }

  Future<void> _createMemorizationTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS memorization_passages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_id TEXT NOT NULL,
        chapter INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        repetitions INTEGER NOT NULL DEFAULT 0,
        easiness REAL NOT NULL DEFAULT 2.5,
        interval_days REAL NOT NULL DEFAULT 0.0,
        mastery_score REAL NOT NULL DEFAULT 0.0,
        next_review_at INTEGER NOT NULL,
        last_practiced_at INTEGER,
        UNIQUE(book_id, chapter)
      )
    ''');
  }

  Future<void> _createSrsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS srs_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        strongs_id TEXT NOT NULL UNIQUE,
        exposure_count INTEGER NOT NULL DEFAULT 0,
        mastery_score REAL NOT NULL DEFAULT 0.0,
        next_review_at INTEGER NOT NULL,
        last_reviewed_at INTEGER NOT NULL,
        repetitions INTEGER NOT NULL DEFAULT 0,
        easiness REAL NOT NULL DEFAULT 2.5,
        interval_days REAL NOT NULL DEFAULT 0.0
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_srs_strongs_id ON srs_progress(strongs_id)',
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    if (kDebugMode) {
      debugPrint('UserDatabaseHelper: Creating user database tables');
    }

    // Bookmarks table
    await db.execute('''
      CREATE TABLE bookmarks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        verse_id TEXT NOT NULL UNIQUE,
        created_at INTEGER NOT NULL,
        collection_name TEXT
      )
    ''');

    // Index for faster lookups
    await db.execute(
      'CREATE INDEX idx_bookmarks_verse_id ON bookmarks(verse_id)',
    );

    // Notes table (for future use)
    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        verse_id TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Highlights table (for future use)
    await db.execute('''
      CREATE TABLE highlights (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        verse_id TEXT NOT NULL,
        color TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // Reading progress table (for future use)
    await db.execute('''
      CREATE TABLE reading_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plan_id TEXT NOT NULL,
        day_number INTEGER NOT NULL,
        completed_at INTEGER,
        UNIQUE(plan_id, day_number)
      )
    ''');

    // Spaced Repetition System table
    await _createSrsTable(db);
    await _createReviewLogTable(db);
    await addFsrsColumns(db);

    // Passage memorization table
    await _createMemorizationTable(db);

    if (kDebugMode) {
      debugPrint('UserDatabaseHelper: Tables created successfully');
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (kDebugMode) {
      debugPrint(
        'UserDatabaseHelper: Upgrading from $oldVersion to $newVersion',
      );
    }

    if (oldVersion < 2) {
      // Creates the table with the current schema, so no further migration
      // steps are needed for this database.
      await _createSrsTable(db);
    } else if (oldVersion < 3) {
      // SM-2 state columns for the spaced-repetition upgrade.
      await db.execute(
        'ALTER TABLE srs_progress ADD COLUMN repetitions INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE srs_progress ADD COLUMN easiness REAL NOT NULL DEFAULT 2.5',
      );
      await db.execute(
        'ALTER TABLE srs_progress ADD COLUMN interval_days REAL NOT NULL DEFAULT 0.0',
      );
    }

    if (oldVersion < 4) {
      await _createMemorizationTable(db);
    }

    if (oldVersion < 5) {
      await _createReviewLogTable(db);
    }

    if (oldVersion < 6) {
      // FSRS replaced SM-2 as the scheduler. The SM-2 rows are the only thing
      // that can seed it, so this runs after every earlier step has guaranteed
      // the columns it reads.
      await migrateSrsToFsrs(db);
    }
  }

  /// Close the database
  Future<void> close() async {
    final database = _databaseLoader.valueOrNull;
    if (database != null && database.isOpen) {
      await database.close();
    }
    _databaseLoader.clear();
  }
}
