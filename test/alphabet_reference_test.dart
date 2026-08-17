/// Guards the beginner's letter reference.
///
/// The alphabet guide is the one screen aimed at someone who cannot read a
/// word of the script yet, so a missing hint or a wrong glyph is not a cosmetic
/// bug — it is the first thing they learn, learned wrong. These checks are
/// cheap and catch the whole class.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late Map<String, dynamic> alphabet;
  late Map<String, dynamic> hints;

  setUpAll(() {
    alphabet =
        jsonDecode(File('assets/alphabet.json').readAsStringSync())
            as Map<String, dynamic>;
    hints =
        jsonDecode(File('assets/alphabet_hints.json').readAsStringSync())
            as Map<String, dynamic>;
  });

  List<Map<String, dynamic>> section(String script, String key) {
    final chart = (alphabet[script] as Map).cast<String, dynamic>();
    return (chart[key] as List).cast<Map<String, dynamic>>();
  }

  group('alphabet asset', () {
    test('Hebrew has all 22 letters and 5 final forms', () {
      final letters = section('hebrew', 'letters');
      expect(letters, hasLength(22));

      final finals = letters.where((l) => l['final'] != null).toList();
      expect(
        finals.map((l) => l['id']),
        containsAll(['kaf', 'mem', 'nun', 'pe', 'tsade']),
        reason: 'these five are the letters that change shape word-finally',
      );
      expect(finals, hasLength(5));
    });

    test('Greek has all 24 letters', () {
      expect(section('greek', 'letters'), hasLength(24));
    });

    test('Hebrew letter values ascend', () {
      final values = section(
        'hebrew',
        'letters',
      ).map((l) => l['value'] as int).toList();
      expect(values.first, 1);
      expect(values.last, 400);
      for (var i = 1; i < values.length; i++) {
        expect(
          values[i],
          greaterThan(values[i - 1]),
          reason: 'gematria values must ascend through the alphabet',
        );
      }
    });

    test('Greek letter values ascend and skip the obsolete letters', () {
      final values = section(
        'greek',
        'letters',
      ).map((l) => l['value'] as int).toList();
      expect(values.first, 1);
      expect(values.last, 800);
      // Digamma (6) and koppa (90) are not letters of the classical alphabet,
      // so zeta is 7 and rho is 100.
      expect(values, isNot(contains(6)));
      expect(values, isNot(contains(90)));
    });

    test('every id is unique across both scripts', () {
      final ids = [
        ...section('hebrew', 'letters'),
        ...section('hebrew', 'vowels'),
        ...section('greek', 'letters'),
      ].map((entry) => entry['id'] as String).toList();

      expect(ids.toSet(), hasLength(ids.length));
    });

    test('every letter and vowel has an English sound hint', () {
      final english = (hints['en'] as Map).cast<String, dynamic>();
      final missing = <String>[];

      for (final entry in [
        ...section('hebrew', 'letters'),
        ...section('hebrew', 'vowels'),
        ...section('greek', 'letters'),
      ]) {
        final id = entry['id'] as String;
        final hint = english[id];
        if (hint is! String || hint.trim().isEmpty) missing.add(id);
      }

      expect(missing, isEmpty, reason: 'ids with no hint: $missing');
    });

    test('example words carry a Strong\'s id, a lemma and a fallback gloss', () {
      for (final entry in [
        ...section('hebrew', 'letters'),
        ...section('greek', 'letters'),
      ]) {
        final id = entry['id'];
        expect(entry['strongs'], isA<String>(), reason: '$id has no strongs');
        expect(entry['lemma'], isA<String>(), reason: '$id has no lemma');
        expect(
          entry['gloss'],
          isA<String>(),
          reason: '$id has no English gloss to fall back on',
        );
      }
    });

    test('translated hint locales only use known ids', () {
      final english = (hints['en'] as Map).cast<String, dynamic>();

      for (final entry in hints.entries) {
        if (entry.key.startsWith('_') || entry.key == 'en') continue;
        final locale = (entry.value as Map).cast<String, dynamic>();
        final unknown = locale.keys.where((k) => !english.containsKey(k));
        expect(
          unknown,
          isEmpty,
          reason: '${entry.key} has hints for unknown ids: $unknown',
        );
      }
    });
  });
}
