/// Paradigm support: the forms of one word that actually occur in the text.
///
/// The app ships no conjugation tables, and inventing them would be a promise
/// the data cannot keep (a full paradigm would mean generating forms no one
/// ever wrote). What the corpus does give, honestly, is every attested form of
/// a lemma with its morphology — which answers the question a learner is really
/// asking after reading a word: "what else does this word do?"
///
/// So this groups attested forms the way a paradigm table is read: Hebrew verbs
/// by binyan (stem), Greek verbs by tense and voice, everything else by part of
/// speech.
library;

import 'morphology_decoder.dart';

/// One form as it appears in the text, with how often it occurs.
class AttestedForm {
  final String form;
  final String morph;
  final int count;

  const AttestedForm({
    required this.form,
    required this.morph,
    required this.count,
  });

  /// 'Qal, Perfect, 3rd person, masculine, singular' — the same decoding the
  /// definition sheet already uses for the tapped word.
  String decoded({required bool isHebrew}) =>
      MorphologyDecoder.decode(morph, isHebrew: isHebrew);
}

/// All attested forms that share one grammatical label.
class ParadigmGroup {
  final String label;
  final List<AttestedForm> forms;

  const ParadigmGroup({required this.label, required this.forms});

  int get totalCount => forms.fold<int>(0, (sum, form) => sum + form.count);
}

/// Order in which groups are presented: the stems a learner meets first, then
/// the rest, then non-verbal parts of speech.
const _hebrewStemOrder = [
  'Qal',
  'Niphal',
  'Piel',
  'Pual',
  'Hiphil',
  'Hophal',
  'Hithpael',
];

const _greekTenseOrder = [
  'Present',
  'Imperfect',
  'Future',
  'Aorist',
  'Perfect',
  'Pluperfect',
];

/// Builds the grouped list from raw (form, morph) pairs keyed by frequency.
///
/// [entries] maps a form plus morphology to its occurrence count; the same
/// surface form with two parsings stays two rows, because that ambiguity is
/// itself worth seeing.
List<ParadigmGroup> buildParadigmGroups({
  required Iterable<({String form, String morph, int count})> entries,
  required bool isHebrew,
}) {
  final buckets = <String, List<AttestedForm>>{};

  for (final entry in entries) {
    final form = entry.form.trim();
    if (form.isEmpty || entry.count <= 0) continue;
    final label = groupLabelFor(entry.morph, isHebrew: isHebrew);
    buckets
        .putIfAbsent(label, () => [])
        .add(AttestedForm(form: form, morph: entry.morph, count: entry.count));
  }

  final groups = buckets.entries
      .map((e) => ParadigmGroup(label: e.key, forms: e.value))
      .toList();

  for (final group in groups) {
    group.forms.sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      return byCount != 0 ? byCount : a.form.compareTo(b.form);
    });
  }

  groups.sort((a, b) {
    final rank = _rankOf(a.label, isHebrew) - _rankOf(b.label, isHebrew);
    if (rank != 0) return rank;
    return b.totalCount.compareTo(a.totalCount);
  });

  return groups;
}

int _rankOf(String label, bool isHebrew) {
  if (isHebrew) {
    final index = _hebrewStemOrder.indexOf(label);
    if (index >= 0) return index;
    // Non-verbal parts of speech come after every stem.
    return _hebrewStemOrder.length + 1;
  }
  final tense = label.split(' · ').first;
  final index = _greekTenseOrder.indexOf(tense);
  if (index >= 0) return index;
  return _greekTenseOrder.length + 1;
}

/// The paradigm label for one morphology code.
///
/// Hebrew: the binyan for verbs ('Qal'), the part of speech otherwise.
/// Greek: 'Aorist Active' for verbs, the part of speech otherwise.
String groupLabelFor(String morph, {required bool isHebrew}) {
  if (morph.isEmpty) return '';
  if (isHebrew) {
    final stem = MorphologyDecoder.hebrewVerbStem(morph);
    if (stem != null) return stem;
    return _hebrewPosLabel(morph);
  }
  final tenseVoice = MorphologyDecoder.greekTenseVoice(morph);
  if (tenseVoice != null) return tenseVoice;
  return _greekPosLabel(morph);
}

const _hebrewPosLabels = {
  'A': 'Adjective',
  'C': 'Conjunction',
  'D': 'Adverb',
  'N': 'Noun',
  'P': 'Pronoun',
  'R': 'Preposition',
  'S': 'Suffix',
  'T': 'Particle',
  'V': 'Verb',
};

const _greekPosLabels = {
  'V': 'Verb',
  'N': 'Noun',
  'A': 'Adjective',
  'D': 'Article',
  'P': 'Pronoun',
  'C': 'Conjunction',
  'R': 'Preposition',
  'X': 'Particle',
  'I': 'Interjection',
};

String _hebrewPosLabel(String morph) {
  final index = (morph.startsWith('H') || morph.startsWith('A')) ? 1 : 0;
  if (index >= morph.length) return '';
  return _hebrewPosLabels[morph[index]] ?? '';
}

String _greekPosLabel(String morph) {
  final pos = morph.split('-').first;
  if (pos.isEmpty) return '';
  return _greekPosLabels[pos] ?? _greekPosLabels[pos[0]] ?? '';
}
