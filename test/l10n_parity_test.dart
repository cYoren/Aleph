import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:original_bible/l10n/generated/app_localizations.dart';

Set<String> _arbKeys(File file) {
  final jsonMap = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return jsonMap.keys.where((key) => !key.startsWith('@')).toSet();
}

void main() {
  test('ARB key parity across all supported locales', () {
    final root = Directory.current.path;
    final l10nDir = Directory(p.join(root, 'lib', 'l10n'));
    final arbFiles =
        l10nDir
            .listSync()
            .whereType<File>()
            .where((file) => p.basename(file.path).startsWith('app_'))
            .where((file) => file.path.endsWith('.arb'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    final enFile = arbFiles.firstWhere(
      (file) => p.basename(file.path) == 'app_en.arb',
    );
    final enKeys = _arbKeys(enFile);
    expect(enKeys, isNotEmpty, reason: 'English ARB must define keys.');

    for (final file in arbFiles) {
      final localeKeys = _arbKeys(file);
      expect(
        localeKeys,
        equals(enKeys),
        reason: '${p.basename(file.path)} keys must match app_en.arb',
      );
    }
  });

  test('generated localizations include zh and ko', () {
    final localeCodes = AppLocalizations.supportedLocales
        .map((locale) => locale.languageCode)
        .toSet();
    expect(localeCodes, contains('zh'));
    expect(localeCodes, contains('ko'));
  });
}
