/// Web has no bundled database: `database_web.dart` refuses to open one, so
/// nothing can reach this path. It exists only to satisfy the conditional
/// import in `gunzip.dart` without dragging `dart:io` into a web build.
List<int> gunzipBytes(List<int> bytes) {
  throw UnsupportedError('The bundled database is not available on web.');
}
