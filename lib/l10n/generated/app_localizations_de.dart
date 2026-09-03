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
      'Vorgelesen von den Sprachstimmen Ihres Geräts: modernes Israelisch für Hebräisch, modernes Griechisch für Griechisch. Das sind lebendige Lesetraditionen, nicht die rekonstruierte antike Aussprache.';

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
      'Drücken Sie auf Wiedergabe, um jedes Kapitel auf Hebräisch oder Griechisch vorlesen zu lassen – mit lebendigen Stimmen statt einer rekonstruierten antiken Aussprache. Verlangsamen Sie das Tempo, bis Ihr Ohr mithalten kann.';

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
  String get backToPrevious => 'Zurück zur vorherigen Stelle';

  @override
  String get copyOriginal => 'Originaltext kopieren';

  @override
  String get copyBoth => 'Original und Übersetzung kopieren';

  @override
  String searchKeepTyping(int count) {
    return 'Geben Sie mindestens $count Buchstaben ein.';
  }

  @override
  String verseResultsShowing(int shown, int total) {
    return 'Verse — $shown von $total';
  }

  @override
  String get searchFailedBody =>
      'Die Suche konnte nicht abgeschlossen werden. Versuchen Sie es erneut.';

  @override
  String get errorGenericBody =>
      'Beim Laden ist etwas schiefgegangen. Versuchen Sie es erneut.';

  @override
  String get verseOfDayUnavailable =>
      'Der Vers des Tages konnte nicht geladen werden.';

  @override
  String get wordGestureHint =>
      'Tippen für den ganzen Eintrag, gedrückt halten für die Bedeutung';

  @override
  String masteryPercent(int percent) {
    return '$percent% gelernt';
  }

  @override
  String get readingSectionTitle => 'Lesen';

  @override
  String get appearanceSectionTitle => 'Darstellung';

  @override
  String get audioSectionTitle => 'Audio';

  @override
  String get aboutSectionTitle => 'Über';

  @override
  String get traditionSettingDesc =>
      'Bestimmt Benennung und Reihenfolge der Bücher';

  @override
  String get fontSizeSample => 'Die Größe des Lesetexts';

  @override
  String get recitationVoiceUnavailable =>
      'Dieses Gerät hat keinen Bildschirm für Sprachdownloads.';

  @override
  String get recitationPause => 'Pause';

  @override
  String get recitationResume => 'Fortsetzen';

  @override
  String get recitationPreviousVerse => 'Vorheriger Vers';

  @override
  String get recitationNextVerse => 'Nächster Vers';

  @override
  String recitationPausedAtVerse(int number) {
    return 'Pausiert bei Vers $number';
  }

  @override
  String get bookmarkRemoved => 'Lesezeichen entfernt';

  @override
  String get undo => 'Rückgängig';

  @override
  String get bookFilterHint => 'Buch suchen';

  @override
  String get clearFilter => 'Löschen';

  @override
  String get databasePreparingTitle => 'Bibliothek wird vorbereitet';

  @override
  String get databasePreparingBody =>
      'Text, Wörterbücher und Grammatik werden auf dieses Gerät kopiert. Das geschieht einmal, danach funktioniert alles offline.';

  @override
  String get databasePrepareFailed =>
      'Die Bibliothek konnte nicht vorbereitet werden. Prüfen Sie den freien Speicher und versuchen Sie es erneut.';

  @override
  String get aboutSourcesTitle => 'Quellen und Nachweise';

  @override
  String get aboutSourcesDesc =>
      'Woher Text, Wörterbücher und Schriften stammen';

  @override
  String get aboutSourcesSectionTitle => 'Was in dieser App steckt';

  @override
  String get aboutVersionLabel => 'Version';

  @override
  String get aboutLicensesTitle => 'Open-Source-Lizenzen';

  @override
  String get aboutLicensesDesc => 'Die Softwarebibliotheken hinter dieser App';

  @override
  String get sourceOriginalTextTitle => 'Hebräischer und griechischer Text';

  @override
  String get sourceOriginalTextBody =>
      'Westminster Leningrad Codex (Hebräische Bibel) und das SBL Greek New Testament, beide gemeinfrei oder frei lizenziert.';

  @override
  String get sourceTranslationsTitle => 'Übersetzungen';

  @override
  String get sourceTranslationsBody =>
      'Gemeinfreie und frei lizenzierte Übersetzungen, darunter die King James Version. Jede Übersetzung führt ihre Herkunft in der Datenbank mit.';

  @override
  String get sourceLexiconTitle => 'Wörterbücher und Morphologie';

  @override
  String get sourceLexiconBody =>
      'Strongs hebräische und griechische Wörterbücher, mit morphologischer Analyse aus den Projekten OpenScriptures und MorphGNT.';

  @override
  String get sourceSyntaxTitle => 'Satzbau';

  @override
  String get sourceSyntaxBody =>
      'Syntaxbäume aus den MACULA-Datensätzen (Hebräisch und Griechisch) von Clear Bible, genutzt unter CC BY 4.0.';

  @override
  String get sourceFontsTitle => 'Schriften';

  @override
  String get sourceFontsBody =>
      'Ezra SIL für Hebräisch und Gentium für Griechisch und Latein, beide von SIL International unter der SIL Open Font License.';

  @override
  String get onboardingHebrewExampleGloss => '„Am Anfang schuf Gott …\"';

  @override
  String get onboardingGreekExampleGloss => '„Im Anfang war das Wort …\"';
}
