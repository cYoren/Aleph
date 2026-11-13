// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Aleph';

  @override
  String get continueReading => 'Continuar Leitura';

  @override
  String get selectLanguage => 'Selecione Seu Idioma';

  @override
  String get next => 'Próximo';

  @override
  String get getStarted => 'Começar';

  @override
  String get skip => 'Pular';

  @override
  String get onboardingWelcomeTitle => 'Bem-vindo';

  @override
  String get onboardingWelcomeDesc =>
      'Experimente a Bíblia em suas línguas originais com traduções lado a lado.';

  @override
  String get onboardingHebrewTitle => 'Hebraico - Antigo Testamento';

  @override
  String get onboardingHebrewDesc =>
      'O Antigo Testamento foi escrito em hebraico, lido da direita para a esquerda. Estes textos foram compostos há mais de 2.500 anos e incluem a Torá, Salmos e Profetas.';

  @override
  String get onboardingGreekTitle => 'Grego - Novo Testamento';

  @override
  String get onboardingGreekDesc =>
      'O Novo Testamento foi escrito em grego, lido da esquerda para a direita. Os Evangelhos e Epístolas foram compostos entre 50-100 d.C.';

  @override
  String get onboardingTapTitle => 'Toque em Qualquer Palavra';

  @override
  String get onboardingTapDesc =>
      'Toque em qualquer palavra para ver sua definição, pronúncia e informação gramatical. Toque e segure uma palavra para ver o significado rápido sem perder o lugar.';

  @override
  String get settings => 'Configurações';

  @override
  String get translation => 'Tradução';

  @override
  String get pronunciation => 'Mostrar Pronúncia';

  @override
  String get pronunciationDesc => 'Exibir transliteração acima das palavras';

  @override
  String get fontSize => 'Tamanho da Fonte';

  @override
  String get theme => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get search => 'Buscar';

  @override
  String get searchHint => 'Buscar no texto bíblico...';

  @override
  String get noResults => 'Nenhum resultado encontrado';

  @override
  String get verseOfDay => 'Versículo do Dia';

  @override
  String get quickAccess => 'Acesso Rápido';

  @override
  String get home => 'Início';

  @override
  String get books => 'Livros';

  @override
  String get oldTestament => 'Antigo Testamento';

  @override
  String get newTestament => 'Novo Testamento';

  @override
  String get selectChapter => 'Selecionar Capítulo';

  @override
  String chapters(int count) {
    return '$count capítulos';
  }

  @override
  String get translationNotAvailable => 'Tradução não disponível';

  @override
  String get noLexiconEntry => 'Entrada léxica não disponível';

  @override
  String get copyVerse => 'Copiar versículo';

  @override
  String get shareVerse => 'Compartilhar versículo';

  @override
  String get verseCopied => 'Versículo copiado';

  @override
  String get addBookmark => 'Adicionar favorito';

  @override
  String get removeBookmark => 'Remover favorito';

  @override
  String get bookmarks => 'Favoritos';

  @override
  String get noBookmarks => 'Nenhum favorito ainda';

  @override
  String get noBookmarksDesc =>
      'Segure um versículo e toque no ícone de favorito para salvá-lo aqui.';

  @override
  String get removeBookmarkConfirmation => 'Remover este favorito?';

  @override
  String bookmarkTimeYearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'há # anos',
      one: 'há # ano',
    );
    return '$_temp0';
  }

  @override
  String bookmarkTimeMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'há # meses',
      one: 'há # mês',
    );
    return '$_temp0';
  }

  @override
  String bookmarkTimeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'há # dias',
      one: 'há # dia',
    );
    return '$_temp0';
  }

  @override
  String bookmarkTimeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'há # horas',
      one: 'há # hora',
    );
    return '$_temp0';
  }

  @override
  String bookmarkTimeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'há # minutos',
      one: 'há # minuto',
    );
    return '$_temp0';
  }

  @override
  String get bookmarkTimeJustNow => 'Agora mesmo';

  @override
  String get quickMeaning => 'Significado Rápido';

  @override
  String get fullDefinition => 'Definição Completa';

  @override
  String get pronunciationLabel => 'Pronúncia';

  @override
  String get hebrewOT => 'Hebraico • Antigo Testamento';

  @override
  String get greekNT => 'Grego • Novo Testamento';

  @override
  String get appResponsible => 'Responsável pelo App';

  @override
  String get legalNameLabel => 'Razão Social';

  @override
  String get tradeNameLabel => 'Nome Fantasia';

  @override
  String get cnpjLabel => 'CNPJ';

  @override
  String get tryAgain => 'Tentar Novamente';

  @override
  String get somethingWentWrong => 'Algo deu errado';

  @override
  String get error => 'Erro';

  @override
  String get learningMode => 'Modo de Aprendizado';

  @override
  String get learningModeDesc =>
      'Aprenda os idiomas originais passivamente no decorrer da leitura.';

  @override
  String get learningSectionTitle => 'Aprendizado';

  @override
  String get loading => 'Carregando...';

  @override
  String onboardingBibleLabel(String translation) {
    return 'Bíblia: $translation';
  }

  @override
  String get syntaxTreeTitle => 'Árvore Sintática';

  @override
  String get viewSyntaxTree => 'Ver Árvore Sintática';

  @override
  String get hebrewLabel => 'Hebraico';

  @override
  String get greekLabel => 'Grego';

  @override
  String get syntaxTreeTapHint =>
      'Toque em qualquer nó para ver a definição completa';

  @override
  String get noMorphologicalData =>
      'Não há dados morfológicos disponíveis para este versículo.';

  @override
  String get posVerb => 'Verbo';

  @override
  String get posNoun => 'Subst.';

  @override
  String get posAdjectiveShort => 'Adj.';

  @override
  String get posPronoun => 'Pronome';

  @override
  String get posPrepositionShort => 'Prep.';

  @override
  String get posConjunctionShort => 'Conj.';

  @override
  String strongsHebrewLabel(String number) {
    return 'Hebraico $number';
  }

  @override
  String strongsGreekLabel(String number) {
    return 'Grego $number';
  }

  @override
  String get lemmaDictionaryForm => 'Lema (Forma de Dicionário)';

  @override
  String get grammar => 'Gramática';

  @override
  String get topUsageByBook => 'Uso Principal por Livro';

  @override
  String get failedToLoadFrequencyData =>
      'Falha ao carregar os dados de frequência.';

  @override
  String get noUsageDataAvailable => 'Nenhum dado de uso disponível.';

  @override
  String get previousChapter => 'Capítulo Anterior';

  @override
  String get nextChapter => 'Próximo Capítulo';

  @override
  String get createCinematicImage => 'Criar Imagem Cinematográfica';

  @override
  String get srsQuestionPrompt =>
      'O que esta palavra significa neste contexto?';

  @override
  String get revealAnswer => 'Revelar resposta';

  @override
  String get didntKnow => 'Não sabia';

  @override
  String get knewIt => 'Sabia';

  @override
  String get srsPositiveFeedback => 'Ótimo! A memória da palavra aumentou.';

  @override
  String get srsNegativeFeedback =>
      'Continue praticando. Mostraremos esta palavra com mais frequência.';

  @override
  String get exportVerseTitle => 'Exportar versículo';

  @override
  String get shareImage => 'Compartilhar imagem';

  @override
  String get backgroundTheme => 'Tema de fundo';

  @override
  String get aspectRatio => 'Proporção';

  @override
  String get failedToExportImage => 'Falha ao exportar a imagem.';

  @override
  String get exportUnavailableTitle => 'Exportação indisponível';

  @override
  String get missingExportRouteData =>
      'Dados de rota ausentes para exportação.';

  @override
  String get invalidExportRouteData =>
      'Dados de rota inválidos para exportação.';

  @override
  String get syntaxTreeUnavailableTitle => 'Árvore sintática indisponível';

  @override
  String get missingSyntaxTreeRouteData =>
      'Dados de rota ausentes para a árvore sintática.';

  @override
  String get invalidSyntaxTreeRouteData =>
      'Dados de rota inválidos para a árvore sintática.';

  @override
  String get noStrongsAvailable => 'Sem Strong\'s';

  @override
  String get wordStudyTitle => 'Estudo da Palavra';

  @override
  String get seeAllUses => 'Ver todas as ocorrências';

  @override
  String occurrencesTotal(int count) {
    return '$count ocorrências na Bíblia';
  }

  @override
  String showingFirstOccurrences(int shown) {
    return 'Mostrando as primeiras $shown ocorrências';
  }

  @override
  String get wordStudyUnavailableTitle => 'Estudo da palavra indisponível';

  @override
  String get missingWordStudyRouteData =>
      'Nenhum dado da palavra foi fornecido para esta tela.';

  @override
  String get syntaxTreeHeuristicNotice =>
      'Esboço gramatical baseado em heurísticas de ordem das palavras — não são dados sintáticos verificados.';

  @override
  String get readerMode => 'Modo leitor';

  @override
  String get readerModeDesc =>
      'Mostra uma pequena tradução sob palavras raras durante a leitura. Palavras dominadas aparecem sem ajuda.';

  @override
  String get vocabularyTitle => 'Vocabulário';

  @override
  String get dueForReviewSection => 'Para revisar';

  @override
  String get mostFrequentSection => 'Palavras mais frequentes';

  @override
  String vocabularyCoverage(String percent) {
    return 'Estas palavras cobrem $percent% do texto — aprenda-as primeiro.';
  }

  @override
  String get hebrewTextTitle => 'Texto hebraico';

  @override
  String get hebrewTextDesc => 'Ler com menos sinais é um marco de aprendizado';

  @override
  String get hebrewTextFull => 'Completo (com cantilação)';

  @override
  String get hebrewTextNoCantillation => 'Somente vogais';

  @override
  String get hebrewTextConsonantal => 'Somente consoantes';

  @override
  String get memorizationTitle => 'Memorização';

  @override
  String get memorizationEmpty =>
      'Nada aqui ainda. Adicione um salmo e comece a ocultar palavras.';

  @override
  String get addPassageTitle => 'Adicionar passagem';

  @override
  String get addPassageButton => 'Adicionar';

  @override
  String get selectBookLabel => 'Livro';

  @override
  String get selectChapterLabel => 'Capítulo';

  @override
  String masteryLabel(String percent) {
    return 'Domínio $percent%';
  }

  @override
  String get dueNowLabel => 'Para revisar';

  @override
  String get deletePassageTooltip => 'Remover passagem';

  @override
  String get levelWarmUp => 'Aquecimento';

  @override
  String get levelChallenge => 'Desafio';

  @override
  String get levelFirstLetters => 'Primeiras letras';

  @override
  String get tapHiddenWordHint => 'Toque em uma palavra oculta para revelá-la';

  @override
  String get howDidItGo => 'Como foi?';

  @override
  String get struggledButton => 'Tive dificuldade';

  @override
  String get gotItButton => 'Consegui';

  @override
  String nextReviewInDays(int count) {
    return 'Salvo! Próxima revisão em $count dias.';
  }

  @override
  String nextReviewInHours(int count) {
    return 'Salvo! Próxima revisão em $count horas.';
  }

  @override
  String get missingMemorizationRouteData =>
      'Nenhum dado de passagem foi fornecido para esta tela.';

  @override
  String get wordResultsSection => 'Palavras';

  @override
  String get verseResultsSection => 'Versículos';

  @override
  String get crossReferencesTitle => 'Referências cruzadas';

  @override
  String get noCrossReferences =>
      'Não há referências cruzadas para este versículo.';

  @override
  String get parsingQuizTitle => 'Prática de análise';

  @override
  String get whatFormIsThis => 'Que forma é esta?';

  @override
  String get nextQuestion => 'Próxima';

  @override
  String quizScore(int score, int total) {
    return 'Você acertou $score de $total';
  }

  @override
  String get practiceAgain => 'Praticar novamente';

  @override
  String get doneButton => 'Concluir';

  @override
  String get syntaxSourceMacula =>
      'Árvores sintáticas: MACULA Hebraico e Grego (Clear Bible), CC BY 4.0';

  @override
  String get showMore => 'Mostrar mais';

  @override
  String get showLess => 'Mostrar menos';

  @override
  String get readabilityTitle => 'O que eu consigo ler?';

  @override
  String get readabilityAllBooks => 'Todos os livros, do mais legível ao menos';

  @override
  String get readabilityNoText => 'Nenhum texto carregado ainda.';

  @override
  String get readabilityCanReadNow => 'Você já consegue ler este';

  @override
  String get readabilityClosest => 'Mais próximo de conseguir ler';

  @override
  String get readabilityEmptyTitle =>
      'Comece a aprender palavras para preencher este mapa';

  @override
  String get readabilityEmptyBody =>
      'Conforme você domina o vocabulário, cada livro mostra quanto dele você já consegue ler. As palavras mais frequentes cobrem a maior parte do texto, então o progresso é rápido no início.';

  @override
  String get openVocabulary => 'Abrir vocabulário';

  @override
  String get reciteAloud => 'Recitar em voz alta';

  @override
  String get stopReciting => 'Parar a recitação';

  @override
  String get recitationPreparing => 'Preparando…';

  @override
  String get recitationStop => 'Parar';

  @override
  String get hearItRead => 'Ouvir a leitura';

  @override
  String get phraseSpacingTitle => 'Espaçamento por frases';

  @override
  String get phraseSpacingDesc =>
      'Espaça o hebraico nos acentos massoréticos, para que o versículo seja lido em unidades de sentido, e não palavra por palavra.';

  @override
  String get recitationVoiceTitle => 'Voz da recitação';

  @override
  String get recitationVoiceDesc =>
      'Os capítulos são lidos por vozes integradas ao aplicativo — sem download e sem internet: grego moderno para o Novo Testamento. O hebraico é lido pela voz do próprio aparelho, porque ainda não existe uma voz hebraica que tenhamos permissão de incluir. São tradições de leitura vivas, não uma pronúncia antiga reconstruída.';

  @override
  String get voiceMissing =>
      'Seu dispositivo precisa de uma voz em hebraico ou grego para ler em voz alta. Instalar uma leva um instante e só é preciso fazer uma vez.';

  @override
  String get voiceUnsupported =>
      'Este aparelho não possui mecanismo de fala disponível.';

  @override
  String get voiceInstall => 'Instalar voz';

  @override
  String get voiceInstallUnavailable =>
      'Este dispositivo não tem um instalador de vozes para abrir.';

  @override
  String get recitationFailed => 'Não foi possível iniciar a recitação.';

  @override
  String readBook(String book) {
    return 'Ler $book';
  }

  @override
  String readabilityCoverage(int percent, int count) {
    return 'Você conhece $percent% do vocabulário dele — cerca de $count palavras desconhecidas por capítulo.';
  }

  @override
  String recitationVerse(int number) {
    return 'Versículo $number';
  }

  @override
  String voiceMissingFor(String tradition) {
    return 'Nenhuma voz de $tradition está instalada neste aparelho.';
  }

  @override
  String crossReferencesCount(int count) {
    return '$count referências cruzadas';
  }

  @override
  String get onboardingRecitationTitle => 'Ouça a Recitação';

  @override
  String get onboardingRecitationDesc =>
      'Toque em reproduzir para ouvir qualquer capítulo em voz alta. O Novo Testamento é lido por uma voz de grego moderno integrada ao aplicativo, então funciona offline numa instalação nova. O hebraico usa a voz do seu aparelho. Reduza bastante a velocidade no controle até seu ouvido acompanhar.';

  @override
  String get readingHintTitle => 'Três formas de começar';

  @override
  String get readingHintBody =>
      'Toque em uma palavra para ver o significado completo. Toque e segure para uma prévia rápida sem perder o lugar. Toque em ▶ acima para ouvir o capítulo recitado.';

  @override
  String get readingHintDismiss => 'Entendi';

  @override
  String get explainTitle => 'Explicar esta passagem';

  @override
  String get explainLoading => 'Lendo a passagem…';

  @override
  String get explainDisclaimer =>
      'Escrito por IA. Pode estar errado — confira com o texto.';

  @override
  String get explainSettingTitle => 'Explicação de passagens por IA';

  @override
  String get explainSettingDesc =>
      'Desativado por padrão. Quando ativado, a passagem que você está lendo é enviada pela internet para ser explicada. Todo o resto do app funciona totalmente offline.';

  @override
  String get explainErrorOffline =>
      'Sem conexão. Este é o único recurso que precisa dela.';

  @override
  String get explainErrorRateLimited =>
      'Muitas solicitações agora. Tente novamente em instantes.';

  @override
  String get explainErrorGeneric => 'Não foi possível gerar a explicação.';

  @override
  String get explainRetry => 'Tentar novamente';

  @override
  String get explainLowQuality =>
      'Esta resposta parece estranha. Tente novamente — se continuar, talvez seja preciso trocar o modelo.';

  @override
  String explainFreeRemaining(int count) {
    return '$count explicações gratuitas restantes hoje';
  }

  @override
  String get explainLimitReached =>
      'Você usou as explicações gratuitas de hoje.';

  @override
  String get explainUpgradeTitle => 'Ilimitado, com um modelo melhor';

  @override
  String get explainDiagnosticsTitle => 'Diagnóstico da IA';

  @override
  String get explainDiagnosticsDesc =>
      'Taxa de sucesso e velocidade do modelo que responde às suas perguntas. Confira aqui se as respostas parecerem piores que o normal.';

  @override
  String get explainNoData => 'Nenhuma explicação solicitada ainda.';

  @override
  String get explainClearDiagnostics => 'Limpar histórico';

  @override
  String get onboardingAiTitle => 'Pergunte sobre qualquer passagem';

  @override
  String get onboardingAiDesc =>
      'Um tutor para a sua dúvida: o que o hebraico realmente diz, o que o grego carrega que a tradução não alcança. Toque no ✨ em qualquer versículo.';

  @override
  String get onboardingAiToggle => 'Ativar o tutor de IA';

  @override
  String get onboardingAiPrivacy =>
      'Esta é a única parte do app que usa a internet: o versículo sobre o qual você pergunta é enviado para ser explicado. Todo o resto — texto, dicionários, gramática, áudio — funciona totalmente offline. Você pode mudar isso quando quiser nas Configurações.';

  @override
  String get reciteFromHere => 'Recitar a partir daqui';

  @override
  String get searchEmptyTitle => 'Buscar na Bíblia';

  @override
  String get searchEmptyBody =>
      'Digite quaisquer palavras de um versículo para encontrá-lo. As entradas do dicionário de hebraico e grego aparecem abaixo dos versículos.';

  @override
  String get alphabetTitle => 'O alfabeto';

  @override
  String get alphabetHebrewIntro =>
      'O hebraico se lê da direita para a esquerda. São vinte e duas letras, todas consoantes — os pontos e traços escritos acima e abaixo delas são as vogais. Vá uma letra de cada vez; não há pressa.';

  @override
  String get alphabetGreekIntro =>
      'O grego se lê da esquerda para a direita e tem letras maiúsculas e minúsculas. Ao contrário do hebraico, suas vogais são letras próprias. Vá uma letra de cada vez; não há pressa.';

  @override
  String get alphabetLettersSection => 'Letras';

  @override
  String get alphabetVowelsSection => 'Vogais';

  @override
  String get alphabetVowelsIntro =>
      'As vogais são sinais escritos ao redor de uma letra. Aqui elas aparecem sobre a letra bet (ב).';

  @override
  String get alphabetFinalForm => 'final';

  @override
  String get alphabetExampleLabel => 'Na Bíblia';

  @override
  String get wordConnections => 'Ligações entre palavras';

  @override
  String get wordConnectionsDesc =>
      'Traça linhas entre as outras ocorrências da palavra que você toca. Desligado por padrão, porque as linhas cruzam o texto que você está lendo.';

  @override
  String get memorizationSubtitle =>
      'Esconda palavras em uma passagem que você já lê com facilidade.';

  @override
  String get onboardingTraditionTitle => 'Quais escrituras você lê?';

  @override
  String get onboardingTraditionDesc =>
      'Isso define a ordem dos livros e como eles são chamados. Nada fica oculto de qualquer forma, e você pode mudar nas configurações.';

  @override
  String get traditionChristian => 'Antigo e Novo Testamento';

  @override
  String get traditionChristianDesc =>
      'A ordem cristã, de Gênesis a Apocalipse.';

  @override
  String get traditionJewish => 'Tanakh';

  @override
  String get traditionJewishDesc =>
      'Torá, Nevi\'im e Ketuvim, na ordem judaica tradicional.';

  @override
  String get tanakhTorah => 'Torá';

  @override
  String get tanakhNeviim => 'Nevi\'im — Profetas';

  @override
  String get tanakhKetuvim => 'Ketuvim — Escritos';

  @override
  String get hebrewBibleLabel => 'Bíblia Hebraica';

  @override
  String get traditionSettingTitle => 'Escrituras';

  @override
  String get reviewReminderSetting => 'Lembrete diário de revisão';

  @override
  String get reviewReminderSettingSubtitle =>
      'Um aviso à noite quando houver palavras para revisar';

  @override
  String reminderDueTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count palavras prontas para revisão',
      one: '1 palavra pronta para revisão',
    );
    return '$_temp0';
  }

  @override
  String get reminderDueBody => 'Cinco minutos agora e elas não escapam.';

  @override
  String get reminderReadTitle => 'Seu versículo de hoje está esperando';

  @override
  String get reminderReadBody =>
      'Leia um versículo em hebraico ou grego antes de o dia acabar.';

  @override
  String get pathTitle => 'Trilhas de livros';

  @override
  String get pathHomeStart =>
      'Escolha um livro e aprenda exatamente as palavras dele';

  @override
  String get pathChooseBook => 'Escolha um livro para ler no original';

  @override
  String pathWordsToGoal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count palavras para ler 80% dele',
      one: '1 palavra para ler 80% dele',
    );
    return '$_temp0';
  }

  @override
  String pathCoverage(int percent, String book) {
    return 'Você já lê $percent% de $book';
  }

  @override
  String pathLearning(int percent) {
    return '$percent% contando as palavras que você está aprendendo';
  }

  @override
  String get pathGoalReached =>
      'Você já lê a maior parte deste livro. Abra e aproveite!';

  @override
  String get pathLearnNext => 'Aprender as próximas palavras';

  @override
  String get pathWordsInBook => 'Palavras deste livro, das mais comuns';

  @override
  String get pathChangeBook => 'Trocar de livro';

  @override
  String get pathShare => 'Compartilhar progresso';

  @override
  String shareCardHebrew(int percent, String book) {
    return 'Já aprendi $percent% das palavras de $book em hebraico';
  }

  @override
  String shareCardGreek(int percent, String book) {
    return 'Já aprendi $percent% das palavras de $book em grego';
  }

  @override
  String get shareCardFooter => 'Aprendendo com o Aleph';

  @override
  String get pathAllLearned =>
      'Você já começou todas as palavras deste livro. Continue revisando!';

  @override
  String get dailySessionStart => 'Seus 5 minutos de hoje';

  @override
  String get dailySessionDone => 'Pronto por hoje. Até amanhã!';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias seguidos',
      one: '1 dia seguido',
    );
    return '$_temp0';
  }

  @override
  String get nameTitle => 'O que significa o seu nome?';

  @override
  String get nameHint => 'Digite seu nome';

  @override
  String nameMeans(String name, String meaning) {
    return '$name significa “$meaning”';
  }

  @override
  String nameCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Aparece $count vezes na Bíblia',
      one: 'Aparece uma vez na Bíblia',
    );
    return '$_temp0';
  }

  @override
  String get nameNotFound =>
      'Ainda não está na nossa lista. Tente outra grafia.';

  @override
  String get nameShare => 'Compartilhar';

  @override
  String get usageSharingTitle => 'Compartilhar contagens anônimas de uso';

  @override
  String get usageSharingSubtitle =>
      'Quais recursos são usados. Nunca o que você lê, nem nada que identifique você.';

  @override
  String get supportTitle => 'Apoiar o Aleph';

  @override
  String get supportBody =>
      'O Aleph é o trabalho de uma pessoa: sem anúncios, sem assinatura, sem rastreamento. Uma contribuição única mantém o texto, as vozes e as atualizações chegando.';

  @override
  String get supportNote =>
      'Contribuições não desbloqueiam nada. Cada palavra do Aleph já é sua.';

  @override
  String get supportTierSmall => 'Uma contribuição pequena';

  @override
  String get supportTierMedium => 'Uma contribuição generosa';

  @override
  String get supportTierLarge => 'Uma contribuição grande';

  @override
  String get supportThanks => 'Obrigado. Isso ajuda de verdade.';

  @override
  String get supportUnavailable => 'Contribuições não estão disponíveis agora.';

  @override
  String get supportClose => 'Agora não';

  @override
  String get supportTerms => 'Termos';

  @override
  String get supportPrivacy => 'Privacidade';

  @override
  String get morphHebrew => 'Hebraico';

  @override
  String get morphAramaic => 'Aramaico';

  @override
  String get morphAdjective => 'Adjetivo';

  @override
  String get morphConjunction => 'Conjunção';

  @override
  String get morphAdverb => 'Advérbio';

  @override
  String get morphNoun => 'Substantivo';

  @override
  String get morphPronoun => 'Pronome';

  @override
  String get morphPreposition => 'Preposição';

  @override
  String get morphSuffix => 'Sufixo';

  @override
  String get morphParticle => 'Partícula';

  @override
  String get morphVerb => 'Verbo';

  @override
  String get morphArticle => 'Artigo';

  @override
  String get morphInterjection => 'Interjeição';

  @override
  String get morphCommon => 'comum';

  @override
  String get morphProper => 'próprio';

  @override
  String get morphGentilic => 'gentílico';

  @override
  String get morphMasculine => 'masculino';

  @override
  String get morphFeminine => 'feminino';

  @override
  String get morphBothGenders => 'ambos os gêneros';

  @override
  String get morphNeuter => 'neutro';

  @override
  String get morphSingular => 'singular';

  @override
  String get morphPlural => 'plural';

  @override
  String get morphDual => 'dual';

  @override
  String get morphAbsolute => 'absoluto';

  @override
  String get morphConstruct => 'construto';

  @override
  String get morphDetermined => 'determinado';

  @override
  String get morphFirstPerson => '1ª pessoa';

  @override
  String get morphSecondPerson => '2ª pessoa';

  @override
  String get morphThirdPerson => '3ª pessoa';

  @override
  String get morphPerfect => 'Perfeito';

  @override
  String get morphSequentialPerfect => 'Perfeito Sequencial';

  @override
  String get morphImperfect => 'Imperfeito';

  @override
  String get morphSequentialImperfect => 'Imperfeito Sequencial';

  @override
  String get morphCohortative => 'Coortativo';

  @override
  String get morphJussive => 'Jussivo';

  @override
  String get morphImperative => 'Imperativo';

  @override
  String get morphParticipleActive => 'Particípio Ativo';

  @override
  String get morphParticiplePassive => 'Particípio Passivo';

  @override
  String get morphInfinitiveAbsolute => 'Infinitivo Absoluto';

  @override
  String get morphInfinitiveConstruct => 'Infinitivo Construto';

  @override
  String get morphCardinalNumber => 'número cardinal';

  @override
  String get morphOrdinalNumber => 'número ordinal';

  @override
  String get morphDemonstrative => 'demonstrativo';

  @override
  String get morphIndefinite => 'indefinido';

  @override
  String get morphInterrogative => 'interrogativo';

  @override
  String get morphPersonal => 'pessoal';

  @override
  String get morphRelative => 'relativo';

  @override
  String get morphReciprocal => 'recíproco';

  @override
  String get morphReflexive => 'reflexivo';

  @override
  String get morphPossessive => 'possessivo';

  @override
  String get morphCorrelative => 'correlativo';

  @override
  String get morphDirectional => 'direcional';

  @override
  String get morphParagogicHe => 'he paragógico';

  @override
  String get morphParagogicNun => 'nun paragógico';

  @override
  String get morphPronominal => 'pronominal';

  @override
  String get morphPresent => 'Presente';

  @override
  String get morphFuture => 'Futuro';

  @override
  String get morphAorist => 'Aoristo';

  @override
  String get morphPluperfect => 'Mais-que-perfeito';

  @override
  String get morphNoTense => 'Sem tempo';

  @override
  String get morphActive => 'Ativo';

  @override
  String get morphMiddle => 'Médio';

  @override
  String get morphPassive => 'Passivo';

  @override
  String get morphMiddlePassive => 'Médio/Passivo';

  @override
  String get morphMiddleDeponent => 'Depoente Médio';

  @override
  String get morphPassiveDeponent => 'Depoente Passivo';

  @override
  String get morphMiddlePassiveDeponent => 'Depoente Médio/Passivo';

  @override
  String get morphIndicative => 'Indicativo';

  @override
  String get morphSubjunctive => 'Subjuntivo';

  @override
  String get morphOptative => 'Optativo';

  @override
  String get morphInfinitive => 'Infinitivo';

  @override
  String get morphParticiple => 'Particípio';

  @override
  String get morphNominative => 'Nominativo';

  @override
  String get morphGenitive => 'Genitivo';

  @override
  String get morphDative => 'Dativo';

  @override
  String get morphAccusative => 'Acusativo';

  @override
  String get morphVocative => 'Vocativo';

  @override
  String get contentSourceNote =>
      'Exibido em inglês; ainda não há tradução disponível.';

  @override
  String get recitationVoiceHebrewGap =>
      'O hebraico usa a voz de leitura do seu aparelho. Uma voz hebraica integrada ainda não foi validada para o Aleph.';

  @override
  String get contentLoadError =>
      'Não foi possível carregar este conteúdo. Tente novamente.';

  @override
  String get diagnosticsSuccess => 'Sucesso';

  @override
  String get diagnosticsMedian => 'Tempo mediano';

  @override
  String get diagnosticsCalls => 'Pedidos';

  @override
  String get diagnosticsPoorAnswers => 'Respostas ruins';

  @override
  String get diagnosticsErrors => 'Erros';

  @override
  String get diagnosticsLastProblem => 'Último problema';

  @override
  String get diagnosticsInUse => 'Em uso';

  @override
  String get diagnosticsNotUsed => 'Ainda não utilizado';

  @override
  String get diagnosticsTooEarly => 'Ainda é cedo para avaliar';

  @override
  String get diagnosticsEarlyProblems =>
      'Ainda é cedo para avaliar. Houve problemas.';

  @override
  String get diagnosticsFailing => 'Falhando. Troque o modelo.';

  @override
  String get diagnosticsUnreliable => 'Pouco confiável. Considere trocar.';

  @override
  String get diagnosticsSlow => 'Muito lento. Considere trocar.';

  @override
  String get diagnosticsMostlyGood =>
      'Em geral, funciona. Algumas respostas ruins.';

  @override
  String get diagnosticsHealthy => 'Funcionando bem';

  @override
  String get sensesLabel => 'Sentidos';

  @override
  String get sensesUnavailable =>
      'Este verbete não tem sentidos numerados no dicionário.';

  @override
  String get rootLabel => 'Raiz';

  @override
  String get rootWordsTitle => 'Palavras desta raiz';

  @override
  String rootWordCount(int count) {
    return '$count palavras';
  }

  @override
  String get formsInTextLabel => 'Formas no texto';

  @override
  String get formsInTextNote =>
      'Apenas as formas que realmente aparecem no texto.';

  @override
  String showAllCount(int count) {
    return 'Ver todos ($count)';
  }

  @override
  String get markAsKnown => 'Marcar como conhecida';

  @override
  String get markedAsKnown => 'Conhecida';

  @override
  String get markAsKnownDone =>
      'Marcada como conhecida. Deixa de receber glosa no modo leitura.';

  @override
  String get transliterationLabel => 'Transliteração';

  @override
  String get refersToLabel => 'Refere-se a';

  @override
  String get subjectLabel => 'Sujeito';

  @override
  String get firstStepsHomeTitle => 'Comece aqui';

  @override
  String get firstStepsHomeDesc => 'Três letras, um versículo, cinco palavras.';

  @override
  String get firstStepsTitle => 'Seu primeiro versículo';

  @override
  String get firstStepsLettersTitle => 'Três letras';

  @override
  String get firstStepsLettersDesc =>
      'Estas três bastam para ler uma palavra real. Toque numa letra para ouvi-la.';

  @override
  String get firstStepsWordTitle => 'Uma palavra';

  @override
  String get firstStepsWordDesc =>
      'As letras que você acabou de ver, dentro de uma palavra da Bíblia.';

  @override
  String get firstStepsVerseTitle => 'Um versículo';

  @override
  String get firstStepsVerseDesc =>
      'Cada palavra traz seu som e seu sentido. Nada aqui é prova.';

  @override
  String get firstStepsVerseHint =>
      'Toque em qualquer palavra para ver o verbete completo.';

  @override
  String get firstStepsReviewTitle => 'Cinco palavras';

  @override
  String get firstStepsReviewDesc =>
      'As cinco palavras que valem guardar deste versículo. Uma passada e pronto.';

  @override
  String get firstStepsReviewButton => 'Revisar estas cinco';

  @override
  String get firstStepsStart => 'Começar';

  @override
  String get firstStepsContinue => 'Continuar';

  @override
  String get firstStepsRestart => 'Começar de novo';

  @override
  String firstVerseInMinutes(int minutes) {
    return 'Seu primeiro versículo em $minutes minutos.';
  }

  @override
  String get firstVerseUnderMinute =>
      'Seu primeiro versículo em menos de um minuto.';

  @override
  String get firstStepsDoneTitle => 'A entrada está feita';

  @override
  String get firstStepsDoneDesc =>
      'Letras, uma palavra, um versículo, cinco palavras que você vai reencontrar. O leitor está aberto para você.';

  @override
  String get firstStepsDoneReader => 'Abrir o leitor';

  @override
  String get verseLabel => 'Versículo';
}
