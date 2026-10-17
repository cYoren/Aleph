import 'dart:io';

/// Decompresses a gzip block produced by `scripts/prepare_bible_db.py`.
///
/// `bytes` is the raw BLOB straight out of SQLite. Throws [FormatException] on
/// anything that is not a gzip stream, which the callers treat as "this
/// database is not compacted".
List<int> gunzipBytes(List<int> bytes) => gzip.decode(bytes);
