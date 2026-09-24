import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/shared/utils/transliterator.dart';

String g(String s) => Transliterator.greekToLatin(s);

void main() {
  test('rough breathing becomes h, on vowels and rho', () {
    expect(g('ὑπόστασις'), 'hypostasis');
    expect(g('ῥῆμα'), 'rhēma');
    expect(g('ὁ'), 'ho');
  });

  test('breathing on a diphthong puts h before the pair', () {
    expect(g('οὗτος'), 'houtos');
    expect(g('υἱός'), 'huios');
  });

  test('upsilon is y except in diphthongs', () {
    expect(g('αὐτοῦ'), 'autou');
    expect(g('εὐαγγέλιον'), 'euangelion');
    expect(g('μυστήριον'), 'mystērion');
  });

  test('nasal gamma', () {
    expect(g('ἄγγελος'), 'angelos');
  });

  test('smooth breathing and accents vanish', () {
    expect(g('Ἐν ἀρχῇ ἦν ὁ λόγος'), 'en archē ēn ho logos');
  });

  test('decomposed rough breathing is honoured', () {
    expect(g('ὁ'), 'ho');
  });
}
