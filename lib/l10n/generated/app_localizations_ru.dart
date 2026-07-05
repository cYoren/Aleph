// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Оригинальная Библия';

  @override
  String get continueReading => 'Продолжить чтение';

  @override
  String get selectLanguage => 'Выберите язык';

  @override
  String get next => 'Далее';

  @override
  String get getStarted => 'Начать';

  @override
  String get skip => 'Пропустить';

  @override
  String get onboardingWelcomeTitle => 'Добро пожаловать';

  @override
  String get onboardingWelcomeDesc =>
      'Изучайте Библию на оригинальных языках с параллельными переводами.';

  @override
  String get onboardingHebrewTitle => 'Иврит - Ветхий Завет';

  @override
  String get onboardingHebrewDesc =>
      'Ветхий Завет был написан на иврите, который читается справа налево. Эти тексты были созданы более 2 500 лет назад и включают Тору, Псалмы и Пророков.';

  @override
  String get onboardingGreekTitle => 'Греческий - Новый Завет';

  @override
  String get onboardingGreekDesc =>
      'Новый Завет был написан на греческом языке, который читается слева направо. Евангелия и Послания были написаны между 50 и 100 гг. н.э.';

  @override
  String get onboardingTapTitle => 'Нажмите на любое слово';

  @override
  String get onboardingTapDesc =>
      'Нажмите на любое слово, чтобы увидеть его определение, произношение и грамматическую информацию. Включите кнопку произношения, чтобы видеть, как звучат слова.';

  @override
  String get settings => 'Настройки';

  @override
  String get translation => 'Перевод';

  @override
  String get pronunciation => 'Показывать произношение';

  @override
  String get pronunciationDesc => 'Показывать транслитерацию над словами';

  @override
  String get fontSize => 'Размер шрифта';

  @override
  String get theme => 'Тема';

  @override
  String get themeSystem => 'Системная';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get search => 'Поиск';

  @override
  String get searchHint => 'Поиск по библейскому тексту...';

  @override
  String get noResults => 'Ничего не найдено';

  @override
  String get verseOfDay => 'Стих дня';

  @override
  String get quickAccess => 'Быстрый доступ';

  @override
  String get home => 'Главная';

  @override
  String get books => 'Книги';

  @override
  String get oldTestament => 'Ветхий Завет';

  @override
  String get newTestament => 'Новый Завет';

  @override
  String get selectChapter => 'Выбрать главу';

  @override
  String chapters(int count) {
    return '$count глав';
  }

  @override
  String get translationNotAvailable => 'Перевод недоступен';

  @override
  String get noLexiconEntry => 'Лексическая статья недоступна';

  @override
  String get copyVerse => 'Копировать стих';

  @override
  String get shareVerse => 'Поделиться стихом';

  @override
  String get verseCopied => 'Стих скопирован в буфер обмена';

  @override
  String get addBookmark => 'Добавить закладку';

  @override
  String get removeBookmark => 'Удалить закладку';

  @override
  String get bookmarks => 'Закладки';

  @override
  String get noBookmarks => 'Закладок пока нет';

  @override
  String get noBookmarksDesc =>
      'Нажмите и удерживайте стих, затем нажмите значок закладки, чтобы сохранить его здесь.';

  @override
  String get removeBookmarkConfirmation => 'Удалить эту закладку?';

  @override
  String bookmarkTimeYearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# года назад',
      many: '# лет назад',
      few: '# года назад',
      one: '# год назад',
    );
    return '$_temp0';
  }

  @override
  String bookmarkTimeMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# месяца назад',
      many: '# месяцев назад',
      few: '# месяца назад',
      one: '# месяц назад',
    );
    return '$_temp0';
  }

  @override
  String bookmarkTimeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# дня назад',
      many: '# дней назад',
      few: '# дня назад',
      one: '# день назад',
    );
    return '$_temp0';
  }

  @override
  String bookmarkTimeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# часа назад',
      many: '# часов назад',
      few: '# часа назад',
      one: '# час назад',
    );
    return '$_temp0';
  }

  @override
  String bookmarkTimeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# минуты назад',
      many: '# минут назад',
      few: '# минуты назад',
      one: '# минуту назад',
    );
    return '$_temp0';
  }

  @override
  String get bookmarkTimeJustNow => 'Только что';

  @override
  String get quickMeaning => 'Краткое значение';

  @override
  String get fullDefinition => 'Полное определение';

  @override
  String get pronunciationLabel => 'Произношение';

  @override
  String get hebrewOT => 'Иврит • Ветхий Завет';

  @override
  String get greekNT => 'Греческий • Новый Завет';

  @override
  String get appResponsible => 'Ответственный за приложение';

  @override
  String get legalNameLabel => 'Юридическое название';

  @override
  String get tradeNameLabel => 'Торговое название';

  @override
  String get cnpjLabel => 'CNPJ';

  @override
  String get tryAgain => 'Попробовать снова';

  @override
  String get somethingWentWrong => 'Что-то пошло не так';

  @override
  String get error => 'Ошибка';

  @override
  String get learningMode => 'Режим обучения';

  @override
  String get learningModeDesc =>
      'Пассивно изучайте оригинальные языки, видя их в тексте.';

  @override
  String get learningModeEnglishOnlyNotice =>
      'Режим обучения пока поддерживает только английские переводы.';

  @override
  String get learningSectionTitle => 'Обучение';

  @override
  String get loading => 'Загрузка...';

  @override
  String onboardingBibleLabel(String translation) {
    return 'Библия: $translation';
  }

  @override
  String get syntaxTreeTitle => 'Синтаксическое дерево';

  @override
  String get viewSyntaxTree => 'Показать синтаксическое дерево';

  @override
  String get hebrewLabel => 'Иврит';

  @override
  String get greekLabel => 'Греческий';

  @override
  String get syntaxTreeTapHint =>
      'Нажмите на любой узел слова, чтобы увидеть полное определение';

  @override
  String get noMorphologicalData =>
      'Для этого стиха нет морфологических данных.';

  @override
  String get posVerb => 'Глагол';

  @override
  String get posNoun => 'Сущ.';

  @override
  String get posAdjectiveShort => 'Прил.';

  @override
  String get posPronoun => 'Мест.';

  @override
  String get posPrepositionShort => 'Предл.';

  @override
  String get posConjunctionShort => 'Союз';

  @override
  String strongsHebrewLabel(String number) {
    return 'Иврит $number';
  }

  @override
  String strongsGreekLabel(String number) {
    return 'Греческий $number';
  }

  @override
  String get lemmaDictionaryForm => 'Лемма (словарная форма)';

  @override
  String get grammar => 'Грамматика';

  @override
  String get topUsageByBook => 'Основное употребление по книгам';

  @override
  String get failedToLoadFrequencyData =>
      'Не удалось загрузить данные частоты.';

  @override
  String get noUsageDataAvailable => 'Данные об употреблении недоступны.';

  @override
  String get previousChapter => 'Предыдущая глава';

  @override
  String get nextChapter => 'Следующая глава';

  @override
  String get createCinematicImage => 'Создать кинематографическое изображение';

  @override
  String get srsQuestionPrompt => 'Что означает это слово в этом контексте?';

  @override
  String get revealAnswer => 'Показать ответ';

  @override
  String get didntKnow => 'Не знал';

  @override
  String get knewIt => 'Знал';

  @override
  String get srsPositiveFeedback => 'Отлично! Память слова улучшилась.';

  @override
  String get srsNegativeFeedback =>
      'Продолжайте практиковаться. Мы будем показывать это слово чаще.';

  @override
  String get exportVerseTitle => 'Экспорт стиха';

  @override
  String get shareImage => 'Поделиться изображением';

  @override
  String get backgroundTheme => 'Тема фона';

  @override
  String get aspectRatio => 'Соотношение сторон';

  @override
  String get failedToExportImage => 'Не удалось экспортировать изображение.';

  @override
  String get exportUnavailableTitle => 'Экспорт недоступен';

  @override
  String get missingExportRouteData =>
      'Отсутствуют данные маршрута для экспорта.';

  @override
  String get invalidExportRouteData =>
      'Некорректные данные маршрута для экспорта.';

  @override
  String get syntaxTreeUnavailableTitle => 'Синтаксическое дерево недоступно';

  @override
  String get missingSyntaxTreeRouteData =>
      'Отсутствуют данные маршрута для синтаксического дерева.';

  @override
  String get invalidSyntaxTreeRouteData =>
      'Некорректные данные маршрута для синтаксического дерева.';

  @override
  String get noStrongsAvailable => 'Номер Стронга отсутствует';

  @override
  String get wordStudyTitle => 'Изучение слова';

  @override
  String get seeAllUses => 'Показать все вхождения';

  @override
  String occurrencesTotal(int count) {
    return '$count вхождений в Библии';
  }

  @override
  String showingFirstOccurrences(int shown) {
    return 'Показаны первые $shown вхождений';
  }

  @override
  String get wordStudyUnavailableTitle => 'Изучение слова недоступно';

  @override
  String get missingWordStudyRouteData =>
      'Данные слова для этого экрана не были переданы.';

  @override
  String get syntaxTreeHeuristicNotice =>
      'Грамматический набросок на основе эвристик порядка слов — это не выверенные синтаксические данные.';

  @override
  String get readerMode => 'Режим читателя';

  @override
  String get readerModeDesc =>
      'Показывает небольшой перевод под редкими словами при чтении. Освоенные слова отображаются без подсказки.';

  @override
  String get vocabularyTitle => 'Словарный запас';

  @override
  String get dueForReviewSection => 'Пора повторить';

  @override
  String get mostFrequentSection => 'Самые частые слова';

  @override
  String vocabularyCoverage(String percent) {
    return 'Эти слова покрывают $percent% текста — учите их в первую очередь.';
  }
}
