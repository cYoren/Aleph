// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Bible Originale';

  @override
  String get continueReading => 'Continuer la Lecture';

  @override
  String get selectLanguage => 'Sélectionnez Votre Langue';

  @override
  String get next => 'Suivant';

  @override
  String get getStarted => 'Commencer';

  @override
  String get skip => 'Passer';

  @override
  String get onboardingWelcomeTitle => 'Bienvenue';

  @override
  String get onboardingWelcomeDesc =>
      'Découvrez la Bible dans ses langues originales avec des traductions côte à côte.';

  @override
  String get onboardingHebrewTitle => 'Hébreu - Ancien Testament';

  @override
  String get onboardingHebrewDesc =>
      'L\'Ancien Testament a été écrit en hébreu, lu de droite à gauche. Ces textes ont été composés il y a plus de 2 500 ans et comprennent la Torah, les Psaumes et les Prophètes.';

  @override
  String get onboardingGreekTitle => 'Grec - Nouveau Testament';

  @override
  String get onboardingGreekDesc =>
      'Le Nouveau Testament a été écrit en grec, lu de gauche à droite. Les Évangiles et les Épîtres ont été composés entre 50 et 100 après J.-C.';

  @override
  String get onboardingTapTitle => 'Touchez n\'importe quel mot';

  @override
  String get onboardingTapDesc =>
      'Touchez n\'importe quel mot pour voir sa définition, sa prononciation et ses informations grammaticales. Activez le bouton de prononciation pour voir comment les mots sont prononcés.';

  @override
  String get settings => 'Paramètres';

  @override
  String get translation => 'Traduction';

  @override
  String get pronunciation => 'Afficher la Prononciation';

  @override
  String get pronunciationDesc =>
      'Afficher la translittération au-dessus des mots';

  @override
  String get fontSize => 'Taille de Police';

  @override
  String get theme => 'Thème';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get search => 'Rechercher';

  @override
  String get searchHint => 'Rechercher dans le texte biblique...';

  @override
  String get noResults => 'Aucun résultat trouvé';

  @override
  String get verseOfDay => 'Verset du Jour';

  @override
  String get quickAccess => 'Accès Rapide';

  @override
  String get home => 'Accueil';

  @override
  String get books => 'Livres';

  @override
  String get oldTestament => 'Ancien Testament';

  @override
  String get newTestament => 'Nouveau Testament';

  @override
  String get selectChapter => 'Sélectionner le Chapitre';

  @override
  String chapters(int count) {
    return '$count chapitres';
  }

  @override
  String get translationNotAvailable => 'Traduction non disponible';

  @override
  String get noLexiconEntry => 'Pas d\'entrée lexicale disponible';

  @override
  String get copyVerse => 'Copier le verset';

  @override
  String get shareVerse => 'Partager le verset';

  @override
  String get verseCopied => 'Verset copié dans le presse-papiers';

  @override
  String get addBookmark => 'Ajouter un signet';

  @override
  String get removeBookmark => 'Supprimer le signet';

  @override
  String get bookmarks => 'Signets';

  @override
  String get noBookmarks => 'Pas encore de signets';

  @override
  String get noBookmarksDesc =>
      'Maintenez un verset appuyé et touchez l\'icône de signet pour le sauvegarder ici.';

  @override
  String get removeBookmarkConfirmation => 'Supprimer ce signet ?';

  @override
  String bookmarkTimeYearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a # ans',
      one: 'il y a # an',
    );
    return '$_temp0';
  }

  @override
  String bookmarkTimeMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a # mois',
      one: 'il y a # mois',
    );
    return '$_temp0';
  }

  @override
  String bookmarkTimeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a # jours',
      one: 'il y a # jour',
    );
    return '$_temp0';
  }

  @override
  String bookmarkTimeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a # heures',
      one: 'il y a # heure',
    );
    return '$_temp0';
  }

  @override
  String bookmarkTimeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a # minutes',
      one: 'il y a # minute',
    );
    return '$_temp0';
  }

  @override
  String get bookmarkTimeJustNow => 'À l\'instant';

  @override
  String get quickMeaning => 'Sens Rapide';

  @override
  String get fullDefinition => 'Définition Complète';

  @override
  String get pronunciationLabel => 'Prononciation';

  @override
  String get hebrewOT => 'Hébreu • Ancien Testament';

  @override
  String get greekNT => 'Grec • Nouveau Testament';

  @override
  String get appResponsible => 'Responsable de l\'application';

  @override
  String get legalNameLabel => 'Raison sociale';

  @override
  String get tradeNameLabel => 'Nom commercial';

  @override
  String get cnpjLabel => 'CNPJ';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get somethingWentWrong => 'Une erreur s\'est produite';

  @override
  String get error => 'Erreur';

  @override
  String get learningMode => 'Mode apprentissage';

  @override
  String get learningModeDesc =>
      'Apprenez passivement les langues originales en les voyant dans le texte.';

  @override
  String get learningModeEnglishOnlyNotice =>
      'Le mode apprentissage prend actuellement en charge uniquement les traductions anglaises.';

  @override
  String get learningSectionTitle => 'Apprentissage';

  @override
  String get loading => 'Chargement...';

  @override
  String onboardingBibleLabel(String translation) {
    return 'Bible : $translation';
  }

  @override
  String get syntaxTreeTitle => 'Arbre syntaxique';

  @override
  String get viewSyntaxTree => 'Voir l\'arbre syntaxique';

  @override
  String get hebrewLabel => 'Hébreu';

  @override
  String get greekLabel => 'Grec';

  @override
  String get syntaxTreeTapHint =>
      'Touchez un nœud de mot pour voir sa définition complète';

  @override
  String get noMorphologicalData =>
      'Aucune donnée morphologique disponible pour ce verset.';

  @override
  String get posVerb => 'Verbe';

  @override
  String get posNoun => 'Nom';

  @override
  String get posAdjectiveShort => 'Adj.';

  @override
  String get posPronoun => 'Pronom';

  @override
  String get posPrepositionShort => 'Prép.';

  @override
  String get posConjunctionShort => 'Conj.';

  @override
  String strongsHebrewLabel(String number) {
    return 'Hébreu $number';
  }

  @override
  String strongsGreekLabel(String number) {
    return 'Grec $number';
  }

  @override
  String get lemmaDictionaryForm => 'Lemme (forme dictionnaire)';

  @override
  String get grammar => 'Grammaire';

  @override
  String get topUsageByBook => 'Usage principal par livre';

  @override
  String get failedToLoadFrequencyData =>
      'Échec du chargement des données de fréquence.';

  @override
  String get noUsageDataAvailable => 'Aucune donnée d\'usage disponible.';

  @override
  String get previousChapter => 'Chapitre précédent';

  @override
  String get nextChapter => 'Chapitre suivant';

  @override
  String get createCinematicImage => 'Créer une image cinématographique';

  @override
  String get srsQuestionPrompt => 'Que signifie ce mot dans ce contexte ?';

  @override
  String get revealAnswer => 'Révéler la réponse';

  @override
  String get didntKnow => 'Je ne savais pas';

  @override
  String get knewIt => 'Je savais';

  @override
  String get srsPositiveFeedback => 'Excellent ! La mémoire du mot a augmenté.';

  @override
  String get srsNegativeFeedback =>
      'Continuez à pratiquer. Nous montrerons ce mot plus souvent.';

  @override
  String get exportVerseTitle => 'Exporter le verset';

  @override
  String get shareImage => 'Partager l\'image';

  @override
  String get backgroundTheme => 'Thème d\'arrière-plan';

  @override
  String get aspectRatio => 'Format';

  @override
  String get failedToExportImage => 'Échec de l\'exportation de l\'image.';

  @override
  String get exportUnavailableTitle => 'Export indisponible';

  @override
  String get missingExportRouteData =>
      'Données de route manquantes pour l\'exportation.';

  @override
  String get invalidExportRouteData =>
      'Données de route invalides pour l\'exportation.';

  @override
  String get syntaxTreeUnavailableTitle => 'Arbre syntaxique indisponible';

  @override
  String get missingSyntaxTreeRouteData =>
      'Données de route manquantes pour l\'arbre syntaxique.';

  @override
  String get invalidSyntaxTreeRouteData =>
      'Données de route invalides pour l\'arbre syntaxique.';

  @override
  String get noStrongsAvailable => 'Aucun Strong';

  @override
  String get wordStudyTitle => 'Étude de mot';

  @override
  String get seeAllUses => 'Voir toutes les occurrences';

  @override
  String occurrencesTotal(int count) {
    return '$count occurrences dans la Bible';
  }

  @override
  String showingFirstOccurrences(int shown) {
    return 'Affichage des $shown premières occurrences';
  }

  @override
  String get wordStudyUnavailableTitle => 'Étude de mot indisponible';

  @override
  String get missingWordStudyRouteData =>
      'Aucune donnée de mot n\'a été fournie pour cet écran.';

  @override
  String get syntaxTreeHeuristicNotice =>
      'Esquisse grammaticale fondée sur des heuristiques d\'ordre des mots — pas de données syntaxiques vérifiées.';

  @override
  String get readerMode => 'Mode lecteur';

  @override
  String get readerModeDesc =>
      'Affiche une petite traduction sous les mots rares pendant la lecture. Les mots maîtrisés apparaissent sans aide.';

  @override
  String get vocabularyTitle => 'Vocabulaire';

  @override
  String get dueForReviewSection => 'À réviser';

  @override
  String get mostFrequentSection => 'Mots les plus fréquents';

  @override
  String vocabularyCoverage(String percent) {
    return 'Ces mots couvrent $percent% du texte — apprenez-les en premier.';
  }

  @override
  String get hebrewTextTitle => 'Texte hébreu';

  @override
  String get hebrewTextDesc =>
      'Lire avec moins de signes est une étape d\'apprentissage';

  @override
  String get hebrewTextFull => 'Complet (avec cantillation)';

  @override
  String get hebrewTextNoCantillation => 'Voyelles seulement';

  @override
  String get hebrewTextConsonantal => 'Consonnes seulement';

  @override
  String get memorizationTitle => 'Mémorisation';

  @override
  String get memorizationEmpty =>
      'Rien ici pour l\'instant. Ajoutez un psaume et commencez à masquer des mots.';

  @override
  String get addPassageTitle => 'Ajouter un passage';

  @override
  String get addPassageButton => 'Ajouter';

  @override
  String get selectBookLabel => 'Livre';

  @override
  String get selectChapterLabel => 'Chapitre';

  @override
  String masteryLabel(String percent) {
    return 'Maîtrise $percent%';
  }

  @override
  String get dueNowLabel => 'À réviser';

  @override
  String get deletePassageTooltip => 'Supprimer le passage';

  @override
  String get levelWarmUp => 'Échauffement';

  @override
  String get levelChallenge => 'Défi';

  @override
  String get levelFirstLetters => 'Premières lettres';

  @override
  String get tapHiddenWordHint => 'Touchez un mot masqué pour le révéler';

  @override
  String get howDidItGo => 'Comment ça s\'est passé ?';

  @override
  String get struggledButton => 'Difficile';

  @override
  String get gotItButton => 'Réussi';

  @override
  String nextReviewInDays(int count) {
    return 'Enregistré ! Prochaine révision dans $count jours.';
  }

  @override
  String nextReviewInHours(int count) {
    return 'Enregistré ! Prochaine révision dans $count heures.';
  }

  @override
  String get missingMemorizationRouteData =>
      'Aucune donnée de passage n\'a été fournie pour cet écran.';

  @override
  String get wordResultsSection => 'Mots';

  @override
  String get verseResultsSection => 'Versets';

  @override
  String get crossReferencesTitle => 'Références croisées';

  @override
  String get noCrossReferences => 'Aucune référence croisée pour ce verset.';

  @override
  String get parsingQuizTitle => 'Exercice d\'analyse';

  @override
  String get whatFormIsThis => 'Quelle est cette forme ?';

  @override
  String get nextQuestion => 'Suivant';

  @override
  String quizScore(int score, int total) {
    return 'Vous avez $score sur $total';
  }

  @override
  String get practiceAgain => 'Recommencer';

  @override
  String get doneButton => 'Terminé';

  @override
  String get syntaxSourceMacula =>
      'Arbres syntaxiques : MACULA hébreu et grec (Clear Bible), CC BY 4.0';

  @override
  String get showMore => 'Afficher plus';

  @override
  String get showLess => 'Afficher moins';

  @override
  String get readabilityTitle => 'What can I read?';

  @override
  String get readabilityAllBooks => 'Every book, most readable first';

  @override
  String get readabilityNoText => 'No text is loaded yet.';

  @override
  String get readabilityCanReadNow => 'You can read this now';

  @override
  String get readabilityClosest => 'Closest to readable';

  @override
  String get readabilityEmptyTitle =>
      'Start learning words to see this map fill in';

  @override
  String get readabilityEmptyBody =>
      'As you master vocabulary, each book shows how much of it you can already read. The most frequent words cover the most text, so progress here is quick at first.';

  @override
  String get openVocabulary => 'Open vocabulary';

  @override
  String get reciteAloud => 'Recite aloud';

  @override
  String get stopReciting => 'Stop reciting';

  @override
  String get recitationPreparing => 'Preparing…';

  @override
  String get recitationStop => 'Stop';

  @override
  String get hearItRead => 'Hear it read';

  @override
  String get phraseSpacingTitle => 'Phrase spacing';

  @override
  String get phraseSpacingDesc =>
      'Space the Hebrew at the Masoretic accents, so a verse reads in sense units instead of word by word.';

  @override
  String get recitationVoiceTitle => 'Recitation voice';

  @override
  String get recitationVoiceDesc =>
      'Read aloud by your device\'s speech voices: Modern Israeli for Hebrew, Modern Greek for Greek. These are living reading traditions, not reconstructed ancient pronunciation.';

  @override
  String get voiceMissing =>
      'No Hebrew or Greek voice is installed on this device. Add one in your system speech settings to hear the text read aloud.';

  @override
  String get voiceUnsupported => 'This device has no speech engine available.';

  @override
  String get recitationFailed => 'Recitation could not be started.';

  @override
  String readBook(String book) {
    return 'Read $book';
  }

  @override
  String readabilityCoverage(int percent, int count) {
    return 'You know $percent% of its vocabulary — about $count unfamiliar words per chapter.';
  }

  @override
  String recitationVerse(int number) {
    return 'Verse $number';
  }

  @override
  String voiceMissingFor(String tradition) {
    return 'No $tradition voice is installed on this device.';
  }
}
