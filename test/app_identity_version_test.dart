import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/shared/constants/app_identity.dart';

/// The About screen shows a version string, and a stale one is worse than
/// none: it sends bug reports to the wrong build. This ties the constant to
/// pubspec.yaml so a release bump that forgets it fails here.
void main() {
  test('AppIdentity version matches pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(
      r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)\s*$',
      multiLine: true,
    ).firstMatch(pubspec);

    expect(match, isNotNull, reason: 'pubspec.yaml has no version: line');
    expect(AppIdentity.version, match!.group(1));
    expect(AppIdentity.buildNumber, match.group(2));
  });
}
