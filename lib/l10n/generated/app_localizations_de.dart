// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Aleph';

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
      'Tippen Sie auf ein beliebiges Wort, um Definition, Aussprache und grammatikalische Informationen zu sehen. Halten Sie ein Wort gedrückt, um die Bedeutung kurz zu sehen, ohne die Stelle zu verlieren.';

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

  @override
  String get vocabularyTitle => 'Vokabeln';

  @override
  String get dueForReviewSection => 'Zur Wiederholung fällig';

  @override
  String get mostFrequentSection => 'Häufigste Wörter';

  @override
  String vocabularyCoverage(String percent) {
    return 'Diese Wörter decken $percent% des Textes ab — lerne sie zuerst.';
  }

  @override
  String get hebrewTextTitle => 'Hebräischer Text';

  @override
  String get hebrewTextDesc =>
      'Mit weniger Zeichen zu lesen ist ein Lernmeilenstein';

  @override
  String get hebrewTextFull => 'Vollständig (mit Kantillation)';

  @override
  String get hebrewTextNoCantillation => 'Nur Vokale';

  @override
  String get hebrewTextConsonantal => 'Nur Konsonanten';

  @override
  String get memorizationTitle => 'Auswendiglernen';

  @override
  String get memorizationEmpty =>
      'Noch nichts hier. Füge einen Psalm hinzu und beginne, Wörter zu verbergen.';

  @override
  String get addPassageTitle => 'Passage hinzufügen';

  @override
  String get addPassageButton => 'Hinzufügen';

  @override
  String get selectBookLabel => 'Buch';

  @override
  String get selectChapterLabel => 'Kapitel';

  @override
  String masteryLabel(String percent) {
    return 'Beherrschung $percent%';
  }

  @override
  String get dueNowLabel => 'Jetzt fällig';

  @override
  String get deletePassageTooltip => 'Passage entfernen';

  @override
  String get levelWarmUp => 'Aufwärmen';

  @override
  String get levelChallenge => 'Herausforderung';

  @override
  String get levelFirstLetters => 'Anfangsbuchstaben';

  @override
  String get tapHiddenWordHint =>
      'Tippe auf ein verborgenes Wort, um es aufzudecken';

  @override
  String get howDidItGo => 'Wie lief es?';

  @override
  String get struggledButton => 'Schwierig';

  @override
  String get gotItButton => 'Geschafft';

  @override
  String nextReviewInDays(int count) {
    return 'Gespeichert! Nächste Wiederholung in $count Tagen.';
  }

  @override
  String nextReviewInHours(int count) {
    return 'Gespeichert! Nächste Wiederholung in $count Stunden.';
  }

  @override
  String get missingMemorizationRouteData =>
      'Für diesen Bildschirm wurden keine Passagendaten übergeben.';

  @override
  String get wordResultsSection => 'Wörter';

  @override
  String get verseResultsSection => 'Verse';

  @override
  String get crossReferencesTitle => 'Querverweise';

  @override
  String get noCrossReferences => 'Keine Querverweise für diesen Vers.';

  @override
  String get parsingQuizTitle => 'Formenbestimmung';

  @override
  String get whatFormIsThis => 'Welche Form ist das?';

  @override
  String get nextQuestion => 'Weiter';

  @override
  String quizScore(int score, int total) {
    return '$score von $total richtig';
  }

  @override
  String get practiceAgain => 'Nochmal üben';

  @override
  String get doneButton => 'Fertig';

  @override
  String get syntaxSourceMacula =>
      'Syntaxbäume: MACULA Hebräisch & Griechisch (Clear Bible), CC BY 4.0';

  @override
  String get showMore => 'Mehr anzeigen';

  @override
  String get showLess => 'Weniger anzeigen';

  @override
  String get readabilityTitle => 'Was kann ich lesen?';

  @override
  String get readabilityAllBooks => 'Alle Bücher, die lesbarsten zuerst';

  @override
  String get readabilityNoText => 'Noch kein Text geladen.';

  @override
  String get readabilityCanReadNow => 'Das können Sie jetzt lesen';

  @override
  String get readabilityClosest => 'Am ehesten lesbar';

  @override
  String get readabilityEmptyTitle =>
      'Lernen Sie Wörter, damit sich diese Übersicht füllt';

  @override
  String get readabilityEmptyBody =>
      'Je mehr Wortschatz Sie beherrschen, desto mehr zeigt jedes Buch, wie viel davon Sie bereits lesen können. Die häufigsten Wörter decken den meisten Text ab, daher geht es am Anfang schnell voran.';

  @override
  String get openVocabulary => 'Wortschatz öffnen';

  @override
  String get reciteAloud => 'Vorlesen';

  @override
  String get stopReciting => 'Vorlesen beenden';

  @override
  String get recitationPreparing => 'Wird vorbereitet …';

  @override
  String get recitationStop => 'Stopp';

  @override
  String get hearItRead => 'Vorlesen lassen';

  @override
  String get phraseSpacingTitle => 'Satzgliederung';

  @override
  String get phraseSpacingDesc =>
      'Gliedert den hebräischen Text an den masoretischen Akzenten, sodass ein Vers in Sinneinheiten statt Wort für Wort gelesen wird.';

  @override
  String get recitationVoiceTitle => 'Stimme für das Vorlesen';

  @override
  String get recitationVoiceDesc =>
      'Die Kapitel werden von Stimmen vorgelesen, die in die App integriert sind – ohne Download und ohne Internet: modernes Griechisch für das Neue Testament. Hebräisch wird von der Stimme deines Geräts gelesen, denn es gibt noch keine hebräische Stimme, die wir mitliefern dürfen. Das sind lebendige Lesetraditionen, keine rekonstruierte antike Aussprache.';

  @override
  String get voiceMissing =>
      'Ihr Gerät benötigt eine hebräische oder griechische Sprachausgabe, um den Text vorzulesen. Die Installation dauert nur einen Moment und ist einmalig.';

  @override
  String get voiceUnsupported =>
      'Auf diesem Gerät ist keine Sprachausgabe verfügbar.';

  @override
  String get voiceInstall => 'Stimme installieren';

  @override
  String get voiceInstallUnavailable =>
      'Auf diesem Gerät lässt sich keine Stimmen-Installation öffnen.';

  @override
  String get recitationFailed => 'Das Vorlesen konnte nicht gestartet werden.';

  @override
  String readBook(String book) {
    return '$book lesen';
  }

  @override
  String readabilityCoverage(int percent, int count) {
    return 'Sie kennen $percent % des Wortschatzes – etwa $count unbekannte Wörter pro Kapitel.';
  }

  @override
  String recitationVerse(int number) {
    return 'Vers $number';
  }

  @override
  String voiceMissingFor(String tradition) {
    return 'Auf diesem Gerät ist keine Stimme für $tradition installiert.';
  }

  @override
  String crossReferencesCount(int count) {
    return '$count Querverweise';
  }

  @override
  String get onboardingRecitationTitle => 'Lassen Sie es sich vorlesen';

  @override
  String get onboardingRecitationDesc =>
      'Tippe auf Wiedergabe, um dir jedes Kapitel vorlesen zu lassen. Das Neue Testament wird von einer in die App integrierten Stimme für modernes Griechisch gelesen, funktioniert also offline bei einer frischen Installation. Hebräisch nutzt die Stimme deines Geräts. Stelle die Geschwindigkeit stark herunter, bis dein Ohr mitkommt.';

  @override
  String get readingHintTitle => 'Drei Wege zum Einstieg';

  @override
  String get readingHintBody =>
      'Tippen Sie auf ein Wort für die vollständige Bedeutung. Halten Sie es gedrückt für eine kurze Vorschau, ohne die Stelle zu verlieren. Tippen Sie oben auf ▶, um das Kapitel vorlesen zu lassen.';

  @override
  String get readingHintDismiss => 'Verstanden';

  @override
  String get explainTitle => 'Diese Stelle erklären';

  @override
  String get explainLoading => 'Die Stelle wird gelesen …';

  @override
  String get explainDisclaimer =>
      'Von einer KI verfasst. Kann falsch sein — prüfen Sie es am Text.';

  @override
  String get explainSettingTitle => 'KI-Erklärung von Bibelstellen';

  @override
  String get explainSettingDesc =>
      'Standardmäßig aus. Wenn aktiviert, wird die gelesene Stelle über das Internet zur Erklärung gesendet. Alles andere in dieser App funktioniert vollständig offline.';

  @override
  String get explainErrorOffline =>
      'Keine Verbindung. Dies ist die einzige Funktion, die eine benötigt.';

  @override
  String get explainErrorRateLimited =>
      'Zu viele Anfragen im Moment. Versuchen Sie es gleich noch einmal.';

  @override
  String get explainErrorGeneric =>
      'Die Erklärung konnte nicht erstellt werden.';

  @override
  String get explainRetry => 'Erneut versuchen';

  @override
  String get explainLowQuality =>
      'Diese Antwort wirkt fehlerhaft. Versuchen Sie es erneut — wenn es weiter passiert, sollte das Modell gewechselt werden.';

  @override
  String explainFreeRemaining(int count) {
    return 'Noch $count kostenlose Erklärungen heute';
  }

  @override
  String get explainLimitReached =>
      'Sie haben die kostenlosen Erklärungen für heute aufgebraucht.';

  @override
  String get explainUpgradeTitle => 'Unbegrenzt und ein besseres Modell';

  @override
  String get explainDiagnosticsTitle => 'KI-Diagnose';

  @override
  String get explainDiagnosticsDesc =>
      'Erfolgsquote und Geschwindigkeit des Modells, das Ihre Fragen beantwortet. Prüfen Sie hier, wenn die Antworten schlechter wirken als sonst.';

  @override
  String get explainNoData => 'Noch keine Erklärungen angefordert.';

  @override
  String get explainClearDiagnostics => 'Verlauf löschen';

  @override
  String get onboardingAiTitle => 'Fragen Sie zu jeder Bibelstelle';

  @override
  String get onboardingAiDesc =>
      'Ein Tutor für Ihre Frage: was der hebräische Text wirklich sagt, was das Griechische trägt, das eine Übersetzung nicht fassen kann. Tippen Sie auf das ✨ bei jedem Vers.';

  @override
  String get onboardingAiToggle => 'KI-Tutor aktivieren';

  @override
  String get onboardingAiPrivacy =>
      'Dies ist der einzige Teil der App, der das Internet nutzt: der Vers, zu dem Sie fragen, wird zur Erklärung gesendet. Alles andere — Text, Wörterbücher, Grammatik, Audio — funktioniert vollständig offline. Sie können das jederzeit in den Einstellungen ändern.';

  @override
  String get reciteFromHere => 'Ab hier vorlesen';

  @override
  String get searchEmptyTitle => 'In der Bibel suchen';

  @override
  String get searchEmptyBody =>
      'Gib beliebige Wörter eines Verses ein, um ihn zu finden. Hebräische und griechische Wörterbucheinträge erscheinen unter den Versen.';

  @override
  String get alphabetTitle => 'Das Alphabet';

  @override
  String get alphabetHebrewIntro =>
      'Hebräisch liest man von rechts nach links. Es gibt zweiundzwanzig Buchstaben, und alle sind Konsonanten — die Punkte und Striche darüber und darunter sind die Vokale. Nimm dir einen Buchstaben nach dem anderen vor; es eilt nicht.';

  @override
  String get alphabetGreekIntro =>
      'Griechisch liest man von links nach rechts und hat Groß- und Kleinbuchstaben. Anders als im Hebräischen sind die Vokale eigene Buchstaben. Nimm dir einen Buchstaben nach dem anderen vor; es eilt nicht.';

  @override
  String get alphabetLettersSection => 'Buchstaben';

  @override
  String get alphabetVowelsSection => 'Vokale';

  @override
  String get alphabetVowelsIntro =>
      'Die Vokale sind Zeichen rund um einen Buchstaben. Hier stehen sie am Bet (ב).';

  @override
  String get alphabetFinalForm => 'Endform';

  @override
  String get alphabetExampleLabel => 'In der Bibel';

  @override
  String get wordConnections => 'Wortverbindungen';

  @override
  String get wordConnectionsDesc =>
      'Zeichnet Linien zu den anderen Vorkommen eines angetippten Wortes. Standardmäßig aus, weil die Linien den Text kreuzen, den du gerade liest.';

  @override
  String get memorizationSubtitle =>
      'Blende Wörter in einem Abschnitt aus, den du schon flüssig liest.';

  @override
  String get onboardingTraditionTitle => 'Welche Schriften liest du?';

  @override
  String get onboardingTraditionDesc =>
      'Das bestimmt die Reihenfolge der Bücher und ihre Bezeichnungen. Verborgen wird so oder so nichts, und du kannst es in den Einstellungen ändern.';

  @override
  String get traditionChristian => 'Altes und Neues Testament';

  @override
  String get traditionChristianDesc =>
      'Die christliche Reihenfolge, von Genesis bis zur Offenbarung.';

  @override
  String get traditionJewish => 'Tanach';

  @override
  String get traditionJewishDesc =>
      'Tora, Newi\'im und Ketuwim, in der traditionellen jüdischen Reihenfolge.';

  @override
  String get tanakhTorah => 'Tora';

  @override
  String get tanakhNeviim => 'Newi\'im — Propheten';

  @override
  String get tanakhKetuvim => 'Ketuwim — Schriften';

  @override
  String get hebrewBibleLabel => 'Hebräische Bibel';

  @override
  String get traditionSettingTitle => 'Schriften';

  @override
  String get reviewReminderSetting => 'Tägliche Wiederholungserinnerung';

  @override
  String get reviewReminderSettingSubtitle =>
      'Ein Hinweis am Abend, wenn Wörter fällig sind';

  @override
  String reminderDueTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Wörter sind zur Wiederholung bereit',
      one: '1 Wort ist zur Wiederholung bereit',
    );
    return '$_temp0';
  }

  @override
  String get reminderDueBody => 'Fünf Minuten jetzt, und sie bleiben hängen.';

  @override
  String get reminderReadTitle => 'Dein Vers für heute wartet';

  @override
  String get reminderReadBody =>
      'Lies vor Tagesende einen Vers auf Hebräisch oder Griechisch.';

  @override
  String get pathTitle => 'Buchpfade';

  @override
  String get pathHomeStart =>
      'Wähle ein Buch und lerne genau die Wörter, die es braucht';

  @override
  String get pathChooseBook => 'Wähle ein Buch, das du im Urtext lesen willst';

  @override
  String pathWordsToGoal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Wörter bis 80 % des Buches',
      one: '1 Wort bis 80 % des Buches',
    );
    return '$_temp0';
  }

  @override
  String pathCoverage(int percent, String book) {
    return 'Du kannst $percent% von $book lesen';
  }

  @override
  String pathLearning(int percent) {
    return '$percent% mit den Wörtern, die du gerade lernst';
  }

  @override
  String get pathGoalReached =>
      'Du kannst den Großteil dieses Buches lesen. Schlag es auf!';

  @override
  String get pathLearnNext => 'Die nächsten Wörter lernen';

  @override
  String get pathWordsInBook => 'Wörter in diesem Buch, die häufigsten zuerst';

  @override
  String get pathChangeBook => 'Buch wechseln';

  @override
  String get pathShare => 'Fortschritt teilen';

  @override
  String shareCardHebrew(int percent, String book) {
    return 'Ich habe $percent% der Wörter in $book auf Hebräisch gelernt';
  }

  @override
  String shareCardGreek(int percent, String book) {
    return 'Ich habe $percent% der Wörter in $book auf Griechisch gelernt';
  }

  @override
  String get shareCardFooter => 'Ich lerne mit Aleph';

  @override
  String get pathAllLearned =>
      'Du hast jedes Wort dieses Buches angefangen. Bleib beim Wiederholen!';

  @override
  String get dailySessionStart => 'Deine 5 Minuten heute';

  @override
  String get dailySessionDone => 'Fertig für heute. Bis morgen!';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage in Folge',
      one: '1 Tag in Folge',
    );
    return '$_temp0';
  }

  @override
  String get nameTitle => 'Was bedeutet dein Name?';

  @override
  String get nameHint => 'Gib deinen Namen ein';

  @override
  String nameMeans(String name, String meaning) {
    return '$name bedeutet „$meaning“';
  }

  @override
  String nameCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Kommt $count-mal in der Bibel vor',
      one: 'Kommt einmal in der Bibel vor',
    );
    return '$_temp0';
  }

  @override
  String get nameNotFound =>
      'Noch nicht in unserer Liste. Versuch eine andere Schreibweise.';

  @override
  String get nameShare => 'Teilen';

  @override
  String get usageSharingTitle => 'Anonyme Nutzungszahlen teilen';

  @override
  String get usageSharingSubtitle =>
      'Welche Funktionen genutzt werden. Nie, was du liest, und nichts, was dich identifiziert.';

  @override
  String get supportTitle => 'Aleph unterstützen';

  @override
  String get supportBody =>
      'Aleph ist die Arbeit einer Person: keine Werbung, kein Abo, kein Tracking. Eine einmalige Spende hält Text, Stimmen und Updates am Leben.';

  @override
  String get supportNote =>
      'Spenden schalten nichts frei. Jedes Wort von Aleph gehört dir bereits.';

  @override
  String get supportTierSmall => 'Eine kleine Spende';

  @override
  String get supportTierMedium => 'Eine großzügige Spende';

  @override
  String get supportTierLarge => 'Eine große Spende';

  @override
  String get supportThanks => 'Danke. Das hilft wirklich.';

  @override
  String get supportUnavailable => 'Spenden sind gerade nicht verfügbar.';

  @override
  String get supportClose => 'Jetzt nicht';

  @override
  String get supportTerms => 'Bedingungen';

  @override
  String get supportPrivacy => 'Datenschutz';

  @override
  String get morphHebrew => 'Hebräisch';

  @override
  String get morphAramaic => 'Aramäisch';

  @override
  String get morphAdjective => 'Adjektiv';

  @override
  String get morphConjunction => 'Konjunktion';

  @override
  String get morphAdverb => 'Adverb';

  @override
  String get morphNoun => 'Substantiv';

  @override
  String get morphPronoun => 'Pronomen';

  @override
  String get morphPreposition => 'Präposition';

  @override
  String get morphSuffix => 'Suffix';

  @override
  String get morphParticle => 'Partikel';

  @override
  String get morphVerb => 'Verb';

  @override
  String get morphArticle => 'Artikel';

  @override
  String get morphInterjection => 'Interjektion';

  @override
  String get morphCommon => 'Gattungsname';

  @override
  String get morphProper => 'Eigenname';

  @override
  String get morphGentilic => 'Ethnikon';

  @override
  String get morphMasculine => 'Maskulinum';

  @override
  String get morphFeminine => 'Femininum';

  @override
  String get morphBothGenders => 'beide Geschlechter';

  @override
  String get morphNeuter => 'Neutrum';

  @override
  String get morphSingular => 'Singular';

  @override
  String get morphPlural => 'Plural';

  @override
  String get morphDual => 'Dual';

  @override
  String get morphAbsolute => 'absolut';

  @override
  String get morphConstruct => 'konstrukt';

  @override
  String get morphDetermined => 'determiniert';

  @override
  String get morphFirstPerson => '1. Person';

  @override
  String get morphSecondPerson => '2. Person';

  @override
  String get morphThirdPerson => '3. Person';

  @override
  String get morphPerfect => 'Perfekt';

  @override
  String get morphSequentialPerfect => 'Sequenzielles Perfekt';

  @override
  String get morphImperfect => 'Imperfekt';

  @override
  String get morphSequentialImperfect => 'Sequenzielles Imperfekt';

  @override
  String get morphCohortative => 'Kohortativ';

  @override
  String get morphJussive => 'Jussiv';

  @override
  String get morphImperative => 'Imperativ';

  @override
  String get morphParticipleActive => 'Partizip Aktiv';

  @override
  String get morphParticiplePassive => 'Partizip Passiv';

  @override
  String get morphInfinitiveAbsolute => 'Infinitiv absolut';

  @override
  String get morphInfinitiveConstruct => 'Infinitiv konstrukt';

  @override
  String get morphCardinalNumber => 'Kardinalzahl';

  @override
  String get morphOrdinalNumber => 'Ordnungszahl';

  @override
  String get morphDemonstrative => 'demonstrativ';

  @override
  String get morphIndefinite => 'indefinit';

  @override
  String get morphInterrogative => 'interrogativ';

  @override
  String get morphPersonal => 'personal';

  @override
  String get morphRelative => 'relativ';

  @override
  String get morphReciprocal => 'reziprok';

  @override
  String get morphReflexive => 'reflexiv';

  @override
  String get morphPossessive => 'possessiv';

  @override
  String get morphCorrelative => 'korrelativ';

  @override
  String get morphDirectional => 'direktional';

  @override
  String get morphParagogicHe => 'paragogisches He';

  @override
  String get morphParagogicNun => 'paragogisches Nun';

  @override
  String get morphPronominal => 'pronominal';

  @override
  String get morphPresent => 'Präsens';

  @override
  String get morphFuture => 'Futur';

  @override
  String get morphAorist => 'Aorist';

  @override
  String get morphPluperfect => 'Plusquamperfekt';

  @override
  String get morphNoTense => 'Kein Tempus';

  @override
  String get morphActive => 'Aktiv';

  @override
  String get morphMiddle => 'Medium';

  @override
  String get morphPassive => 'Passiv';

  @override
  String get morphMiddlePassive => 'Medium/Passiv';

  @override
  String get morphMiddleDeponent => 'Medium-Deponens';

  @override
  String get morphPassiveDeponent => 'Passiv-Deponens';

  @override
  String get morphMiddlePassiveDeponent => 'Medium/Passiv-Deponens';

  @override
  String get morphIndicative => 'Indikativ';

  @override
  String get morphSubjunctive => 'Konjunktiv';

  @override
  String get morphOptative => 'Optativ';

  @override
  String get morphInfinitive => 'Infinitiv';

  @override
  String get morphParticiple => 'Partizip';

  @override
  String get morphNominative => 'Nominativ';

  @override
  String get morphGenitive => 'Genitiv';

  @override
  String get morphDative => 'Dativ';

  @override
  String get morphAccusative => 'Akkusativ';

  @override
  String get morphVocative => 'Vokativ';

  @override
  String get contentSourceNote =>
      'Auf Englisch angezeigt; noch keine Übersetzung verfügbar.';

  @override
  String get recitationVoiceHebrewGap =>
      'Hebräisch nutzt die Sprachstimme deines Geräts. Eine integrierte hebräische Stimme wurde für Aleph noch nicht validiert.';

  @override
  String get contentLoadError =>
      'Dieser Inhalt konnte nicht geladen werden. Versuche es erneut.';

  @override
  String get diagnosticsSuccess => 'Erfolgsquote';

  @override
  String get diagnosticsMedian => 'Median der Dauer';

  @override
  String get diagnosticsCalls => 'Anfragen';

  @override
  String get diagnosticsPoorAnswers => 'Schlechte Antworten';

  @override
  String get diagnosticsErrors => 'Fehler';

  @override
  String get diagnosticsLastProblem => 'Letztes Problem';

  @override
  String get diagnosticsInUse => 'Wird verwendet';

  @override
  String get diagnosticsNotUsed => 'Noch nicht verwendet';

  @override
  String get diagnosticsTooEarly => 'Noch zu früh für eine Bewertung';

  @override
  String get diagnosticsEarlyProblems =>
      'Noch zu früh für eine Bewertung. Einige Probleme.';

  @override
  String get diagnosticsFailing => 'Fehlerhaft. Modell wechseln.';

  @override
  String get diagnosticsUnreliable => 'Unzuverlässig. Modellwechsel erwägen.';

  @override
  String get diagnosticsSlow => 'Sehr langsam. Modellwechsel erwägen.';

  @override
  String get diagnosticsMostlyGood =>
      'Überwiegend gut. Einige schlechte Antworten.';

  @override
  String get diagnosticsHealthy => 'Funktioniert gut';
}
