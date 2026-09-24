/// "What does my name mean?": a typed name, matched against a curated list of
/// Bible names, shown in its original script with its traditional meaning.
///
/// The list is hand-authored in `assets/names.json` because meanings parsed
/// from lexicon prose were wrong too often ("BH id.", "of Persian
/// derivation") for something people share with their name on it.
library;

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/utils/search_fold.dart';

class BibleName {
  final String strongs;
  final Map<String, String> meaning;
  final List<String> names;
  final bool showCount;

  const BibleName({
    required this.strongs,
    required this.meaning,
    required this.names,
    required this.showCount,
  });

  bool get isHebrew => strongs.startsWith('H');

  String meaningIn(String language) => meaning[language] ?? meaning['en']!;

  factory BibleName.fromJson(Map<String, dynamic> json) => BibleName(
    strongs: json['strongs'] as String,
    meaning: Map<String, String>.from(json['meaning'] as Map),
    names: List<String>.from(json['names'] as List),
    showCount: json['showCount'] as bool? ?? true,
  );
}

/// Entries whose spellings include [query], exact matches first.
///
/// Accents and case are ignored, so "joao" finds João. A prefix match only
/// counts from three letters on, so "a" does not list half the Bible.
List<BibleName> matchNames(List<BibleName> all, String query) {
  final q = foldForSearch(query.trim());
  if (q.isEmpty) return const [];
  final exact = <BibleName>[];
  final prefix = <BibleName>[];
  for (final entry in all) {
    final folded = entry.names.map(foldForSearch);
    if (folded.contains(q)) {
      exact.add(entry);
    } else if (q.length >= 3 && folded.any((n) => n.startsWith(q))) {
      prefix.add(entry);
    }
  }
  return [...exact, ...prefix];
}

final bibleNamesProvider = FutureProvider<List<BibleName>>((ref) async {
  final raw = await rootBundle.loadString('assets/names.json');
  final list = (jsonDecode(raw) as Map<String, dynamic>)['names'] as List;
  return list
      .map((e) => BibleName.fromJson(e as Map<String, dynamic>))
      .toList();
});
