import 'dart:io';
import 'dart:isolate';
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

  // The bug ALEPH-1/ALEPH-2 reported was not "the unpack is slow" but "the unpack
  // is slow *on the screen the reader is looking at*". Counting timer ticks is
  // the wrong probe: awaiting file I/O yields even when a synchronous gunzip is
  // on the caller's isolate, so a reverted implementation could still look fine.
  // Asking the production runner to report its own isolate id cannot be faked.
  test('the production runner really runs on another isolate', () async {
    final callerIsolate = Isolate.current.hashCode;
    final workIsolate =
        await defaultOffIsolateRunner(() async => Isolate.current.hashCode);
    expect(workIsolate, isNot(callerIsolate));
  });

  // Deterministic version of the test above, so the guarantee does not depend on
  // how fast this machine decompresses. If the unpack ever runs before (or
  // instead of) the off-isolate runner, the file exists and this fails.
  test('writes nothing unless the off-isolate runner runs the work', () async {
    final payload = Uint8List.fromList(List<int>.filled(2048, 7));
    final target = '${temp.path}/bible.db';
    var requests = 0;

    await expectLater(
      unpackGzipBytes(
        Uint8List.fromList(gzip.encode(payload)),
        target,
        runOffIsolate: <T>(Future<T> Function() action) async {
          requests++;
          // Refuse the work, the way a dead isolate would.
          throw StateError('not run');
        },
      ),
      throwsA(isA<StateError>()),
    );

    expect(requests, 1, reason: 'the decode must be handed to the runner');
    expect(
      await File(target).exists(),
      isFalse,
      reason: 'the caller isolate decompressed instead of the runner',
    );
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
