import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/data/database/database_mobile.dart';

/// The bundled database is 78 MB compressed and 234 MB unpacked; doing that on
/// the UI isolate is what Sentry showed as an app hang on iPads (ALEPH-1,
/// ALEPH-2), so it now runs in a background isolate. The isolate boundary lives
/// inside `unpackGzipBytes`; what these tests pin is that the bytes on disk are
/// still exactly the bundled database.
void main() {
  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('aleph-unpack-');
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test('writes the decompressed bytes to the target path', () async {
    final payload = Uint8List.fromList(
      List<int>.generate(200000, (i) => i % 251),
    );
    final target = '${temp.path}/bible.db';

    await unpackGzipBytes(Uint8List.fromList(gzip.encode(payload)), target);

    expect(await File(target).readAsBytes(), payload);
  });

  test('replaces an existing file of the same name', () async {
    final target = '${temp.path}/bible.db';
    await File(target).writeAsBytes(List<int>.filled(10, 0));

    final payload = Uint8List.fromList(List<int>.filled(1024, 42));
    await unpackGzipBytes(Uint8List.fromList(gzip.encode(payload)), target);

    expect(await File(target).readAsBytes(), payload);
  });

  test('surfaces a corrupt asset instead of reporting success', () async {
    await expectLater(
      unpackGzipBytes(
        Uint8List.fromList(<int>[1, 2, 3, 4]),
        '${temp.path}/bible.db',
      ),
      throwsA(isA<FormatException>()),
    );
  });
}
