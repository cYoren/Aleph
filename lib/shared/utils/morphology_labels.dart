/// Localized display names for the grammar labels `MorphologyDecoder` produces.
///
/// The decoder builds its output from fixed English tables ("Noun, common,
/// masculine, singular, absolute"). Those strings were shown verbatim in the
/// definition sheet and used as the answers in the parsing quiz, so every
/// reader who was not reading English met grammar in English — the one thing
/// this app exists to help them with.
///
/// This class maps each English label the decoder can emit onto a key in the
/// generated localizations, so the same parsing is spelled out in the reader's
/// language. The decoder itself stays English-keyed (it is also used to
/// *compare* parsings, where the exact string is what must stay stable); this
/// layer only translates for display.
library;

import '../../l10n/generated/app_localizations.dart';

/// English label (exactly as `MorphologyDecoder` emits it) to ARB key.
///
/// Where the decoder uses the same English word for a Hebrew and a Greek
/// category ("Imperfect", "masculine"/"Masculine"), both spellings point at the
/// same key so one translation covers both.
const Map<String, String> kMorphologyLabelKeys = {
  'Hebrew': 'morphHebrew',
  'Aramaic': 'morphAramaic',
  'Adjective': 'morphAdjective',
  'Conjunction': 'morphConjunction',
  'Adverb': 'morphAdverb',
  'Noun': 'morphNoun',
  'Pronoun': 'morphPronoun',
  'Preposition': 'morphPreposition',
  'Suffix': 'morphSuffix',
  'Particle': 'morphParticle',
  'Verb': 'morphVerb',
  'Article': 'morphArticle',
  'Interjection': 'morphInterjection',
  'common': 'morphCommon',
  'proper': 'morphProper',
  'gentilic': 'morphGentilic',
  'masculine': 'morphMasculine',
  'Masculine': 'morphMasculine',
  'feminine': 'morphFeminine',
  'Feminine': 'morphFeminine',
  'both genders': 'morphBothGenders',
  'neuter': 'morphNeuter',
  'Neuter': 'morphNeuter',
  'singular': 'morphSingular',
  'Singular': 'morphSingular',
  'plural': 'morphPlural',
  'Plural': 'morphPlural',
  'dual': 'morphDual',
  'Dual': 'morphDual',
  'absolute': 'morphAbsolute',
  'construct': 'morphConstruct',
  'determined': 'morphDetermined',
  '1st person': 'morphFirstPerson',
  '2nd person': 'morphSecondPerson',
  '3rd person': 'morphThirdPerson',
  'Perfect': 'morphPerfect',
  'Sequential Perfect': 'morphSequentialPerfect',
  'Imperfect': 'morphImperfect',
  'Sequential Imperfect': 'morphSequentialImperfect',
  'Cohortative': 'morphCohortative',
  'Jussive': 'morphJussive',
  'Imperative': 'morphImperative',
  'Participle Active': 'morphParticipleActive',
  'Participle Passive': 'morphParticiplePassive',
  'Infinitive Absolute': 'morphInfinitiveAbsolute',
  'Infinitive Construct': 'morphInfinitiveConstruct',
  'cardinal number': 'morphCardinalNumber',
  'ordinal number': 'morphOrdinalNumber',
  'demonstrative': 'morphDemonstrative',
  'Demonstrative': 'morphDemonstrative',
  'indefinite': 'morphIndefinite',
  'Indefinite': 'morphIndefinite',
  'interrogative': 'morphInterrogative',
  'Interrogative': 'morphInterrogative',
  'personal': 'morphPersonal',
  'Personal': 'morphPersonal',
  'relative': 'morphRelative',
  'Relative': 'morphRelative',
  'reciprocal': 'morphReciprocal',
  'reflexive': 'morphReflexive',
  'possessive': 'morphPossessive',
  'correlative': 'morphCorrelative',
  'directional': 'morphDirectional',
  'paragogic he': 'morphParagogicHe',
  'paragogic nun': 'morphParagogicNun',
  'pronominal': 'morphPronominal',
  'Present': 'morphPresent',
  'Future': 'morphFuture',
  'Aorist': 'morphAorist',
  'Pluperfect': 'morphPluperfect',
  'No tense': 'morphNoTense',
  'Active': 'morphActive',
  'Middle': 'morphMiddle',
  'Passive': 'morphPassive',
  'Middle/Passive': 'morphMiddlePassive',
  'Middle Deponent': 'morphMiddleDeponent',
  'Passive Deponent': 'morphPassiveDeponent',
  'Middle/Passive Deponent': 'morphMiddlePassiveDeponent',
  'Indicative': 'morphIndicative',
  'Subjunctive': 'morphSubjunctive',
  'Optative': 'morphOptative',
  'Infinitive': 'morphInfinitive',
  'Participle': 'morphParticiple',
  'Nominative': 'morphNominative',
  'Genitive': 'morphGenitive',
  'Dative': 'morphDative',
  'Accusative': 'morphAccusative',
  'Vocative': 'morphVocative',
};

/// Translates a decoded morphology label for display.
///
/// Any label the localizations do not name (a verb stem such as "Qal", which is
/// a transliteration of a Hebrew name rather than an English word) is returned
/// unchanged.
class MorphologyLabels {
  MorphologyLabels(this._byLabel);

  MorphologyLabels.of(AppLocalizations l10n)
    : _byLabel = {
        for (final entry in kMorphologyLabelKeys.entries)
          entry.key: _value(l10n, entry.value),
      };

  final Map<String, String> _byLabel;

  String label(String englishLabel) => _byLabel[englishLabel] ?? englishLabel;

  /// The map, suitable for passing into pure helpers such as `buildParsingQuiz`
  /// that have no `BuildContext`.
  Map<String, String> get map => _byLabel;

  static String _value(AppLocalizations l10n, String key) {
    // Exhaustive switch keeps the mapping honest: a new key that is added to the
    // map but not here is a compile error rather than a silent English leak.
    return switch (key) {
      'morphHebrew' => l10n.morphHebrew,
      'morphAramaic' => l10n.morphAramaic,
      'morphAdjective' => l10n.morphAdjective,
      'morphConjunction' => l10n.morphConjunction,
      'morphAdverb' => l10n.morphAdverb,
      'morphNoun' => l10n.morphNoun,
      'morphPronoun' => l10n.morphPronoun,
      'morphPreposition' => l10n.morphPreposition,
      'morphSuffix' => l10n.morphSuffix,
      'morphParticle' => l10n.morphParticle,
      'morphVerb' => l10n.morphVerb,
      'morphArticle' => l10n.morphArticle,
      'morphInterjection' => l10n.morphInterjection,
      'morphCommon' => l10n.morphCommon,
      'morphProper' => l10n.morphProper,
      'morphGentilic' => l10n.morphGentilic,
      'morphMasculine' => l10n.morphMasculine,
      'morphFeminine' => l10n.morphFeminine,
      'morphBothGenders' => l10n.morphBothGenders,
      'morphNeuter' => l10n.morphNeuter,
      'morphSingular' => l10n.morphSingular,
      'morphPlural' => l10n.morphPlural,
      'morphDual' => l10n.morphDual,
      'morphAbsolute' => l10n.morphAbsolute,
      'morphConstruct' => l10n.morphConstruct,
      'morphDetermined' => l10n.morphDetermined,
      'morphFirstPerson' => l10n.morphFirstPerson,
      'morphSecondPerson' => l10n.morphSecondPerson,
      'morphThirdPerson' => l10n.morphThirdPerson,
      'morphPerfect' => l10n.morphPerfect,
      'morphSequentialPerfect' => l10n.morphSequentialPerfect,
      'morphImperfect' => l10n.morphImperfect,
      'morphSequentialImperfect' => l10n.morphSequentialImperfect,
      'morphCohortative' => l10n.morphCohortative,
      'morphJussive' => l10n.morphJussive,
      'morphImperative' => l10n.morphImperative,
      'morphParticipleActive' => l10n.morphParticipleActive,
      'morphParticiplePassive' => l10n.morphParticiplePassive,
      'morphInfinitiveAbsolute' => l10n.morphInfinitiveAbsolute,
      'morphInfinitiveConstruct' => l10n.morphInfinitiveConstruct,
      'morphCardinalNumber' => l10n.morphCardinalNumber,
      'morphOrdinalNumber' => l10n.morphOrdinalNumber,
      'morphDemonstrative' => l10n.morphDemonstrative,
      'morphIndefinite' => l10n.morphIndefinite,
      'morphInterrogative' => l10n.morphInterrogative,
      'morphPersonal' => l10n.morphPersonal,
      'morphRelative' => l10n.morphRelative,
      'morphReciprocal' => l10n.morphReciprocal,
      'morphReflexive' => l10n.morphReflexive,
      'morphPossessive' => l10n.morphPossessive,
      'morphCorrelative' => l10n.morphCorrelative,
      'morphDirectional' => l10n.morphDirectional,
      'morphParagogicHe' => l10n.morphParagogicHe,
      'morphParagogicNun' => l10n.morphParagogicNun,
      'morphPronominal' => l10n.morphPronominal,
      'morphPresent' => l10n.morphPresent,
      'morphFuture' => l10n.morphFuture,
      'morphAorist' => l10n.morphAorist,
      'morphPluperfect' => l10n.morphPluperfect,
      'morphNoTense' => l10n.morphNoTense,
      'morphActive' => l10n.morphActive,
      'morphMiddle' => l10n.morphMiddle,
      'morphPassive' => l10n.morphPassive,
      'morphMiddlePassive' => l10n.morphMiddlePassive,
      'morphMiddleDeponent' => l10n.morphMiddleDeponent,
      'morphPassiveDeponent' => l10n.morphPassiveDeponent,
      'morphMiddlePassiveDeponent' => l10n.morphMiddlePassiveDeponent,
      'morphIndicative' => l10n.morphIndicative,
      'morphSubjunctive' => l10n.morphSubjunctive,
      'morphOptative' => l10n.morphOptative,
      'morphInfinitive' => l10n.morphInfinitive,
      'morphParticiple' => l10n.morphParticiple,
      'morphNominative' => l10n.morphNominative,
      'morphGenitive' => l10n.morphGenitive,
      'morphDative' => l10n.morphDative,
      'morphAccusative' => l10n.morphAccusative,
      'morphVocative' => l10n.morphVocative,
      _ => key,
    };
  }
}
