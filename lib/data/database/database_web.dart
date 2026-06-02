import 'dart:async';

/// DatabaseHelper interface that matches the mobile version
/// but throws an error on web since large embedded DBs are not supported
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  DatabaseHelper._init();

  /// Throws an error on web - database requires backend API
  Future<dynamic> get database async {
    throw UnsupportedError(
      'Database access on web requires a backend API. '
      'The 100MB bible.db cannot be efficiently loaded in a browser. '
      'Please use the mobile app or implement a REST API backend.',
    );
  }
}
