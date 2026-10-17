/// Gzip decoding for bundled data, kept behind a conditional import so the
/// shared database code never pulls `dart:io` into a web build.
///
/// The release database stores its syntax trees as gzip blocks (see
/// `scripts/prepare_bible_db.py`), so reading them needs a decoder that the
/// browser build cannot provide. Web has no bundled database at all
/// (`database_web.dart` throws), hence the stub.
library;

export 'gunzip_io.dart' if (dart.library.html) 'gunzip_web.dart';
