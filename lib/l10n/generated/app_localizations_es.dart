// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Biblia Original';

  @override
  String get continueReading => 'Continuar leyendo';

  @override
  String get selectLanguage => 'Selecciona tu idioma';

  @override
  String get next => 'Siguiente';

  @override
  String get getStarted => 'Comenzar';

  @override
  String get skip => 'Omitir';

  @override
  String get onboardingWelcomeTitle => 'Bienvenido';

  @override
  String get onboardingWelcomeDesc =>
      'Experimenta la Biblia en sus idiomas originales con traducciones lado a lado.';

  @override
  String get onboardingHebrewTitle => 'Hebreo - Antiguo Testamento';

  @override
  String get onboardingHebrewDesc =>
      'El Antiguo Testamento fue escrito en hebreo, de derecha a izquierda. Estos textos fueron compuestos hace más de 2.500 años e incluyen la Torá, los Salmos y los Profetas.';

  @override
  String get onboardingGreekTitle => 'Griego - Nuevo Testamento';

  @override
  String get onboardingGreekDesc =>
      'El Nuevo Testamento fue escrito en griego, de izquierda a derecha. Los Evangelios y las Epístolas fueron compuestos entre los años 50 y 100 d.C.';

  @override
  String get onboardingTapTitle => 'Toca cualquier palabra';

  @override
  String get onboardingTapDesc =>
      'Toca cualquier palabra para ver su definición, pronunciación e información gramatical. Mantén pulsada una palabra para ver su significado rápido sin perder tu lugar.';

  @override
  String get settings => 'Ajustes';

  @override
  String get translation => 'Traducción';

  @override
  String get pronunciation => 'Mostrar pronunciación';

  @override
  String get pronunciationDesc => 'Mostrar transliteración sobre las palabras';

  @override
  String get fontSize => 'Tamaño de fuente';

  @override
  String get theme => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get search => 'Buscar';

  @override
  String get searchHint => 'Buscar en el texto bíblico...';

  @override
  String get noResults => 'No se encontraron resultados';

  @override
  String get verseOfDay => 'Versículo del día';

  @override
  String get quickAccess => 'Acceso rápido';

  @override
  String get home => 'Inicio';

  @override
  String get books => 'Libros';

  @override
  String get oldTestament => 'Antiguo Testamento';

  @override
  String get newTestament => 'Nuevo Testamento';

  @override
  String get selectChapter => 'Seleccionar capítulo';

  @override
  String chapters(int count) {
    return '$count capítulos';
  }

  @override
  String get translationNotAvailable => 'Traducción no disponible';

  @override
  String get noLexiconEntry => 'No hay entrada léxica disponible';

  @override
  String get copyVerse => 'Copiar versículo';

  @override
  String get shareVerse => 'Compartir versículo';

  @override
  String get verseCopied => 'Versículo copiado al portapapeles';

  @override
  String get addBookmark => 'Agregar marcador';

  @override
  String get removeBookmark => 'Eliminar marcador';

  @override
  String get bookmarks => 'Marcadores';

  @override
  String get noBookmarks => 'Aún no hay marcadores';

  @override
  String get noBookmarksDesc =>
      'Mantén presionado un versículo y toca el ícono de marcador para guardarlo aquí.';

  @override
  String get removeBookmarkConfirmation => '¿Eliminar este marcador?';

  @override
  String bookmarkTimeYearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace # años',
      one: 'hace # año',
    );
    return '$_temp0';
  }

  @override
  String bookmarkTimeMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace # meses',
      one: 'hace # mes',
    );
    return '$_temp0';
  }

  @override
  String bookmarkTimeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace # días',
      one: 'hace # día',
    );
    return '$_temp0';
  }

  @override
  String bookmarkTimeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace # horas',
      one: 'hace # hora',
    );
    return '$_temp0';
  }

  @override
  String bookmarkTimeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace # minutos',
      one: 'hace # minuto',
    );
    return '$_temp0';
  }

  @override
  String get bookmarkTimeJustNow => 'Ahora mismo';

  @override
  String get quickMeaning => 'Significado rápido';

  @override
  String get fullDefinition => 'Definición completa';

  @override
  String get pronunciationLabel => 'Pronunciación';

  @override
  String get hebrewOT => 'Hebreo • Antiguo Testamento';

  @override
  String get greekNT => 'Griego • Nuevo Testamento';

  @override
  String get appResponsible => 'Responsable de la app';

  @override
  String get legalNameLabel => 'Razón social';

  @override
  String get tradeNameLabel => 'Nombre comercial';

  @override
  String get cnpjLabel => 'CNPJ';

  @override
  String get tryAgain => 'Intentar de nuevo';

  @override
  String get somethingWentWrong => 'Algo salió mal';

  @override
  String get error => 'Error';

  @override
  String get learningMode => 'Modo de aprendizaje';

  @override
  String get learningModeDesc =>
      'Aprende de forma pasiva los idiomas originales al verlos en el texto.';

  @override
  String get learningModeEnglishOnlyNotice =>
      'El modo de aprendizaje actualmente solo admite traducciones en inglés.';

  @override
  String get learningSectionTitle => 'Aprendizaje';

  @override
  String get loading => 'Cargando...';

  @override
  String onboardingBibleLabel(String translation) {
    return 'Biblia: $translation';
  }

  @override
  String get syntaxTreeTitle => 'Árbol sintáctico';

  @override
  String get viewSyntaxTree => 'Ver árbol sintáctico';

  @override
  String get hebrewLabel => 'Hebreo';

  @override
  String get greekLabel => 'Griego';

  @override
  String get syntaxTreeTapHint =>
      'Toca cualquier nodo para ver su definición completa';

  @override
  String get noMorphologicalData =>
      'No hay datos morfológicos disponibles para este versículo.';

  @override
  String get posVerb => 'Verbo';

  @override
  String get posNoun => 'Sust.';

  @override
  String get posAdjectiveShort => 'Adj.';

  @override
  String get posPronoun => 'Pronombre';

  @override
  String get posPrepositionShort => 'Prep.';

  @override
  String get posConjunctionShort => 'Conj.';

  @override
  String strongsHebrewLabel(String number) {
    return 'Hebreo $number';
  }

  @override
  String strongsGreekLabel(String number) {
    return 'Griego $number';
  }

  @override
  String get lemmaDictionaryForm => 'Lema (forma de diccionario)';

  @override
  String get grammar => 'Gramática';

  @override
  String get topUsageByBook => 'Uso principal por libro';

  @override
  String get failedToLoadFrequencyData =>
      'No se pudieron cargar los datos de frecuencia.';

  @override
  String get noUsageDataAvailable => 'No hay datos de uso disponibles.';

  @override
  String get previousChapter => 'Capítulo anterior';

  @override
  String get nextChapter => 'Capítulo siguiente';

  @override
  String get createCinematicImage => 'Crear imagen cinematográfica';

  @override
  String get srsQuestionPrompt =>
      '¿Qué significa esta palabra en este contexto?';

  @override
  String get revealAnswer => 'Mostrar respuesta';

  @override
  String get didntKnow => 'No lo sabía';

  @override
  String get knewIt => 'Lo sabía';

  @override
  String get srsPositiveFeedback =>
      '¡Excelente! La memoria de la palabra aumentó.';

  @override
  String get srsNegativeFeedback =>
      'Sigue practicando. Mostraremos esta palabra más seguido.';

  @override
  String get exportVerseTitle => 'Exportar versículo';

  @override
  String get shareImage => 'Compartir imagen';

  @override
  String get backgroundTheme => 'Tema de fondo';

  @override
  String get aspectRatio => 'Relación de aspecto';

  @override
  String get failedToExportImage => 'No se pudo exportar la imagen.';

  @override
  String get exportUnavailableTitle => 'Exportación no disponible';

  @override
  String get missingExportRouteData =>
      'Faltan datos de ruta para la exportación.';

  @override
  String get invalidExportRouteData =>
      'Datos de ruta no válidos para la exportación.';

  @override
  String get syntaxTreeUnavailableTitle => 'Árbol sintáctico no disponible';

  @override
  String get missingSyntaxTreeRouteData =>
      'Faltan datos de ruta para el árbol sintáctico.';

  @override
  String get invalidSyntaxTreeRouteData =>
      'Datos de ruta no válidos para el árbol sintáctico.';

  @override
  String get noStrongsAvailable => 'Sin Strong\'s';

  @override
  String get wordStudyTitle => 'Estudio de la palabra';

  @override
  String get seeAllUses => 'Ver todas las apariciones';

  @override
  String occurrencesTotal(int count) {
    return '$count apariciones en la Biblia';
  }

  @override
  String showingFirstOccurrences(int shown) {
    return 'Mostrando las primeras $shown apariciones';
  }

  @override
  String get wordStudyUnavailableTitle => 'Estudio de palabra no disponible';

  @override
  String get missingWordStudyRouteData =>
      'No se proporcionaron datos de la palabra para esta pantalla.';

  @override
  String get syntaxTreeHeuristicNotice =>
      'Esbozo gramatical basado en heurísticas del orden de palabras — no son datos sintácticos verificados.';

  @override
  String get readerMode => 'Modo lector';

  @override
  String get readerModeDesc =>
      'Muestra una pequeña traducción bajo las palabras raras mientras lees. Las palabras dominadas aparecen sin ayuda.';

  @override
  String get vocabularyTitle => 'Vocabulario';

  @override
  String get dueForReviewSection => 'Para repasar';

  @override
  String get mostFrequentSection => 'Palabras más frecuentes';

  @override
  String vocabularyCoverage(String percent) {
    return 'Estas palabras cubren el $percent% del texto — apréndelas primero.';
  }

  @override
  String get hebrewTextTitle => 'Texto hebreo';

  @override
  String get hebrewTextDesc =>
      'Leer con menos signos es un hito de aprendizaje';

  @override
  String get hebrewTextFull => 'Completo (con cantilación)';

  @override
  String get hebrewTextNoCantillation => 'Solo vocales';

  @override
  String get hebrewTextConsonantal => 'Solo consonantes';

  @override
  String get memorizationTitle => 'Memorización';

  @override
  String get memorizationEmpty =>
      'Nada por aquí todavía. Añade un salmo y empieza a ocultar palabras.';

  @override
  String get addPassageTitle => 'Añadir pasaje';

  @override
  String get addPassageButton => 'Añadir';

  @override
  String get selectBookLabel => 'Libro';

  @override
  String get selectChapterLabel => 'Capítulo';

  @override
  String masteryLabel(String percent) {
    return 'Dominio $percent%';
  }

  @override
  String get dueNowLabel => 'Para repasar';

  @override
  String get deletePassageTooltip => 'Eliminar pasaje';

  @override
  String get levelWarmUp => 'Calentamiento';

  @override
  String get levelChallenge => 'Desafío';

  @override
  String get levelFirstLetters => 'Primeras letras';

  @override
  String get tapHiddenWordHint => 'Toca una palabra oculta para revelarla';

  @override
  String get howDidItGo => '¿Cómo te fue?';

  @override
  String get struggledButton => 'Me costó';

  @override
  String get gotItButton => 'Lo logré';

  @override
  String nextReviewInDays(int count) {
    return '¡Guardado! Próximo repaso en $count días.';
  }

  @override
  String nextReviewInHours(int count) {
    return '¡Guardado! Próximo repaso en $count horas.';
  }

  @override
  String get missingMemorizationRouteData =>
      'No se proporcionaron datos del pasaje para esta pantalla.';

  @override
  String get wordResultsSection => 'Palabras';

  @override
  String get verseResultsSection => 'Versículos';

  @override
  String get crossReferencesTitle => 'Referencias cruzadas';

  @override
  String get noCrossReferences =>
      'No hay referencias cruzadas para este versículo.';

  @override
  String get parsingQuizTitle => 'Práctica de análisis';

  @override
  String get whatFormIsThis => '¿Qué forma es esta?';

  @override
  String get nextQuestion => 'Siguiente';

  @override
  String quizScore(int score, int total) {
    return 'Acertaste $score de $total';
  }

  @override
  String get practiceAgain => 'Practicar de nuevo';

  @override
  String get doneButton => 'Listo';

  @override
  String get syntaxSourceMacula =>
      'Árboles sintácticos: MACULA hebreo y griego (Clear Bible), CC BY 4.0';

  @override
  String get showMore => 'Mostrar más';

  @override
  String get showLess => 'Mostrar menos';

  @override
  String get readabilityTitle => '¿Qué puedo leer?';

  @override
  String get readabilityAllBooks =>
      'Todos los libros, del más legible al menos';

  @override
  String get readabilityNoText => 'Todavía no hay texto cargado.';

  @override
  String get readabilityCanReadNow => 'Ya puedes leer este';

  @override
  String get readabilityClosest => 'El más cercano a poder leerse';

  @override
  String get readabilityEmptyTitle =>
      'Empieza a aprender palabras para llenar este mapa';

  @override
  String get readabilityEmptyBody =>
      'A medida que domines el vocabulario, cada libro mostrará cuánto puedes leer ya. Las palabras más frecuentes cubren la mayor parte del texto, así que al principio se avanza rápido.';

  @override
  String get openVocabulary => 'Abrir vocabulario';

  @override
  String get reciteAloud => 'Leer en voz alta';

  @override
  String get stopReciting => 'Detener la lectura';

  @override
  String get recitationPreparing => 'Preparando…';

  @override
  String get recitationStop => 'Detener';

  @override
  String get hearItRead => 'Escuchar la lectura';

  @override
  String get phraseSpacingTitle => 'Espaciado por frases';

  @override
  String get phraseSpacingDesc =>
      'Espacia el texto hebreo en los acentos masoréticos, para leer el versículo en unidades de sentido y no palabra por palabra.';

  @override
  String get recitationVoiceTitle => 'Voz de lectura';

  @override
  String get recitationVoiceDesc =>
      'Lectura con las voces de tu dispositivo: hebreo israelí moderno y griego moderno. Son tradiciones vivas de lectura, no la pronunciación antigua reconstruida.';

  @override
  String get voiceMissing =>
      'No hay ninguna voz de hebreo o griego instalada en este dispositivo. Añade una en los ajustes de voz del sistema para escuchar el texto.';

  @override
  String get voiceUnsupported =>
      'Este dispositivo no tiene ningún motor de voz disponible.';

  @override
  String get recitationFailed => 'No se pudo iniciar la lectura.';

  @override
  String readBook(String book) {
    return 'Leer $book';
  }

  @override
  String readabilityCoverage(int percent, int count) {
    return 'Conoces el $percent % de su vocabulario: unas $count palabras desconocidas por capítulo.';
  }

  @override
  String recitationVerse(int number) {
    return 'Versículo $number';
  }

  @override
  String voiceMissingFor(String tradition) {
    return 'No hay ninguna voz de $tradition instalada en este dispositivo.';
  }

  @override
  String crossReferencesCount(int count) {
    return '$count referencias cruzadas';
  }

  @override
  String get onboardingRecitationTitle => 'Escucha la recitación';

  @override
  String get onboardingRecitationDesc =>
      'Pulsa reproducir para escuchar cualquier capítulo leído en voz alta en hebreo o griego, con voces vivas en lugar de una pronunciación antigua reconstruida. Reduce la velocidad hasta que tu oído se acostumbre.';

  @override
  String get readingHintTitle => 'Tres formas de empezar';

  @override
  String get readingHintBody =>
      'Toca una palabra para ver su significado completo. Mantén pulsado para una vista rápida sin perder tu lugar. Pulsa ▶ arriba para escuchar el capítulo recitado.';

  @override
  String get readingHintDismiss => 'Entendido';
}
