import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/features/names/bible_names.dart';

void main() {
  final all =
      ((jsonDecode(File('assets/names.json').readAsStringSync())
                  as Map<String, dynamic>)['names']
              as List)
          .map((e) => BibleName.fromJson(e as Map<String, dynamic>))
          .toList();

  test('every name has a meaning in all eight app languages', () {
    for (final entry in all) {
      for (final lang in ['en', 'pt', 'es', 'de', 'fr', 'ru', 'zh', 'ko']) {
        expect(entry.meaning[lang], isNotEmpty, reason: entry.strongs);
      }
    }
  });

  List<String> find(String q) =>
      matchNames(all, q).map((e) => e.strongs).toList();

  test('accents and case are ignored', () {
    expect(find('joao'), ['G2491']);
    expect(find('JOÃO'), ['G2491']);
  });

  test('names in other scripts match', () {
    expect(find('Иван'), ['G2491']);
    expect(find('요한'), ['G2491']);
  });

  test('a name shared by two people lists both', () {
    expect(find('Anna').toSet(), {'H2584', 'G451'});
  });

  test('short fragments do not list everything', () {
    expect(find('jo'), isEmpty);
    expect(find('gabr'), ['H1403']);
  });
}
