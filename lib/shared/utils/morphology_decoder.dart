/// Utility class for decoding morphology codes into human-readable format.
///
/// Supports:
/// - Hebrew morphology (OSHM - OpenScriptures Hebrew Morphology)
/// - Greek morphology (Robinson's Morphological Analysis Codes)
class MorphologyDecoder {
  /// Decode a morphology code based on language
  static String decode(String code, {required bool isHebrew}) {
    if (code.isEmpty) return '';

    if (isHebrew) {
      return decodeHebrew(code);
    } else {
      return decodeGreek(code);
    }
  }

  /// Decode a code and render each label in the reader's language.
  ///
  /// The English output of [decode] is what identifies a parsing, so it stays
  /// the stable key; [translate] (see `MorphologyLabels`) maps each label to
  /// the localized display string for the plain grammar a reader actually
  /// reads. Labels with no translation (verb stems such as "Qal") pass through.
  static String decodeLocalized(
    String code, {
    required bool isHebrew,
    required String Function(String) translate,
  }) {
    final decoded = decode(code, isHebrew: isHebrew);
    if (decoded.isEmpty) return decoded;
    return decoded
        .split(', ')
        .map(translate)
        .where((part) => part.isNotEmpty)
        .join(', ');
  }

  /// Decode Hebrew morphology code (OSHM format)
  /// Example: "HNcmsa" → "Hebrew Noun, common, masculine, singular, absolute"
  static String decodeHebrew(String code) {
    if (code.isEmpty) return '';

    final parts = <String>[];
    int index = 0;

    // Skip language prefix if present (H for Hebrew, A for Aramaic)
    if (code.startsWith('H') || code.startsWith('A')) {
      parts.add(code.startsWith('H') ? 'Hebrew' : 'Aramaic');
      index = 1;
    }

    if (index >= code.length) return parts.join(' ');

    // Part of speech
    final pos = code[index];
    final posName = _hebrewPartsOfSpeech[pos];
    if (posName != null) {
      parts.add(posName);
      index++;
    }

    // Parse remaining characters based on part of speech
    if (index < code.length) {
      final remaining = code.substring(index);

      switch (pos) {
        case 'N': // Noun
          parts.addAll(_parseHebrewNoun(remaining));
          break;
        case 'V': // Verb
          parts.addAll(_parseHebrewVerb(remaining));
          break;
        case 'A': // Adjective
          parts.addAll(_parseHebrewAdjective(remaining));
          break;
        case 'P': // Pronoun
          parts.addAll(_parseHebrewPronoun(remaining));
          break;
        case 'S': // Suffix
          parts.addAll(_parseHebrewSuffix(remaining));
          break;
        default:
          // For other parts of speech, try generic parsing
          parts.addAll(_parseHebrewGeneric(remaining));
      }
    }

    return parts.where((p) => p.isNotEmpty).join(', ');
  }

  /// Decode Greek morphology code (Robinson format)
  /// Example: "V-AAI-3S" → "Verb, Aorist, Active, Indicative, 3rd person, Singular"
  static String decodeGreek(String code) {
    if (code.isEmpty) return '';

    final parts = <String>[];

    // Split by hyphen if present
    final segments = code.split('-');

    if (segments.isEmpty) return '';

    // First segment is usually part of speech
    final pos = segments[0];
    final posName =
        _greekPartsOfSpeech[pos] ??
        (pos.isNotEmpty ? _greekPartsOfSpeech[pos[0]] : null);
    if (posName != null) {
      parts.add(posName);
    }

    // Parse based on part of speech
    if (pos.startsWith('V')) {
      parts.addAll(_parseGreekVerb(segments));
    } else if (pos.startsWith('N')) {
      parts.addAll(_parseGreekNoun(segments));
    } else if (pos.startsWith('A')) {
      parts.addAll(_parseGreekAdjective(segments));
    } else if (pos.startsWith('P')) {
      parts.addAll(_parseGreekPronoun(segments));
    } else if (pos.startsWith('D')) {
      parts.addAll(_parseGreekArticle(segments));
    } else {
      // Generic parsing for other types
      parts.addAll(_parseGreekGeneric(segments));
    }

    return parts.where((p) => p.isNotEmpty).join(', ');
  }

  // ========== Hebrew Parsing Helpers ==========

  /// The binyan (stem) of a Hebrew verb code, e.g. 'Vpw3ms' -> 'Qal'.
  ///
  /// Returns null for anything that is not a verb, so callers can fall back to
  /// the part of speech.
  static String? hebrewVerbStem(String code) {
    if (code.isEmpty) return null;
    var index = (code.startsWith('H') || code.startsWith('A')) ? 1 : 0;
    if (index >= code.length || code[index] != 'V') return null;
    index++;
    if (index >= code.length) return null;
    return _hebrewVerbStem[code[index]];
  }

  /// Tense and voice of a Greek verb code, e.g. 'V-AAI-3S' -> 'Aorist Active'.
  ///
  /// Returns null for anything that is not a verb.
  static String? greekTenseVoice(String code) {
    if (code.isEmpty || !code.startsWith('V')) return null;
    final segments = code.split('-');
    if (segments.length < 2 || segments[1].length < 2) return null;
    final tense = _greekTense[segments[1][0]];
    final voice = _greekVoice[segments[1][1]];
    if (tense == null || voice == null) return null;
    return '$tense $voice';
  }

  static List<String> _parseHebrewNoun(String code) {
    final parts = <String>[];
    if (code.isEmpty) return parts;

    int i = 0;

    // Type (common/proper)
    if (i < code.length) {
      parts.add(_hebrewNounType[code[i]] ?? '');
      i++;
    }

    // Gender
    if (i < code.length) {
      parts.add(_hebrewGender[code[i]] ?? '');
      i++;
    }

    // Number
    if (i < code.length) {
      parts.add(_hebrewNumber[code[i]] ?? '');
      i++;
    }

    // State
    if (i < code.length) {
      parts.add(_hebrewState[code[i]] ?? '');
      i++;
    }

    return parts;
  }

  static List<String> _parseHebrewVerb(String code) {
    final parts = <String>[];
    if (code.isEmpty) return parts;

    int i = 0;

    // Stem
    if (i < code.length) {
      parts.add(_hebrewVerbStem[code[i]] ?? '');
      i++;
    }

    // Conjugation/Aspect
    if (i < code.length) {
      parts.add(_hebrewVerbConjugation[code[i]] ?? '');
      i++;
    }

    // Person
    if (i < code.length) {
      parts.add(_hebrewPerson[code[i]] ?? '');
      i++;
    }

    // Gender
    if (i < code.length) {
      parts.add(_hebrewGender[code[i]] ?? '');
      i++;
    }

    // Number
    if (i < code.length) {
      parts.add(_hebrewNumber[code[i]] ?? '');
      i++;
    }

    return parts;
  }

  static List<String> _parseHebrewAdjective(String code) {
    final parts = <String>[];
    if (code.isEmpty) return parts;

    int i = 0;

    // Type
    if (i < code.length) {
      parts.add(_hebrewAdjectiveType[code[i]] ?? '');
      i++;
    }

    // Gender
    if (i < code.length) {
      parts.add(_hebrewGender[code[i]] ?? '');
      i++;
    }

    // Number
    if (i < code.length) {
      parts.add(_hebrewNumber[code[i]] ?? '');
      i++;
    }

    // State
    if (i < code.length) {
      parts.add(_hebrewState[code[i]] ?? '');
      i++;
    }

    return parts;
  }

  static List<String> _parseHebrewPronoun(String code) {
    final parts = <String>[];
    if (code.isEmpty) return parts;

    int i = 0;

    // Type
    if (i < code.length) {
      parts.add(_hebrewPronounType[code[i]] ?? '');
      i++;
    }

    // Person
    if (i < code.length) {
      parts.add(_hebrewPerson[code[i]] ?? '');
      i++;
    }

    // Gender
    if (i < code.length) {
      parts.add(_hebrewGender[code[i]] ?? '');
      i++;
    }

    // Number
    if (i < code.length) {
      parts.add(_hebrewNumber[code[i]] ?? '');
      i++;
    }

    return parts;
  }

  static List<String> _parseHebrewSuffix(String code) {
    final parts = <String>[];
    if (code.isEmpty) return parts;

    int i = 0;

    // Type
    if (i < code.length) {
      parts.add(_hebrewSuffixType[code[i]] ?? '');
      i++;
    }

    // Person
    if (i < code.length) {
      parts.add(_hebrewPerson[code[i]] ?? '');
      i++;
    }

    // Gender
    if (i < code.length) {
      parts.add(_hebrewGender[code[i]] ?? '');
      i++;
    }

    // Number
    if (i < code.length) {
      parts.add(_hebrewNumber[code[i]] ?? '');
      i++;
    }

    return parts;
  }

  static List<String> _parseHebrewGeneric(String code) {
    final parts = <String>[];
    for (int i = 0; i < code.length; i++) {
      final char = code[i];
      final decoded =
          _hebrewGender[char] ??
          _hebrewNumber[char] ??
          _hebrewPerson[char] ??
          _hebrewState[char] ??
          '';
      if (decoded.isNotEmpty) {
        parts.add(decoded);
      }
    }
    return parts;
  }

  // ========== Greek Parsing Helpers ==========

  static List<String> _parseGreekVerb(List<String> segments) {
    final parts = <String>[];

    if (segments.length >= 2) {
      final morphPart = segments[1];

      // Tense
      if (morphPart.isNotEmpty) {
        parts.add(_greekTense[morphPart[0]] ?? '');
      }

      // Voice
      if (morphPart.length > 1) {
        parts.add(_greekVoice[morphPart[1]] ?? '');
      }

      // Mood
      if (morphPart.length > 2) {
        parts.add(_greekMood[morphPart[2]] ?? '');
      }
    }

    if (segments.length >= 3) {
      final personNum = segments[2];

      // Person
      if (personNum.isNotEmpty) {
        parts.add(_greekPerson[personNum[0]] ?? '');
      }

      // Number
      if (personNum.length > 1) {
        parts.add(_greekNumber[personNum[1]] ?? '');
      }
    }

    return parts;
  }

  static List<String> _parseGreekNoun(List<String> segments) {
    final parts = <String>[];

    if (segments.length >= 2) {
      final casePart = segments[1];

      // Case
      if (casePart.isNotEmpty) {
        parts.add(_greekCase[casePart[0]] ?? '');
      }

      // Number
      if (casePart.length > 1) {
        parts.add(_greekNumber[casePart[1]] ?? '');
      }

      // Gender
      if (casePart.length > 2) {
        parts.add(_greekGender[casePart[2]] ?? '');
      }
    }

    return parts;
  }

  static List<String> _parseGreekAdjective(List<String> segments) {
    return _parseGreekNoun(segments); // Same parsing as noun
  }

  static List<String> _parseGreekArticle(List<String> segments) {
    return _parseGreekNoun(segments); // Same parsing as noun
  }

  static List<String> _parseGreekPronoun(List<String> segments) {
    final parts = <String>[];

    // Get pronoun type from first segment
    if (segments.isNotEmpty && segments[0].length > 1) {
      parts.add(_greekPronounType[segments[0].substring(1)] ?? '');
    }

    // Parse case/number/gender
    parts.addAll(_parseGreekNoun(segments));

    return parts;
  }

  static List<String> _parseGreekGeneric(List<String> segments) {
    final parts = <String>[];

    for (int i = 1; i < segments.length; i++) {
      final segment = segments[i];
      for (int j = 0; j < segment.length; j++) {
        final char = segment[j];
        final decoded =
            _greekCase[char] ??
            _greekNumber[char] ??
            _greekGender[char] ??
            _greekPerson[char] ??
            '';
        if (decoded.isNotEmpty) {
          parts.add(decoded);
        }
      }
    }

    return parts;
  }

  // ========== Hebrew Lookup Tables ==========

  static const _hebrewPartsOfSpeech = {
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

  static const _hebrewNounType = {
    'c': 'common',
    'p': 'proper',
    'g': 'gentilic',
  };

  static const _hebrewGender = {
    'm': 'masculine',
    'f': 'feminine',
    'b': 'both genders',
    'c': 'common',
  };

  static const _hebrewNumber = {'s': 'singular', 'p': 'plural', 'd': 'dual'};

  static const _hebrewState = {
    'a': 'absolute',
    'c': 'construct',
    'd': 'determined',
  };

  static const _hebrewPerson = {
    '1': '1st person',
    '2': '2nd person',
    '3': '3rd person',
  };

  static const _hebrewVerbStem = {
    'q': 'Qal',
    'N': 'Niphal',
    'p': 'Piel',
    'P': 'Pual',
    'h': 'Hiphil',
    'H': 'Hophal',
    't': 'Hithpael',
    'o': 'Polel',
    'O': 'Polal',
    'r': 'Hithpolel',
    'm': 'Poel',
    'M': 'Poal',
    'k': 'Palel',
    'K': 'Pulal',
    'Q': 'Qal Passive',
    'l': 'Pilpel',
    'L': 'Polpal',
    'f': 'Hithpalpel',
    'D': 'Nithpael',
    'j': 'Pealal',
    'i': 'Pilel',
    'u': 'Hothpaal',
    'c': 'Tiphil',
    'v': 'Hishtaphel',
    'w': 'Nithpalel',
    'y': 'Nithpoel',
    'z': 'Hithpoel',
  };

  static const _hebrewVerbConjugation = {
    'p': 'Perfect',
    'q': 'Sequential Perfect',
    'i': 'Imperfect',
    'w': 'Sequential Imperfect',
    'h': 'Cohortative',
    'j': 'Jussive',
    'v': 'Imperative',
    'r': 'Participle Active',
    's': 'Participle Passive',
    'a': 'Infinitive Absolute',
    'c': 'Infinitive Construct',
  };

  static const _hebrewAdjectiveType = {
    'a': 'adjective',
    'c': 'cardinal number',
    'g': 'gentilic',
    'o': 'ordinal number',
  };

  static const _hebrewPronounType = {
    'd': 'demonstrative',
    'f': 'indefinite',
    'i': 'interrogative',
    'p': 'personal',
    'r': 'relative',
  };

  static const _hebrewSuffixType = {
    'd': 'directional',
    'h': 'paragogic he',
    'n': 'paragogic nun',
    'p': 'pronominal',
  };

  // ========== Greek Lookup Tables ==========

  static const _greekPartsOfSpeech = {
    'V': 'Verb',
    'N': 'Noun',
    'A': 'Adjective',
    'D': 'Article',
    'P': 'Pronoun',
    'C': 'Conjunction',
    'R': 'Preposition',
    'X': 'Particle',
    'I': 'Interjection',
    'ADV': 'Adverb',
    'CONJ': 'Conjunction',
    'PREP': 'Preposition',
    'PRT': 'Particle',
  };

  static const _greekTense = {
    'P': 'Present',
    'I': 'Imperfect',
    'F': 'Future',
    'A': 'Aorist',
    'R': 'Perfect',
    'L': 'Pluperfect',
    'X': 'No tense',
  };

  static const _greekVoice = {
    'A': 'Active',
    'M': 'Middle',
    'P': 'Passive',
    'E': 'Middle/Passive',
    'D': 'Middle Deponent',
    'O': 'Passive Deponent',
    'N': 'Middle/Passive Deponent',
  };

  static const _greekMood = {
    'I': 'Indicative',
    'S': 'Subjunctive',
    'O': 'Optative',
    'M': 'Imperative',
    'N': 'Infinitive',
    'P': 'Participle',
    'R': 'Imperative',
  };

  static const _greekPerson = {
    '1': '1st person',
    '2': '2nd person',
    '3': '3rd person',
  };

  static const _greekNumber = {'S': 'Singular', 'P': 'Plural', 'D': 'Dual'};

  static const _greekCase = {
    'N': 'Nominative',
    'G': 'Genitive',
    'D': 'Dative',
    'A': 'Accusative',
    'V': 'Vocative',
  };

  static const _greekGender = {
    'M': 'Masculine',
    'F': 'Feminine',
    'N': 'Neuter',
  };

  static const _greekPronounType = {
    'P': 'Personal',
    'R': 'Relative',
    'D': 'Demonstrative',
    'C': 'Reciprocal',
    'I': 'Interrogative',
    'X': 'Indefinite',
    'F': 'Reflexive',
    'S': 'Possessive',
    'K': 'Correlative',
  };

  /// Get a color for part of speech for visual distinction
  static int getPartOfSpeechColor(String code, {required bool isHebrew}) {
    if (code.isEmpty) return 0xFF757575; // Grey

    String pos;
    if (isHebrew) {
      pos = code.startsWith('H') || code.startsWith('A')
          ? (code.length > 1 ? code[1] : '')
          : code[0];
    } else {
      pos = code.split('-').first;
      if (pos.isNotEmpty) pos = pos[0];
    }

    return switch (pos) {
      'V' => 0xFF1976D2, // Blue - Verb
      'N' => 0xFF388E3C, // Green - Noun
      'A' => 0xFF7B1FA2, // Purple - Adjective
      'P' => 0xFFF57C00, // Orange - Pronoun
      'D' => 0xFF00838F, // Teal - Article/Adverb
      'R' => 0xFF5D4037, // Brown - Preposition
      'C' => 0xFF455A64, // Blue Grey - Conjunction
      'T' || 'X' => 0xFF757575, // Grey - Particle
      _ => 0xFF757575, // Grey - Default
    };
  }
}
