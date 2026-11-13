/// Guards the attested-forms pane: the honest stand-in for a paradigm table.
///
/// The grouping is what makes the pane read like a conjugation table, so the
/// two decisions — Hebrew by binyan, Greek by tense and voice, everything else
/// by part of speech — are pinned here, along with the order the stems are
/// presented in.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/shared/utils/morphology_decoder.dart';
import 'package:original_bible/shared/utils/paradigm.dart';

void main() {
  group('groupLabelFor', () {
    test('Hebrew verbs group by binyan', () {
      expect(groupLabelFor('Vqp3ms', isHebrew: true), 'Qal');
      expect(groupLabelFor('Vpw3ms', isHebrew: true), 'Piel');
      expect(groupLabelFor('VNp3ms', isHebrew: true), 'Niphal');
      expect(groupLabelFor('HVhp3ms', isHebrew: true), 'Hiphil');
    });

    test('Hebrew non-verbs group by part of speech', () {
      expect(groupLabelFor('HNcmsa', isHebrew: true), 'Noun');
      expect(groupLabelFor('HAabsa', isHebrew: true), 'Adjective');
      expect(groupLabelFor('HR', isHebrew: true), 'Preposition');
    });

    test('Greek verbs group by tense and voice', () {
      expect(groupLabelFor('V-AAI-3S', isHebrew: false), 'Aorist Active');
      expect(groupLabelFor('V-PAI-3S', isHebrew: false), 'Present Active');
      expect(groupLabelFor('V-API-3S', isHebrew: false), 'Aorist Passive');
    });

    test('Greek non-verbs group by part of speech', () {
      expect(groupLabelFor('N-NSM', isHebrew: false), 'Noun');
      expect(groupLabelFor('A-APF', isHebrew: false), 'Adjective');
    });
  });

  group('buildParadigmGroups', () {
    test('collects forms under their stem and orders Qal first', () {
      final groups = buildParadigmGroups(
        isHebrew: true,
        entries: const [
          (form: 'בֵּרַךְ', morph: 'Vpp3ms', count: 30),
          (form: 'בָּרוּךְ', morph: 'Vqsmsa', count: 60),
          (form: 'יְבָרֵךְ', morph: 'Vpi3ms', count: 20),
          (form: 'נִבְרְכוּ', morph: 'VNp3cp', count: 4),
        ],
      );

      // Gesenius's order: Qal, Niphal, Piel, Pual, Hiphil, Hophal, Hithpael.
      expect(groups.map((g) => g.label), ['Qal', 'Niphal', 'Piel']);
      expect(groups.first.forms.map((f) => f.form), ['בָּרוּךְ']);
      expect(groups[2].totalCount, 50);
    });

    test('forms inside a group are ordered by how often they occur', () {
      final groups = buildParadigmGroups(
        isHebrew: true,
        entries: const [
          (form: 'אָבַד', morph: 'Vqp3ms', count: 12),
          (form: 'אָבְדוּ', morph: 'Vqp3cp', count: 40),
        ],
      );

      expect(groups.single.forms.map((f) => f.form), ['אָבְדוּ', 'אָבַד']);
    });

    test('the same form with two parsings stays two rows', () {
      final groups = buildParadigmGroups(
        isHebrew: true,
        entries: const [
          (form: 'שָׁמַר', morph: 'Vqp3ms', count: 5),
          (form: 'שָׁמַר', morph: 'Vqp3ms', count: 5),
        ],
      );

      expect(groups.single.forms, hasLength(2));
    });

    test('empty forms and zero counts are dropped', () {
      final groups = buildParadigmGroups(
        isHebrew: true,
        entries: const [
          (form: '   ', morph: 'Vqp3ms', count: 9),
          (form: 'אָבַד', morph: 'Vqp3ms', count: 0),
        ],
      );

      expect(groups, isEmpty);
    });

    test('Greek groups come out ordered by tense', () {
      final groups = buildParadigmGroups(
        isHebrew: false,
        entries: const [
          (form: 'ἐπίστευσα', morph: 'V-AAI-1S', count: 3),
          (form: 'πιστεύω', morph: 'V-PAI-1S', count: 9),
        ],
      );

      expect(groups.map((g) => g.label), ['Present Active', 'Aorist Active']);
    });

    test('non-verbs land after every verb group', () {
      final groups = buildParadigmGroups(
        isHebrew: true,
        entries: const [
          (form: 'דָּבָר', morph: 'HNcmsa', count: 90),
          (form: 'אָבַד', morph: 'Vqp3ms', count: 1),
        ],
      );

      expect(groups.map((g) => g.label), ['Qal', 'Noun']);
    });
  });

  group('decode helpers used by the pane', () {
    test('Hebrew stem is null for non-verbs', () {
      expect(MorphologyDecoder.hebrewVerbStem('HNcmsa'), isNull);
      expect(MorphologyDecoder.hebrewVerbStem('Vqp3ms'), 'Qal');
    });

    test('Greek tense and voice is null for non-verbs', () {
      expect(MorphologyDecoder.greekTenseVoice('N-NSM'), isNull);
      expect(MorphologyDecoder.greekTenseVoice('V-PAI-3S'), 'Present Active');
    });
  });
}
