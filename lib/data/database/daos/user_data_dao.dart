import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;
import '../../models/bookmark.dart';
import '../user_database_helper.dart';

/// Data Access Object for user-generated content (bookmarks, notes, etc.)
class UserDataDAO {
  final UserDatabaseHelper _dbHelper = UserDatabaseHelper.instance;

  // ========== BOOKMARKS ==========

  /// Add a bookmark for a verse
  Future<int> addBookmark(String verseId, {String? collectionName}) async {
    final db = await _dbHelper.database;

    final bookmark = Bookmark(verseId: verseId, collectionName: collectionName);

    try {
      final id = await db.insert(
        'bookmarks',
        bookmark.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (kDebugMode) {
        debugPrint('UserDataDAO: Added bookmark for $verseId with id $id');
      }

      return id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('UserDataDAO: Error adding bookmark: $e');
      }
      rethrow;
    }
  }

  /// Remove a bookmark by verse ID
  Future<bool> removeBookmark(String verseId) async {
    final db = await _dbHelper.database;

    final count = await db.delete(
      'bookmarks',
      where: 'verse_id = ?',
      whereArgs: [verseId],
    );

    if (kDebugMode) {
      debugPrint('UserDataDAO: Removed $count bookmark(s) for $verseId');
    }

    return count > 0;
  }

  /// Toggle bookmark for a verse (add if not exists, remove if exists)
  Future<bool> toggleBookmark(String verseId, {String? collectionName}) async {
    final isCurrentlyBookmarked = await isBookmarked(verseId);

    if (isCurrentlyBookmarked) {
      await removeBookmark(verseId);
      return false;
    } else {
      await addBookmark(verseId, collectionName: collectionName);
      return true;
    }
  }

  /// Check if a verse is bookmarked
  Future<bool> isBookmarked(String verseId) async {
    final db = await _dbHelper.database;

    final result = await db.query(
      'bookmarks',
      where: 'verse_id = ?',
      whereArgs: [verseId],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  /// Get all bookmarks
  Future<List<Bookmark>> getBookmarks({String? collectionName}) async {
    final db = await _dbHelper.database;

    List<Map<String, dynamic>> result;

    if (collectionName != null) {
      result = await db.query(
        'bookmarks',
        where: 'collection_name = ?',
        whereArgs: [collectionName],
        orderBy: 'created_at DESC',
      );
    } else {
      result = await db.query('bookmarks', orderBy: 'created_at DESC');
    }

    if (kDebugMode) {
      debugPrint('UserDataDAO: Found ${result.length} bookmarks');
    }

    return result.map((map) => Bookmark.fromMap(map)).toList();
  }

  /// Get bookmarked verse IDs as a Set for quick lookup
  Future<Set<String>> getBookmarkedVerseIds() async {
    final db = await _dbHelper.database;

    final result = await db.query('bookmarks', columns: ['verse_id']);

    return result.map((map) => map['verse_id'] as String).toSet();
  }

  /// Get bookmark count
  Future<int> getBookmarkCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM bookmarks');
    return result.first['count'] as int? ?? 0;
  }

  /// Get unique collection names
  Future<List<String>> getCollections() async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery('''
      SELECT DISTINCT collection_name 
      FROM bookmarks 
      WHERE collection_name IS NOT NULL
      ORDER BY collection_name
    ''');

    return result
        .where((map) => map['collection_name'] != null)
        .map((map) => map['collection_name'] as String)
        .toList();
  }
}
