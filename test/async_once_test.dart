import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/shared/utils/async_once.dart';

void main() {
  group('Database init single-flight', () {
    test('runs only one initialization for concurrent callers', () async {
      final loader = AsyncOnce<int>();
      final completer = Completer<int>();
      var initCalls = 0;

      Future<int> create() {
        initCalls += 1;
        return completer.future;
      }

      final futures = List.generate(6, (_) => loader.getOrCreate(create));

      expect(initCalls, 1);

      completer.complete(42);

      final results = await Future.wait(futures);
      expect(results, everyElement(42));
    });

    test('retries after a failed initialization', () async {
      final loader = AsyncOnce<int>();
      var initCalls = 0;

      Future<int> create() async {
        initCalls += 1;
        if (initCalls == 1) {
          throw StateError('boom');
        }
        return 7;
      }

      await expectLater(loader.getOrCreate(create), throwsStateError);
      expect(await loader.getOrCreate(create), 7);
      expect(initCalls, 2);
    });
  });
}
