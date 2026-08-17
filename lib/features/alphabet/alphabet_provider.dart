/// The beginner's letter reference, loaded from `assets/alphabet.json`.
///
/// Kept as an asset rather than Dart constants so the sound hints can be
/// translated by the same offline batch pipeline that translates the lexicon
/// glosses, without a recompile.
library;

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/database_provider.dart';
import '../settings/settings_provider.dart';

enum SourceAlphabet { hebrew, greek }

class AlphabetLetter {
  final String id;
  final String glyph;

  /// Word-final form, where the letter has one (Hebrew kaf, mem, nun, pe,
  /// tsade). Null for every Greek letter.
  final String? finalForm;
  final String name;
  final String transliteration;
  final int? numericValue;

  /// Lexicon key for the example word, so its meaning can be shown in the
  /// reader's own language when a translated gloss exists.
  final String? strongs;
  final String? lemma;
  final String? lemmaTransliteration;

  /// English meaning of the example word, used until a translated gloss for
  /// [strongs] is available.
  final String? gloss;

  const AlphabetLetter({
    required this.id,
    required this.glyph,
    required this.name,
    required this.transliteration,
    this.finalForm,
    this.numericValue,
    this.strongs,
    this.lemma,
    this.lemmaTransliteration,
    this.gloss,
  });

  factory AlphabetLetter.fromJson(Map<String, dynamic> json) {
    return AlphabetLetter(
      id: json['id']?.toString() ?? '',
      glyph: json['glyph']?.toString() ?? '',
      finalForm: json['final']?.toString(),
      name: json['name']?.toString() ?? '',
      transliteration: json['translit']?.toString() ?? '',
      numericValue: (json['value'] as num?)?.toInt(),
      strongs: json['strongs']?.toString(),
      lemma: json['lemma']?.toString(),
      lemmaTransliteration: json['lemmaTranslit']?.toString(),
      gloss: json['gloss']?.toString(),
    );
  }

  bool get hasExample => lemma != null && lemma!.isNotEmpty;
}

class AlphabetChart {
  final String fontFamily;
  final bool isRtl;
  final List<AlphabetLetter> letters;

  /// Hebrew pointing. Empty for Greek, whose vowels are letters in their own
  /// right.
  final List<AlphabetLetter> vowels;

  const AlphabetChart({
    required this.fontFamily,
    required this.isRtl,
    required this.letters,
    required this.vowels,
  });

  factory AlphabetChart.fromJson(Map<String, dynamic> json) {
    List<AlphabetLetter> parse(String key) {
      final raw = json[key];
      if (raw is! List) return const [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(AlphabetLetter.fromJson)
          .toList();
    }

    return AlphabetChart(
      fontFamily: json['font']?.toString() ?? 'Gentium',
      isRtl: json['direction']?.toString() == 'rtl',
      letters: parse('letters'),
      vowels: parse('vowels'),
    );
  }
}

/// Both charts plus the localized sound hints for the current interface
/// language.
class AlphabetReference {
  final AlphabetChart hebrew;
  final AlphabetChart greek;
  final Map<String, String> _hints;

  const AlphabetReference({
    required this.hebrew,
    required this.greek,
    required Map<String, String> hints,
  }) : _hints = hints;

  AlphabetChart chart(SourceAlphabet alphabet) =>
      alphabet == SourceAlphabet.hebrew ? hebrew : greek;

  /// Sound description for a letter, or empty when no locale has one.
  String hintFor(String letterId) => _hints[letterId] ?? '';
}

final _alphabetJsonProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final raw = await rootBundle.loadString('assets/alphabet.json');
  return jsonDecode(raw) as Map<String, dynamic>;
});

final _alphabetHintsJsonProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final raw = await rootBundle.loadString('assets/alphabet_hints.json');
  return jsonDecode(raw) as Map<String, dynamic>;
});

final alphabetReferenceProvider = FutureProvider<AlphabetReference>((
  ref,
) async {
  final data = await ref.watch(_alphabetJsonProvider.future);
  final hintsByLocale = await ref.watch(_alphabetHintsJsonProvider.future);
  final language = ref.watch(settingsProvider.select((s) => s.appLanguage));

  // Per-locale hints layered over English, so a partially translated locale
  // shows translated lines where it has them and English everywhere else,
  // rather than blank cells.
  Map<String, String> asStringMap(Object? raw) {
    if (raw is! Map) return const {};
    return {
      for (final entry in raw.entries)
        entry.key.toString(): entry.value.toString(),
    };
  }

  final hints = <String, String>{
    ...asStringMap(hintsByLocale['en']),
    ...asStringMap(hintsByLocale[language]),
  };

  return AlphabetReference(
    hebrew: AlphabetChart.fromJson(
      (data['hebrew'] as Map).cast<String, dynamic>(),
    ),
    greek: AlphabetChart.fromJson(
      (data['greek'] as Map).cast<String, dynamic>(),
    ),
    hints: hints,
  );
});

/// Meanings of the guide's example words, in the reader's own language.
///
/// Read through [bibleDaoProvider], which already resolves the localized gloss
/// when one exists — so the alphabet page becomes Portuguese the moment the
/// lexicon does, with no separate translation of its own. Falls back to the
/// English gloss carried in the asset.
final alphabetExampleGlossesProvider = FutureProvider<Map<String, String>>((
  ref,
) async {
  final reference = await ref.watch(alphabetReferenceProvider.future);
  final ids = [
    ...reference.hebrew.letters,
    ...reference.greek.letters,
  ].map((letter) => letter.strongs).whereType<String>().toList();

  if (ids.isEmpty) return const {};

  final entries = await ref
      .watch(bibleDaoProvider)
      .getLexiconEntriesForStrongs(ids);

  return {
    for (final entry in entries.entries)
      if (entry.value.gloss != null && entry.value.gloss!.isNotEmpty)
        entry.key: entry.value.gloss!,
  };
});
