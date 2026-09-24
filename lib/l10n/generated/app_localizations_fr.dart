// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Aleph';

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
      'Touchez n\'importe quel mot pour voir sa définition, sa prononciation et ses informations grammaticales. Restez appuyé sur un mot pour voir rapidement son sens sans perdre votre place.';

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
  String get readabilityTitle => 'Que puis-je lire ?';

  @override
  String get readabilityAllBooks => 'Tous les livres, du plus lisible au moins';

  @override
  String get readabilityNoText => 'Aucun texte chargé pour le moment.';

  @override
  String get readabilityCanReadNow => 'Vous pouvez déjà lire ce livre';

  @override
  String get readabilityClosest => 'Le plus proche d\'être lisible';

  @override
  String get readabilityEmptyTitle =>
      'Apprenez du vocabulaire pour remplir cette carte';

  @override
  String get readabilityEmptyBody =>
      'À mesure que vous maîtrisez le vocabulaire, chaque livre indique la part que vous pouvez déjà lire. Les mots les plus fréquents couvrent la majeure partie du texte : les progrès sont donc rapides au début.';

  @override
  String get openVocabulary => 'Ouvrir le vocabulaire';

  @override
  String get reciteAloud => 'Lire à voix haute';

  @override
  String get stopReciting => 'Arrêter la lecture';

  @override
  String get recitationPreparing => 'Préparation…';

  @override
  String get recitationStop => 'Arrêter';

  @override
  String get hearItRead => 'Écouter la lecture';

  @override
  String get phraseSpacingTitle => 'Espacement par groupes de sens';

  @override
  String get phraseSpacingDesc =>
      'Espace le texte hébreu aux accents massorétiques, afin de lire le verset par unités de sens plutôt que mot à mot.';

  @override
  String get recitationVoiceTitle => 'Voix de lecture';

  @override
  String get recitationVoiceDesc =>
      'Lecture par les voix de synthèse de votre appareil : hébreu israélien moderne et grec moderne. Ce sont des traditions de lecture vivantes, et non la prononciation antique reconstituée.';

  @override
  String get voiceMissing =>
      'Votre appareil a besoin d\'une voix hébraïque ou grecque pour lire à voix haute. L\'installation prend un instant et ne se fait qu\'une fois.';

  @override
  String get voiceUnsupported =>
      'Aucun moteur de synthèse vocale n\'est disponible sur cet appareil.';

  @override
  String get voiceInstall => 'Installer une voix';

  @override
  String get voiceInstallUnavailable =>
      'Cet appareil n\'a pas d\'installateur de voix à ouvrir.';

  @override
  String get recitationFailed => 'Impossible de démarrer la lecture.';

  @override
  String readBook(String book) {
    return 'Lire $book';
  }

  @override
  String readabilityCoverage(int percent, int count) {
    return 'Vous connaissez $percent % de son vocabulaire — environ $count mots inconnus par chapitre.';
  }

  @override
  String recitationVerse(int number) {
    return 'Verset $number';
  }

  @override
  String voiceMissingFor(String tradition) {
    return 'Aucune voix $tradition n\'est installée sur cet appareil.';
  }

  @override
  String crossReferencesCount(int count) {
    return '$count références croisées';
  }

  @override
  String get onboardingRecitationTitle => 'Écoutez la récitation';

  @override
  String get onboardingRecitationDesc =>
      'Appuyez sur lecture pour entendre n\'importe quel chapitre lu à voix haute en hébreu ou en grec, avec des voix vivantes plutôt qu\'une prononciation antique reconstituée. Ralentissez le rythme jusqu\'à ce que votre oreille suive.';

  @override
  String get readingHintTitle => 'Trois façons de commencer';

  @override
  String get readingHintBody =>
      'Touchez un mot pour voir son sens complet. Restez appuyé pour un aperçu rapide sans perdre votre place. Appuyez sur ▶ ci-dessus pour entendre le chapitre récité.';

  @override
  String get readingHintDismiss => 'Compris';

  @override
  String get explainTitle => 'Expliquer ce passage';

  @override
  String get explainLoading => 'Lecture du passage…';

  @override
  String get explainDisclaimer =>
      'Rédigé par une IA. Peut se tromper — vérifiez avec le texte.';

  @override
  String get explainSettingTitle => 'Explication de passage par IA';

  @override
  String get explainSettingDesc =>
      'Désactivé par défaut. Une fois activé, le passage que vous lisez est envoyé par internet pour être expliqué. Tout le reste de l\'application fonctionne entièrement hors ligne.';

  @override
  String get explainErrorOffline =>
      'Pas de connexion. C\'est la seule fonction qui en a besoin.';

  @override
  String get explainErrorRateLimited =>
      'Trop de requêtes en ce moment. Réessayez dans un instant.';

  @override
  String get explainErrorGeneric => 'L\'explication n\'a pas pu être produite.';

  @override
  String get explainRetry => 'Réessayer';

  @override
  String get explainLowQuality =>
      'Cette réponse semble incorrecte. Réessayez — si cela persiste, il faudra peut-être changer de modèle.';

  @override
  String explainFreeRemaining(int count) {
    return '$count explications gratuites restantes aujourd\'hui';
  }

  @override
  String get explainLimitReached =>
      'Vous avez utilisé vos explications gratuites du jour.';

  @override
  String get explainUpgradeTitle => 'Illimité, avec un modèle plus fin';

  @override
  String get explainDiagnosticsTitle => 'Diagnostic de l\'IA';

  @override
  String get explainDiagnosticsDesc =>
      'Taux de réussite et rapidité du modèle qui répond à vos questions. À consulter si les réponses semblent moins bonnes que d\'habitude.';

  @override
  String get explainNoData => 'Aucune explication demandée pour l\'instant.';

  @override
  String get explainClearDiagnostics => 'Effacer l\'historique';

  @override
  String get onboardingAiTitle => 'Posez une question sur un passage';

  @override
  String get onboardingAiDesc =>
      'Un tuteur pour votre question : ce que dit vraiment l\'hébreu, ce que porte le grec qu\'une traduction ne rend pas. Touchez le ✨ sur n\'importe quel verset.';

  @override
  String get onboardingAiToggle => 'Activer le tuteur IA';

  @override
  String get onboardingAiPrivacy =>
      'C\'est la seule partie de l\'application qui utilise internet : le verset sur lequel vous posez une question est envoyé pour être expliqué. Tout le reste — texte, dictionnaires, grammaire, audio — fonctionne entièrement hors ligne. Vous pouvez changer cela à tout moment dans les Réglages.';

  @override
  String get reciteFromHere => 'Réciter à partir d\'ici';

  @override
  String get searchEmptyTitle => 'Chercher dans la Bible';

  @override
  String get searchEmptyBody =>
      'Tapez n\'importe quels mots d\'un verset pour le retrouver. Les entrées du dictionnaire hébreu et grec apparaissent sous les versets.';

  @override
  String get alphabetTitle => 'L\'alphabet';

  @override
  String get alphabetHebrewIntro =>
      'L\'hébreu se lit de droite à gauche. Il compte vingt-deux lettres, toutes des consonnes — les points et les traits écrits au-dessus et au-dessous sont les voyelles. Prenez une lettre à la fois ; rien ne presse.';

  @override
  String get alphabetGreekIntro =>
      'Le grec se lit de gauche à droite et possède des majuscules et des minuscules. Contrairement à l\'hébreu, ses voyelles sont des lettres à part entière. Prenez une lettre à la fois ; rien ne presse.';

  @override
  String get alphabetLettersSection => 'Lettres';

  @override
  String get alphabetVowelsSection => 'Voyelles';

  @override
  String get alphabetVowelsIntro =>
      'Les voyelles sont des signes écrits autour d\'une lettre. Elles sont montrées ici sur le bet (ב).';

  @override
  String get alphabetFinalForm => 'finale';

  @override
  String get alphabetExampleLabel => 'Dans la Bible';

  @override
  String get wordConnections => 'Liens entre les mots';

  @override
  String get wordConnectionsDesc =>
      'Trace des lignes vers les autres occurrences du mot touché. Désactivé par défaut, car les lignes traversent le texte que vous lisez.';

  @override
  String get memorizationSubtitle =>
      'Masquez des mots dans un passage que vous lisez déjà avec aisance.';

  @override
  String get onboardingTraditionTitle => 'Quelles Écritures lisez-vous ?';

  @override
  String get onboardingTraditionDesc =>
      'Cela détermine l\'ordre des livres et leurs noms. Rien n\'est masqué dans un cas comme dans l\'autre, et vous pouvez le changer dans les réglages.';

  @override
  String get traditionChristian => 'Ancien et Nouveau Testament';

  @override
  String get traditionChristianDesc =>
      'L\'ordre chrétien, de la Genèse à l\'Apocalypse.';

  @override
  String get traditionJewish => 'Tanakh';

  @override
  String get traditionJewishDesc =>
      'Torah, Nevi\'im et Ketouvim, dans l\'ordre juif traditionnel.';

  @override
  String get tanakhTorah => 'Torah';

  @override
  String get tanakhNeviim => 'Nevi\'im — Prophètes';

  @override
  String get tanakhKetuvim => 'Ketouvim — Écrits';

  @override
  String get hebrewBibleLabel => 'Bible hébraïque';

  @override
  String get traditionSettingTitle => 'Écritures';

  @override
  String get reviewReminderSetting => 'Rappel quotidien de révision';

  @override
  String get reviewReminderSettingSubtitle =>
      'Un rappel le soir quand des mots sont à revoir';

  @override
  String reminderDueTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mots à réviser',
      one: '1 mot à réviser',
    );
    return '$_temp0';
  }

  @override
  String get reminderDueBody =>
      'Cinq minutes maintenant, et ils ne vous échapperont pas.';

  @override
  String get reminderReadTitle => 'Votre verset du jour vous attend';

  @override
  String get reminderReadBody =>
      'Lisez un verset en hébreu ou en grec avant la fin de la journée.';

  @override
  String get pathTitle => 'Parcours de livres';

  @override
  String get pathHomeStart =>
      'Choisissez un livre et apprenez exactement ses mots';

  @override
  String get pathChooseBook => 'Choisissez un livre à lire dans l\'original';

  @override
  String pathWordsToGoal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mots pour lire 80 % du livre',
      one: '1 mot pour lire 80 % du livre',
    );
    return '$_temp0';
  }

  @override
  String pathCoverage(int percent, String book) {
    return 'Vous lisez déjà $percent% de $book';
  }

  @override
  String pathLearning(int percent) {
    return '$percent% en comptant les mots en cours d\'apprentissage';
  }

  @override
  String get pathGoalReached =>
      'Vous lisez l\'essentiel de ce livre. Ouvrez-le et profitez !';

  @override
  String get pathLearnNext => 'Apprendre les mots suivants';

  @override
  String get pathWordsInBook => 'Mots de ce livre, des plus fréquents';

  @override
  String get pathChangeBook => 'Changer de livre';

  @override
  String get pathShare => 'Partager ma progression';

  @override
  String shareCardHebrew(int percent, String book) {
    return 'J\'ai appris $percent% des mots de $book en hébreu';
  }

  @override
  String shareCardGreek(int percent, String book) {
    return 'J\'ai appris $percent% des mots de $book en grec';
  }

  @override
  String get shareCardFooter => 'J\'apprends avec Aleph';

  @override
  String get pathAllLearned =>
      'Vous avez commencé tous les mots de ce livre. Continuez à réviser !';

  @override
  String get dailySessionStart => 'Vos 5 minutes du jour';

  @override
  String get dailySessionDone => 'C\'est fait pour aujourd\'hui. À demain !';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours d\'affilée',
      one: '1 jour d\'affilée',
    );
    return '$_temp0';
  }
}
