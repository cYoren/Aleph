import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:original_bible/shared/utils/async_once.dart';

/// Bumped whenever the bundled `assets/bible.db.gz` gains content an already
/// installed copy would not have.
///
/// The on-device copy is written once and then reused forever, so without a
/// stamp a reader who installed an older build keeps that older database
/// indefinitely — which is exactly how cross-references came to look "not
/// implemented" for existing users while the asset had 343k of them.
/// Bump this on every regenerated release database.
const int kBundledDatabaseVersion = 6;

/// The database ships gzip-compressed to keep the app bundle small; the
/// uncompressed form is written to the device on first launch.
const String kBundledDatabaseAsset = 'assets/bible.db.gz';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static final AsyncOnce<Database> _databaseLoader = AsyncOnce<Database>();

  /// Test seam: when set, [database] returns this connection instead of the
  /// bundled asset. Tests build a minimal in-memory schema to exercise the DAO
  /// against controlled rows.
  @visibleForTesting
  static Database? debugOverrideDatabase;

  static const Set<String> _requiredTables = {
    'books',
    'verses',
    'translations',
    'translation_verses',
    'translation_ref_map',
    'words',
    'lexicon',
    'cross_references',
    'syntax_trees',
    // The depth layers. A stale install that lacks one of these would show a
    // sheet or a pane with nothing in it and report no error, which is the
    // defect PAPERCUTS records for cross-references.
    'lexicon_senses',
    'lexicon_roots',
    'textual_variants',
  };

  DatabaseHelper._init();

  Future<Database> get database async {
    final override = debugOverrideDatabase;
    if (override != null) return override;
    return _databaseLoader.getOrCreate(() => _initDB('bible.db'));
  }

  @visibleForTesting
  Future<void> resetForTesting() async {
    debugOverrideDatabase = null;
    final database = _databaseLoader.valueOrNull;
    if (database != null && database.isOpen) {
      await database.close();
    }
    _databaseLoader.clear();
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final dbFilePath = path.join(dbPath, fileName);
    final stampFile = File('$dbFilePath.version');

    // Check if database file exists AND has data
    bool needsCopy = true;

    // A stale stamp forces a recopy even when every table is present: the
    // schema can be complete while the *content* is a release behind.
    final bool stampIsCurrent =
        await _readStamp(stampFile) == kBundledDatabaseVersion;

    if (!stampIsCurrent && await File(dbFilePath).exists()) {
      if (kDebugMode) {
        debugPrint('Bundled database is newer than the local copy, recopying');
      }
      try {
        await File(dbFilePath).delete();
      } catch (_) {}
    }

    if (await File(dbFilePath).exists()) {
      // Check if the database has ALL required tables (including translations)
      try {
        final testDb = await openDatabase(dbFilePath, readOnly: true);
        final tableRows = await testDb.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table'",
        );
        await testDb.close();
        final existingTables = tableRows
            .map((row) => row['name']?.toString() ?? '')
            .where((name) => name.isNotEmpty)
            .toSet();
        final missingTables = _requiredTables.difference(existingTables);

        if (missingTables.isEmpty) {
          needsCopy = false;
          if (kDebugMode) {
            debugPrint('Database exists with all tables, using existing DB');
          }
        } else {
          if (kDebugMode) {
            debugPrint(
              'Database missing required tables (${missingTables.join(', ')}), will recopy',
            );
          }
          // Delete the incomplete database
          await File(dbFilePath).delete();
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error checking database: $e, will recopy');
        }
        // Delete corrupted database
        try {
          await File(dbFilePath).delete();
        } catch (_) {}
      }
    }

    if (needsCopy) {
      if (kDebugMode) {
        debugPrint('Unpacking database from assets...');
      }

      try {
        // Ensure directory exists
        await Directory(path.dirname(dbFilePath)).create(recursive: true);

        await unpackBundledDatabase(dbFilePath);

        // Written only after the copy succeeds, so an interrupted copy is
        // retried on the next launch rather than being trusted.
        await stampFile.writeAsString('$kBundledDatabaseVersion', flush: true);

        if (kDebugMode) {
          debugPrint('Database unpacked successfully to $dbFilePath');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error unpacking database: $e');
        }
        rethrow;
      }
    }

    return await openDatabase(dbFilePath, readOnly: true);
  }

  /// Version of the database currently on disk, or null when unknown.
  Future<int?> _readStamp(File stampFile) async {
    try {
      if (!await stampFile.exists()) return null;
      return int.tryParse((await stampFile.readAsString()).trim());
    } catch (_) {
      return null;
    }
  }
}

/// Unpacks the bundled database into [targetPath], off the UI isolate.
///
/// The asset is ~78 MB compressed and ~234 MB on disk. Decompressing and writing
/// it on the main isolate blocks the Flutter UI for 2.5–4.1 s: Sentry ALEPH-1
/// and ALEPH-2 are exactly that, "App Hang Fully Blocked" on iPads, once per
/// fresh install. The bytes are handed to the isolate as
/// [TransferableTypedData] so the 78 MB is not copied a second time.
Future<void> unpackBundledDatabase(String targetPath) async {
  final ByteData data = await rootBundle.load(kBundledDatabaseAsset);
  await unpackGzipBytes(
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    targetPath,
  );
}

/// Runs `action` somewhere other than the isolate that is painting the screen.
typedef OffIsolateRunner = Future<T> Function<T>(Future<T> Function() action);

/// The production runner, exposed so a test can prove it really is a different
/// isolate rather than trust the call site.
@visibleForTesting
OffIsolateRunner defaultOffIsolateRunner = _runOffIsolate;

Future<T> _runOffIsolate<T>(Future<T> Function() action) =>
    Isolate.run(action);

/// Writes the gunzipped [bytes] to [targetPath] in a background isolate.
///
/// Exposed for tests: it is the part that used to block the UI thread, and it
/// must produce the same file the streaming copy did.
@visibleForTesting
Future<void> unpackGzipBytes(
  Uint8List bytes,
  String targetPath, {
  OffIsolateRunner runOffIsolate = _runOffIsolate,
}) {
  final transferable = TransferableTypedData.fromList(<Uint8List>[bytes]);
  return runOffIsolate(() async {
    final compressed = Stream<List<int>>.value(
      transferable.materialize().asUint8List(),
    );
    await gzip.decoder.bind(compressed).pipe(File(targetPath).openWrite());
  });
}
