import '../../data/models/word.dart';
import '../../data/models/syntax_node.dart';

/// Builds a heuristic syntax tree from a list of verse words.
///
/// Since the Bible database has no formal dependency/head-word links,
/// this parser uses grammatical Part-of-Speech ordering heuristics:
///
/// 1. The first **Verb** becomes the root.
/// 2. **Nouns** left of the Verb → "Subject"
/// 3. **Nouns** right of the Verb → "Object" / "Complement"
/// 4. **Adjectives** → attach to the nearest preceding Noun
/// 5. **Preposition + following Noun** → compound "Prep. Phrase" on root
/// 6. **Conjunctions** → sibling bridge nodes on root
/// 7. Remaining words → "Other" on root
/// 8. If no Verb found → first Noun is root
class SyntaxTreeParser {
  /// Parses [words] into a [SyntaxNode] tree.
  static SyntaxNode parse(List<Word> words, {required bool isHebrew}) {
    if (words.isEmpty) {
      // Shouldn't happen in practice — caller guards for empty before showing screen
      return SyntaxNode(
        word: Word(
          id: -1,
          verseId: '',
          position: 0,
          displayText: '?',
          language: isHebrew ? 'heb' : 'grc',
        ),
        role: 'Verse',
      );
    }

    // Decode POS for every word
    final posList = words.map((w) {
      final code = w.morphCode ?? '';
      return _getPos(code, isHebrew: isHebrew);
    }).toList();

    // Find the main Verb (root)
    int rootIndex = posList.indexWhere((p) => p == 'V');
    if (rootIndex < 0) {
      // No verb — use the first noun, or first word
      rootIndex = posList.indexWhere((p) => p == 'N');
      if (rootIndex < 0) rootIndex = 0;
    }

    final rootWord = words[rootIndex];
    final rootRole = posList[rootIndex] == 'V' ? 'Verb' : 'Noun';

    // Track which word indices have been assigned to a node
    final assigned = <int>{rootIndex};

    final rootChildren = <SyntaxNode>[];

    // --- Pass 1: Build Noun Phrases (Noun + its preceding Adjectives) ---
    // We scan left-to-right and group each Noun with any immediately preceding
    // Adjectives.
    int i = 0;
    while (i < words.length) {
      if (assigned.contains(i) || posList[i] != 'N') {
        i++;
        continue;
      }

      // Gather preceding adjectives not yet assigned
      final adjChildren = <SyntaxNode>[];
      for (int j = i - 1;
          j >= 0 && !assigned.contains(j) && posList[j] == 'A';
          j--) {
        adjChildren.insert(
          0,
          SyntaxNode(word: words[j], role: 'Adjective'),
        );
        assigned.add(j);
      }

      final nounRole = i < rootIndex ? 'Subject' : 'Object';
      final nounNode = SyntaxNode(
        word: words[i],
        role: nounRole,
        children: adjChildren,
      );
      assigned.add(i);
      rootChildren.add(nounNode);
      i++;
    }

    // --- Pass 2: Handle Prepositional Phrases (Preposition + following Noun) ---
    for (int j = 0; j < words.length; j++) {
      if (assigned.contains(j) || posList[j] != 'R') continue;

      // Found a preposition — look for the next unassigned Noun
      final prepChildren = <SyntaxNode>[];
      for (int k = j + 1; k < words.length; k++) {
        if (!assigned.contains(k) && posList[k] == 'N') {
          prepChildren.add(SyntaxNode(word: words[k], role: 'Object of Prep.'));
          assigned.add(k);
          break;
        }
      }
      rootChildren.add(
        SyntaxNode(
          word: words[j],
          role: 'Preposition',
          children: prepChildren,
        ),
      );
      assigned.add(j);
    }

    // --- Pass 3: Conjunctions as bridge siblings ---
    for (int j = 0; j < words.length; j++) {
      if (assigned.contains(j) || posList[j] != 'C') continue;
      rootChildren.add(SyntaxNode(word: words[j], role: 'Conjunction'));
      assigned.add(j);
    }

    // --- Pass 4: Pronouns ---
    for (int j = 0; j < words.length; j++) {
      if (assigned.contains(j) || posList[j] != 'P') continue;
      final pronounRole = j < rootIndex ? 'Subject' : 'Object';
      rootChildren.add(SyntaxNode(word: words[j], role: pronounRole));
      assigned.add(j);
    }

    // --- Pass 5: Particles/Adverbs directly modifying the verb ---
    for (int j = 0; j < words.length; j++) {
      if (assigned.contains(j)) continue;
      final pos = posList[j];
      if (pos == 'D' || pos == 'T' || pos == 'X') {
        rootChildren.add(SyntaxNode(word: words[j], role: 'Adverb/Particle'));
        assigned.add(j);
      }
    }

    // --- Pass 6: Remaining unassigned words ---
    for (int j = 0; j < words.length; j++) {
      if (!assigned.contains(j)) {
        rootChildren.add(SyntaxNode(word: words[j], role: 'Other'));
      }
    }

    return SyntaxNode(
      word: rootWord,
      role: rootRole,
      children: rootChildren,
    );
  }

  /// Extracts the single-character Part-of-Speech key from a morph code.
  static String _getPos(String code, {required bool isHebrew}) {
    if (code.isEmpty) return '?';
    // For Hebrew: optional H/A prefix, then POS char
    if (isHebrew) {
      final start = (code.startsWith('H') || code.startsWith('A')) ? 1 : 0;
      return start < code.length ? code[start] : '?';
    }
    // For Greek: first segment before '-'
    return code.split('-').first.isNotEmpty ? code.split('-').first[0] : '?';
  }
}
