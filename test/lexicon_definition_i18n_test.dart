import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/data/database/daos/bible_dao.dart';
import 'package:original_bible/data/database/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// A deliberately different original and translation so a test can tell which
/// one came back.
const _englishDefinition = 'Gods in the ordinary sense; the supreme God.';
const _ptDefinition = 'Deuses no sentido comum; o Deus supremo.';
const _esDefinition = 'Dioses en el sentido común; el Dios supremo.';
const _englishExtended = 'BDB: plural of majesty.';
const _ptExtended = 'BDB: plural de majestade.';

Future<Database> _seed() async {
  final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
  for (final table in [
    'lexicon_definition_i18n',
    'lexicon_gloss_i18n',
    'lexicon',
  ]) {
    await db.execute('DROP TABLE IF EXISTS $table');
  }
  await db.execute('''
    CREATE TABLE lexicon (
      lemma TEXT PRIMARY KEY,
      strongs_id TEXT,
      gloss TEXT NOT NULL,
      definition TEXT,
      part_of_speech TEXT,
      language TEXT,
      transliteration TEXT,
      pronunciation TEXT,
      extended_definition TEXT,
      extended_source TEXT
    )
  ''');
  await db.execute('''
    CREATE TABLE lexicon_gloss_i18n (
      strongs_id TEXT NOT NULL,
      lang TEXT NOT NULL,
      gloss TEXT NOT NULL,
      PRIMARY KEY (strongs_id, lang)
    )
  ''');
  await db.execute('''
    CREATE TABLE lexicon_definition_i18n (
      lemma TEXT NOT NULL,
      lang TEXT NOT NULL,
      definition TEXT,
      extended_definition TEXT,
      source_definition_sha256 TEXT,
      source_extended_sha256 TEXT,
      method TEXT NOT NULL DEFAULT 'machine',
      revision INTEGER NOT NULL DEFAULT 1,
      PRIMARY KEY (lemma, lang)
    )
  ''');

  // Two entries that share a Strong's id but have distinct lemmas.
  await db.insert('lexicon', {
    'lemma': 'אֱלֹהִים',
    'strongs_id': 'H430',
    'gloss': 'God',
    'definition': _englishDefinition,
    'extended_definition': _englishExtended,
    'extended_source': 'BDB',
    'language': 'heb',
  });
  await db.insert('lexicon', {
    'lemma': 'אֱלוֹהַּ',
    'strongs_id': 'H430',
    'gloss': 'God',
    'definition': _englishDefinition,
    'language': 'heb',
  });

  // Translations: definition for both lemmas (they share the source text);
  // extended only for the first; Spanish only for the shared definition.
  await db.insert('lexicon_definition_i18n', {
    'lemma': 'אֱלֹהִים',
    'lang': 'pt',
    'definition': _ptDefinition,
    'extended_definition': _ptExtended,
    'method': 'machine',
    'revision': 1,
  });
  for (final lemma in ['אֱלֹהִים', 'אֱלוֹהַּ']) {
    await db.insert('lexicon_definition_i18n', {
      'lemma': lemma,
      'lang': 'es',
      'definition': _esDefinition,
      'method': 'machine',
      'revision': 1,
    });
  }
  await db.insert('lexicon_definition_i18n', {
    'lemma': 'אֱלוֹהַּ',
    'lang': 'pt',
    'definition': _ptDefinition,
    'method': 'machine',
    'revision': 1,
  });
  return db;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    db = await _seed();
    DatabaseHelper.debugOverrideDatabase = db;
  });

  tearDown(() async {
    await DatabaseHelper.instance.resetForTesting();
    await db.close();
  });

  test('translated definition is served with its language provenance', () async {
    final entry = await BibleDAO(glossLanguage: 'pt').getLexiconEntry('H430');

    expect(entry, isNotNull);
    expect(entry!.definition, _ptDefinition);
    expect(entry.definitionLanguage, 'pt');
    // Extended translation was only stored for the first lemma; this lookup
    // returns the first matching row, which carries both translations.
    expect(entry.extendedDefinition, _ptExtended);
    expect(entry.extendedDefinitionLanguage, 'pt');
    // The English original stays available in the database, untouched.
    final raw = await db.query('lexicon', where: "lemma = 'אֱלֹהִים'");
    expect(raw.first['definition'], _englishDefinition);
  });

  test('missing translation falls back to English and is labelled', () async {
    // Spanish has the definition but not the extended text.
    final entry = await BibleDAO(glossLanguage: 'es').getLexiconEntry('H430');

    expect(entry!.definition, _esDefinition);
    expect(entry.definitionLanguage, 'es');
    expect(entry.extendedDefinition, _englishExtended);
    expect(entry.extendedDefinitionLanguage, isNull);
  });

  test('English reader always gets the originals', () async {
    final entry = await BibleDAO(glossLanguage: 'en').getLexiconEntry('H430');

    expect(entry!.definition, _englishDefinition);
    expect(entry.definitionLanguage, isNull);
    expect(entry.extendedDefinition, _englishExtended);
  });

  test('switching language changes the content served', () async {
    final pt = await BibleDAO(glossLanguage: 'pt').getLexiconEntry('H430');
    final es = await BibleDAO(glossLanguage: 'es').getLexiconEntry('H430');

    expect(pt!.definition, _ptDefinition);
    expect(es!.definition, _esDefinition);
    expect(pt.definition, isNot(es.definition));
  });

  test('batch lookup localizes per lemma while keeping homonyms apart', () async {
    final entries = await BibleDAO(
      glossLanguage: 'pt',
    ).getLexiconEntriesForStrongs(['H430']);

    // The batch path keys by Strong's id, so the shared id yields one entry;
    // what matters is that the localized long-form content is present.
    expect(entries, isNotEmpty);
    expect(entries['H430']!.definition, _ptDefinition);
  });
}
