// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Bíblia Original';

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
      'Toque em qualquer palavra para ver sua definição, pronúncia e informação gramatical. Ative o botão de pronúncia para ver como as palavras são faladas.';

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
  String get learningModeEnglishOnlyNotice =>
      'O Modo de Aprendizado atualmente oferece suporte apenas a traduções em inglês.';

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
}
