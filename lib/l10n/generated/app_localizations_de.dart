// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Original Bibel';

  @override
  String get continueReading => 'Weiterlesen';

  @override
  String get selectLanguage => 'Wählen Sie Ihre Sprache';

  @override
  String get next => 'Weiter';

  @override
  String get getStarted => 'Loslegen';

  @override
  String get skip => 'Überspringen';

  @override
  String get onboardingWelcomeTitle => 'Willkommen';

  @override
  String get onboardingWelcomeDesc =>
      'Erleben Sie die Bibel in ihren Originalsprachen mit Übersetzungen nebeneinander.';

  @override
  String get onboardingHebrewTitle => 'Hebräisch - Altes Testament';

  @override
  String get onboardingHebrewDesc =>
      'Das Alte Testament wurde auf Hebräisch geschrieben und von rechts nach links gelesen. Diese Texte entstanden vor über 2.500 Jahren und umfassen die Tora, Psalmen und Propheten.';

  @override
  String get onboardingGreekTitle => 'Griechisch - Neues Testament';

  @override
  String get onboardingGreekDesc =>
      'Das Neue Testament wurde auf Griechisch geschrieben und von links nach rechts gelesen. Die Evangelien und Briefe entstanden zwischen 50-100 n.Chr.';

  @override
  String get onboardingTapTitle => 'Tippen Sie auf ein Wort';

  @override
  String get onboardingTapDesc =>
      'Tippen Sie auf ein beliebiges Wort, um Definition, Aussprache und grammatikalische Informationen zu sehen. Aktivieren Sie die Aussprache-Taste, um zu hören, wie Wörter gesprochen werden.';

  @override
  String get settings => 'Einstellungen';

  @override
  String get translation => 'Übersetzung';

  @override
  String get pronunciation => 'Aussprache anzeigen';

  @override
  String get pronunciationDesc => 'Transliteration über den Wörtern anzeigen';

  @override
  String get fontSize => 'Schriftgröße';

  @override
  String get theme => 'Design';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get search => 'Suchen';

  @override
  String get searchHint => 'Im Bibeltext suchen...';

  @override
  String get noResults => 'Keine Ergebnisse gefunden';

  @override
  String get verseOfDay => 'Vers des Tages';

  @override
  String get quickAccess => 'Schnellzugriff';

  @override
  String get home => 'Start';

  @override
  String get books => 'Bücher';

  @override
  String get oldTestament => 'Altes Testament';

  @override
  String get newTestament => 'Neues Testament';

  @override
  String get selectChapter => 'Kapitel wählen';

  @override
  String chapters(int count) {
    return '$count Kapitel';
  }

  @override
  String get translationNotAvailable => 'Übersetzung nicht verfügbar';

  @override
  String get noLexiconEntry => 'Kein Lexikoneintrag verfügbar';

  @override
  String get copyVerse => 'Vers kopieren';

  @override
  String get shareVerse => 'Vers teilen';

  @override
  String get verseCopied => 'Vers in die Zwischenablage kopiert';

  @override
  String get addBookmark => 'Lesezeichen hinzufügen';

  @override
  String get removeBookmark => 'Lesezeichen entfernen';

  @override
  String get bookmarks => 'Lesezeichen';

  @override
  String get noBookmarks => 'Noch keine Lesezeichen';

  @override
  String get noBookmarksDesc =>
      'Halten Sie einen Vers gedrückt und tippen Sie auf das Lesezeichen-Symbol, um ihn hier zu speichern.';

  @override
  String get removeBookmarkConfirmation => 'Dieses Lesezeichen entfernen?';

  @override
  String bookmarkTimeYearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor # Jahren',
      one: 'vor # Jahr',
    );
    return '$_temp0';
  }

  @override
  String bookmarkTimeMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor # Monaten',
      one: 'vor # Monat',
    );
    return '$_temp0';
  }

  @override
  String bookmarkTimeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor # Tagen',
      one: 'vor # Tag',
    );
    return '$_temp0';
  }

  @override
  String bookmarkTimeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor # Stunden',
      one: 'vor # Stunde',
    );
    return '$_temp0';
  }

  @override
  String bookmarkTimeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor # Minuten',
      one: 'vor # Minute',
    );
    return '$_temp0';
  }

  @override
  String get bookmarkTimeJustNow => 'Gerade eben';

  @override
  String get quickMeaning => 'Kurzbedeutung';

  @override
  String get fullDefinition => 'Vollständige Definition';

  @override
  String get pronunciationLabel => 'Aussprache';

  @override
  String get hebrewOT => 'Hebräisch • Altes Testament';

  @override
  String get greekNT => 'Griechisch • Neues Testament';

  @override
  String get appResponsible => 'Verantwortlich für die App';

  @override
  String get legalNameLabel => 'Firmenname';

  @override
  String get tradeNameLabel => 'Handelsname';

  @override
  String get cnpjLabel => 'CNPJ';

  @override
  String get tryAgain => 'Erneut versuchen';

  @override
  String get somethingWentWrong => 'Etwas ist schiefgelaufen';

  @override
  String get error => 'Fehler';

  @override
  String get learningMode => 'Lernmodus';

  @override
  String get learningModeDesc =>
      'Lernen Sie die Originalsprachen passiv, indem Sie sie im Text sehen.';

  @override
  String get learningModeEnglishOnlyNotice =>
      'Der Lernmodus unterstützt derzeit nur englische Übersetzungen.';

  @override
  String get learningSectionTitle => 'Lernen';

  @override
  String get loading => 'Wird geladen...';

  @override
  String onboardingBibleLabel(String translation) {
    return 'Bibel: $translation';
  }

  @override
  String get syntaxTreeTitle => 'Syntaxbaum';

  @override
  String get viewSyntaxTree => 'Syntaxbaum anzeigen';

  @override
  String get hebrewLabel => 'Hebräisch';

  @override
  String get greekLabel => 'Griechisch';

  @override
  String get syntaxTreeTapHint =>
      'Tippen Sie auf einen Wortknoten, um die vollständige Definition zu sehen';

  @override
  String get noMorphologicalData =>
      'Für diesen Vers sind keine morphologischen Daten verfügbar.';

  @override
  String get posVerb => 'Verb';

  @override
  String get posNoun => 'Nomen';

  @override
  String get posAdjectiveShort => 'Adj.';

  @override
  String get posPronoun => 'Pronomen';

  @override
  String get posPrepositionShort => 'Präp.';

  @override
  String get posConjunctionShort => 'Konj.';

  @override
  String strongsHebrewLabel(String number) {
    return 'Hebräisch $number';
  }

  @override
  String strongsGreekLabel(String number) {
    return 'Griechisch $number';
  }

  @override
  String get lemmaDictionaryForm => 'Lemma (Wörterbuchform)';

  @override
  String get grammar => 'Grammatik';

  @override
  String get topUsageByBook => 'Häufigste Nutzung nach Buch';

  @override
  String get failedToLoadFrequencyData =>
      'Häufigkeitsdaten konnten nicht geladen werden.';

  @override
  String get noUsageDataAvailable => 'Keine Nutzungsdaten verfügbar.';

  @override
  String get previousChapter => 'Vorheriges Kapitel';

  @override
  String get nextChapter => 'Nächstes Kapitel';

  @override
  String get createCinematicImage => 'Filmisches Bild erstellen';

  @override
  String get srsQuestionPrompt => 'Was bedeutet dieses Wort in diesem Kontext?';

  @override
  String get revealAnswer => 'Antwort anzeigen';

  @override
  String get didntKnow => 'Wusste ich nicht';

  @override
  String get knewIt => 'Wusste ich';

  @override
  String get srsPositiveFeedback =>
      'Gut gemacht! Die Worterinnerung wurde erhöht.';

  @override
  String get srsNegativeFeedback =>
      'Weiter üben. Dieses Wort zeigen wir häufiger.';

  @override
  String get exportVerseTitle => 'Vers exportieren';

  @override
  String get shareImage => 'Bild teilen';

  @override
  String get backgroundTheme => 'Hintergrundthema';

  @override
  String get aspectRatio => 'Seitenverhältnis';

  @override
  String get failedToExportImage => 'Bild konnte nicht exportiert werden.';

  @override
  String get exportUnavailableTitle => 'Export nicht verfügbar';

  @override
  String get missingExportRouteData => 'Fehlende Routendaten für den Export.';

  @override
  String get invalidExportRouteData => 'Ungültige Routendaten für den Export.';

  @override
  String get syntaxTreeUnavailableTitle => 'Syntaxbaum nicht verfügbar';

  @override
  String get missingSyntaxTreeRouteData =>
      'Fehlende Routendaten für den Syntaxbaum.';

  @override
  String get invalidSyntaxTreeRouteData =>
      'Ungültige Routendaten für den Syntaxbaum.';

  @override
  String get noStrongsAvailable => 'Keine Strong-Nummer';

  @override
  String get wordStudyTitle => 'Wortstudie';

  @override
  String get seeAllUses => 'Alle Vorkommen anzeigen';

  @override
  String occurrencesTotal(int count) {
    return '$count Vorkommen in der Bibel';
  }

  @override
  String showingFirstOccurrences(int shown) {
    return 'Die ersten $shown Vorkommen werden angezeigt';
  }

  @override
  String get wordStudyUnavailableTitle => 'Wortstudie nicht verfügbar';

  @override
  String get missingWordStudyRouteData =>
      'Für diesen Bildschirm wurden keine Wortdaten übergeben.';

  @override
  String get syntaxTreeHeuristicNotice =>
      'Grammatische Skizze auf Basis von Wortstellungs-Heuristiken — keine verifizierten Syntaxdaten.';

  @override
  String get readerMode => 'Lesemodus';

  @override
  String get readerModeDesc =>
      'Zeigt beim Lesen eine kleine Übersetzung unter seltenen Wörtern. Gemeisterte Wörter erscheinen ohne Hilfe.';
}
