// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Aleph';

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
      'Нажмите на любое слово, чтобы увидеть его определение, произношение и грамматическую информацию. Нажмите и удерживайте слово, чтобы быстро увидеть значение, не теряя место.';

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

  @override
  String get hebrewTextTitle => 'Еврейский текст';

  @override
  String get hebrewTextDesc =>
      'Чтение с меньшим числом знаков — веха в обучении';

  @override
  String get hebrewTextFull => 'Полный (с кантилляцией)';

  @override
  String get hebrewTextNoCantillation => 'Только огласовки';

  @override
  String get hebrewTextConsonantal => 'Только согласные';

  @override
  String get memorizationTitle => 'Заучивание';

  @override
  String get memorizationEmpty =>
      'Пока пусто. Добавьте псалом и начните скрывать слова.';

  @override
  String get addPassageTitle => 'Добавить отрывок';

  @override
  String get addPassageButton => 'Добавить';

  @override
  String get selectBookLabel => 'Книга';

  @override
  String get selectChapterLabel => 'Глава';

  @override
  String masteryLabel(String percent) {
    return 'Освоение $percent%';
  }

  @override
  String get dueNowLabel => 'Пора повторить';

  @override
  String get deletePassageTooltip => 'Удалить отрывок';

  @override
  String get levelWarmUp => 'Разминка';

  @override
  String get levelChallenge => 'Вызов';

  @override
  String get levelFirstLetters => 'Первые буквы';

  @override
  String get tapHiddenWordHint => 'Нажмите на скрытое слово, чтобы открыть его';

  @override
  String get howDidItGo => 'Как прошло?';

  @override
  String get struggledButton => 'Было трудно';

  @override
  String get gotItButton => 'Получилось';

  @override
  String nextReviewInDays(int count) {
    return 'Сохранено! Следующее повторение через $count дн.';
  }

  @override
  String nextReviewInHours(int count) {
    return 'Сохранено! Следующее повторение через $count ч.';
  }

  @override
  String get missingMemorizationRouteData =>
      'Данные отрывка для этого экрана не были переданы.';

  @override
  String get wordResultsSection => 'Слова';

  @override
  String get verseResultsSection => 'Стихи';

  @override
  String get crossReferencesTitle => 'Перекрёстные ссылки';

  @override
  String get noCrossReferences => 'Для этого стиха нет перекрёстных ссылок.';

  @override
  String get parsingQuizTitle => 'Разбор форм';

  @override
  String get whatFormIsThis => 'Что это за форма?';

  @override
  String get nextQuestion => 'Далее';

  @override
  String quizScore(int score, int total) {
    return 'Правильно $score из $total';
  }

  @override
  String get practiceAgain => 'Ещё раз';

  @override
  String get doneButton => 'Готово';

  @override
  String get syntaxSourceMacula =>
      'Синтаксические деревья: MACULA Hebrew & Greek (Clear Bible), CC BY 4.0';

  @override
  String get showMore => 'Показать больше';

  @override
  String get showLess => 'Свернуть';

  @override
  String get readabilityTitle => 'Что я могу читать?';

  @override
  String get readabilityAllBooks => 'Все книги, от самых доступных';

  @override
  String get readabilityNoText => 'Текст ещё не загружен.';

  @override
  String get readabilityCanReadNow => 'Это вы уже можете читать';

  @override
  String get readabilityClosest => 'Ближе всего к доступному';

  @override
  String get readabilityEmptyTitle =>
      'Начните учить слова, и эта карта заполнится';

  @override
  String get readabilityEmptyBody =>
      'По мере освоения лексики каждая книга показывает, какую её часть вы уже можете читать. Самые частые слова покрывают большую часть текста, поэтому вначале прогресс идёт быстро.';

  @override
  String get openVocabulary => 'Открыть словарь';

  @override
  String get reciteAloud => 'Читать вслух';

  @override
  String get stopReciting => 'Остановить чтение';

  @override
  String get recitationPreparing => 'Подготовка…';

  @override
  String get recitationStop => 'Стоп';

  @override
  String get hearItRead => 'Прослушать';

  @override
  String get phraseSpacingTitle => 'Деление на смысловые части';

  @override
  String get phraseSpacingDesc =>
      'Расставляет пробелы в еврейском тексте по масоретским акцентам, чтобы стих читался смысловыми единицами, а не слово за словом.';

  @override
  String get recitationVoiceTitle => 'Голос чтения';

  @override
  String get recitationVoiceDesc =>
      'Главы читают голоса, встроенные в приложение, — без загрузки и без интернета: новогреческий для Нового Завета. Еврейский текст читает голос вашего устройства, потому что голоса на иврите, который мы вправе включить, пока не существует. Это живые традиции чтения, а не реконструированное древнее произношение.';

  @override
  String get voiceMissing =>
      'Чтобы читать вслух, устройству нужен голос для иврита или греческого. Установка занимает минуту и требуется лишь один раз.';

  @override
  String get voiceUnsupported =>
      'На этом устройстве нет доступного синтезатора речи.';

  @override
  String get voiceInstall => 'Установить голос';

  @override
  String get voiceInstallUnavailable =>
      'На этом устройстве нет установщика голосов.';

  @override
  String get recitationFailed => 'Не удалось начать чтение.';

  @override
  String readBook(String book) {
    return 'Читать: $book';
  }

  @override
  String readabilityCoverage(int percent, int count) {
    return 'Вы знаете $percent % его лексики — около $count незнакомых слов на главу.';
  }

  @override
  String recitationVerse(int number) {
    return 'Стих $number';
  }

  @override
  String voiceMissingFor(String tradition) {
    return 'На этом устройстве не установлен голос «$tradition».';
  }

  @override
  String crossReferencesCount(int count) {
    return 'Перекрёстных ссылок: $count';
  }

  @override
  String get onboardingRecitationTitle => 'Послушайте чтение вслух';

  @override
  String get onboardingRecitationDesc =>
      'Нажмите воспроизведение, чтобы услышать чтение любой главы вслух. Новый Завет читает голос новогреческого, встроенный в приложение, поэтому он работает офлайн сразу после установки. Для иврита используется голос вашего устройства. Сильно замедлите чтение с помощью регулятора скорости, пока слух не начнёт успевать.';

  @override
  String get readingHintTitle => 'Три способа начать';

  @override
  String get readingHintBody =>
      'Нажмите на слово, чтобы увидеть его полное значение. Нажмите и удерживайте для быстрого предпросмотра, не теряя место. Нажмите ▶ вверху, чтобы услышать главу вслух.';

  @override
  String get readingHintDismiss => 'Понятно';

  @override
  String get explainTitle => 'Объяснить этот отрывок';

  @override
  String get explainLoading => 'Читаем отрывок…';

  @override
  String get explainDisclaimer =>
      'Написано ИИ. Может ошибаться — сверьте с текстом.';

  @override
  String get explainSettingTitle => 'Объяснение отрывков ИИ';

  @override
  String get explainSettingDesc =>
      'По умолчанию выключено. При включении читаемый отрывок отправляется через интернет для объяснения. Всё остальное в приложении работает полностью офлайн.';

  @override
  String get explainErrorOffline =>
      'Нет соединения. Это единственная функция, которой оно требуется.';

  @override
  String get explainErrorRateLimited =>
      'Слишком много запросов сейчас. Повторите попытку чуть позже.';

  @override
  String get explainErrorGeneric => 'Не удалось получить объяснение.';

  @override
  String get explainRetry => 'Повторить';

  @override
  String get explainLowQuality =>
      'Этот ответ выглядит неправильно. Повторите попытку — если повторяется, возможно, пора сменить модель.';

  @override
  String explainFreeRemaining(int count) {
    return 'Осталось бесплатных объяснений сегодня: $count';
  }

  @override
  String get explainLimitReached =>
      'Вы использовали бесплатные объяснения на сегодня.';

  @override
  String get explainUpgradeTitle => 'Без ограничений и с более сильной моделью';

  @override
  String get explainDiagnosticsTitle => 'Диагностика ИИ';

  @override
  String get explainDiagnosticsDesc =>
      'Доля успешных ответов и скорость модели. Загляните сюда, если ответы стали хуже обычного.';

  @override
  String get explainNoData => 'Объяснения ещё не запрашивались.';

  @override
  String get explainClearDiagnostics => 'Очистить историю';

  @override
  String get onboardingAiTitle => 'Спросите о любом отрывке';

  @override
  String get onboardingAiDesc =>
      'Наставник для вашего вопроса: что на самом деле говорит еврейский текст, что несёт греческий, чего не передаёт перевод. Нажмите ✨ у любого стиха.';

  @override
  String get onboardingAiToggle => 'Включить ИИ-наставника';

  @override
  String get onboardingAiPrivacy =>
      'Это единственная часть приложения, использующая интернет: стих, о котором вы спрашиваете, отправляется для объяснения. Всё остальное — текст, словари, грамматика, аудио — работает полностью офлайн. Это можно изменить в любой момент в настройках.';

  @override
  String get reciteFromHere => 'Читать вслух отсюда';

  @override
  String get searchEmptyTitle => 'Поиск по Библии';

  @override
  String get searchEmptyBody =>
      'Введите любые слова из стиха, чтобы найти его. Словарные статьи на иврите и греческом появляются под стихами.';

  @override
  String get alphabetTitle => 'Алфавит';

  @override
  String get alphabetHebrewIntro =>
      'Иврит читается справа налево. В нём двадцать две буквы, и все они согласные — точки и чёрточки над ними и под ними обозначают гласные. Изучайте по одной букве, спешить некуда.';

  @override
  String get alphabetGreekIntro =>
      'Греческий читается слева направо и имеет заглавные и строчные буквы. В отличие от иврита, гласные здесь — самостоятельные буквы. Изучайте по одной букве, спешить некуда.';

  @override
  String get alphabetLettersSection => 'Буквы';

  @override
  String get alphabetVowelsSection => 'Гласные';

  @override
  String get alphabetVowelsIntro =>
      'Гласные — это знаки вокруг буквы. Здесь они показаны на букве бет (ב).';

  @override
  String get alphabetFinalForm => 'конечная';

  @override
  String get alphabetExampleLabel => 'В Библии';

  @override
  String get wordConnections => 'Связи между словами';

  @override
  String get wordConnectionsDesc =>
      'Проводит линии к другим случаям употребления выбранного слова. По умолчанию отключено: линии пересекают читаемый текст.';

  @override
  String get memorizationSubtitle =>
      'Скрывайте слова в отрывке, который вы уже читаете свободно.';

  @override
  String get onboardingTraditionTitle => 'Какие писания вы читаете?';

  @override
  String get onboardingTraditionDesc =>
      'От этого зависит порядок книг и их названия. Ничего не скрывается ни в одном из вариантов, и это можно изменить в настройках.';

  @override
  String get traditionChristian => 'Ветхий и Новый Завет';

  @override
  String get traditionChristianDesc =>
      'Христианский порядок, от Бытия до Откровения.';

  @override
  String get traditionJewish => 'Танах';

  @override
  String get traditionJewishDesc =>
      'Тора, Невиим и Ктувим, в традиционном еврейском порядке.';

  @override
  String get tanakhTorah => 'Тора';

  @override
  String get tanakhNeviim => 'Невиим — Пророки';

  @override
  String get tanakhKetuvim => 'Ктувим — Писания';

  @override
  String get hebrewBibleLabel => 'Еврейская Библия';

  @override
  String get traditionSettingTitle => 'Писания';

  @override
  String get reviewReminderSetting => 'Ежедневное напоминание о повторении';

  @override
  String get reviewReminderSettingSubtitle =>
      'Вечернее напоминание, когда пора повторить слова';

  @override
  String reminderDueTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count слова готовы к повторению',
      many: '$count слов готовы к повторению',
      few: '$count слова готовы к повторению',
      one: '$count слово готово к повторению',
    );
    return '$_temp0';
  }

  @override
  String get reminderDueBody => 'Пять минут сейчас, и слова не забудутся.';

  @override
  String get reminderReadTitle => 'Ваш стих на сегодня ждёт';

  @override
  String get reminderReadBody =>
      'Прочитайте один стих на иврите или греческом до конца дня.';

  @override
  String get pathTitle => 'Путь по книге';

  @override
  String get pathHomeStart => 'Выберите книгу и выучите именно её слова';

  @override
  String get pathChooseBook => 'Выберите книгу, чтобы читать её в оригинале';

  @override
  String pathWordsToGoal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count слова до 80% книги',
      many: '$count слов до 80% книги',
      few: '$count слова до 80% книги',
      one: '$count слово до 80% книги',
    );
    return '$_temp0';
  }

  @override
  String pathCoverage(int percent, String book) {
    return 'Вы уже можете прочитать $percent% книги $book';
  }

  @override
  String pathLearning(int percent) {
    return '$percent% вместе со словами, которые вы учите';
  }

  @override
  String get pathGoalReached =>
      'Вы можете прочитать большую часть этой книги. Откройте её!';

  @override
  String get pathLearnNext => 'Учить следующие слова';

  @override
  String get pathWordsInBook => 'Слова этой книги, от частых к редким';

  @override
  String get pathChangeBook => 'Сменить книгу';

  @override
  String get pathShare => 'Поделиться прогрессом';

  @override
  String shareCardHebrew(int percent, String book) {
    return 'Я выучил(а) $percent% слов книги $book на иврите';
  }

  @override
  String shareCardGreek(int percent, String book) {
    return 'Я выучил(а) $percent% слов книги $book на греческом';
  }

  @override
  String get shareCardFooter => 'Учусь с Aleph';

  @override
  String get pathAllLearned =>
      'Вы начали учить все слова этой книги. Продолжайте повторять!';

  @override
  String get dailySessionStart => 'Ваши 5 минут на сегодня';

  @override
  String get dailySessionDone => 'На сегодня всё. До завтра!';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дня подряд',
      many: '$count дней подряд',
      few: '$count дня подряд',
      one: '$count день подряд',
    );
    return '$_temp0';
  }

  @override
  String get nameTitle => 'Что означает ваше имя?';

  @override
  String get nameHint => 'Введите своё имя';

  @override
  String nameMeans(String name, String meaning) {
    return '$name означает «$meaning»';
  }

  @override
  String nameCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Встречается в Библии $count раза',
      many: 'Встречается в Библии $count раз',
      few: 'Встречается в Библии $count раза',
      one: 'Встречается в Библии $count раз',
    );
    return '$_temp0';
  }

  @override
  String get nameNotFound =>
      'Этого имени пока нет в списке. Попробуйте другое написание.';

  @override
  String get nameShare => 'Поделиться';

  @override
  String get usageSharingTitle => 'Отправлять анонимную статистику';

  @override
  String get usageSharingSubtitle =>
      'Какие функции используются. Никогда не то, что вы читаете, и ничего, что вас идентифицирует.';

  @override
  String get supportTitle => 'Поддержать Aleph';

  @override
  String get supportBody =>
      'Aleph: работа одного человека. Без рекламы, без подписки, без слежки. Разовый донат помогает тексту, голосам и обновлениям выходить дальше.';

  @override
  String get supportNote =>
      'Донат ничего не открывает. Каждое слово Aleph уже ваше.';

  @override
  String get supportTierSmall => 'Небольшой донат';

  @override
  String get supportTierMedium => 'Щедрый донат';

  @override
  String get supportTierLarge => 'Крупный донат';

  @override
  String get supportThanks => 'Спасибо. Это правда помогает.';

  @override
  String get supportUnavailable => 'Донаты сейчас недоступны.';

  @override
  String get supportClose => 'Не сейчас';

  @override
  String get supportTerms => 'Условия';

  @override
  String get supportPrivacy => 'Конфиденциальность';

  @override
  String get morphHebrew => 'Иврит';

  @override
  String get morphAramaic => 'Арамейский';

  @override
  String get morphAdjective => 'Прилагательное';

  @override
  String get morphConjunction => 'Союз';

  @override
  String get morphAdverb => 'Наречие';

  @override
  String get morphNoun => 'Существительное';

  @override
  String get morphPronoun => 'Местоимение';

  @override
  String get morphPreposition => 'Предлог';

  @override
  String get morphSuffix => 'Суффикс';

  @override
  String get morphParticle => 'Частица';

  @override
  String get morphVerb => 'Глагол';

  @override
  String get morphArticle => 'Артикль';

  @override
  String get morphInterjection => 'Междометие';

  @override
  String get morphCommon => 'нарицательное';

  @override
  String get morphProper => 'собственное';

  @override
  String get morphGentilic => 'этникон';

  @override
  String get morphMasculine => 'мужской';

  @override
  String get morphFeminine => 'женский';

  @override
  String get morphBothGenders => 'оба рода';

  @override
  String get morphNeuter => 'средний';

  @override
  String get morphSingular => 'единственное';

  @override
  String get morphPlural => 'множественное';

  @override
  String get morphDual => 'двойственное';

  @override
  String get morphAbsolute => 'абсолютное';

  @override
  String get morphConstruct => 'сопряжённое';

  @override
  String get morphDetermined => 'определённое';

  @override
  String get morphFirstPerson => '1-е лицо';

  @override
  String get morphSecondPerson => '2-е лицо';

  @override
  String get morphThirdPerson => '3-е лицо';

  @override
  String get morphPerfect => 'Перфект';

  @override
  String get morphSequentialPerfect => 'Последовательный перфект';

  @override
  String get morphImperfect => 'Имперфект';

  @override
  String get morphSequentialImperfect => 'Последовательный имперфект';

  @override
  String get morphCohortative => 'Когортатив';

  @override
  String get morphJussive => 'Юссив';

  @override
  String get morphImperative => 'Императив';

  @override
  String get morphParticipleActive => 'Причастие действительное';

  @override
  String get morphParticiplePassive => 'Причастие страдательное';

  @override
  String get morphInfinitiveAbsolute => 'Абсолютный инфинитив';

  @override
  String get morphInfinitiveConstruct => 'Сопряжённый инфинитив';

  @override
  String get morphCardinalNumber => 'количественное числительное';

  @override
  String get morphOrdinalNumber => 'порядковое числительное';

  @override
  String get morphDemonstrative => 'указательное';

  @override
  String get morphIndefinite => 'неопределённое';

  @override
  String get morphInterrogative => 'вопросительное';

  @override
  String get morphPersonal => 'личное';

  @override
  String get morphRelative => 'относительное';

  @override
  String get morphReciprocal => 'взаимное';

  @override
  String get morphReflexive => 'возвратное';

  @override
  String get morphPossessive => 'притяжательное';

  @override
  String get morphCorrelative => 'коррелятивное';

  @override
  String get morphDirectional => 'направительное';

  @override
  String get morphParagogicHe => 'парагогический хе';

  @override
  String get morphParagogicNun => 'парагогический нун';

  @override
  String get morphPronominal => 'местоименный';

  @override
  String get morphPresent => 'Настоящее';

  @override
  String get morphFuture => 'Будущее';

  @override
  String get morphAorist => 'Аорист';

  @override
  String get morphPluperfect => 'Плюсквамперфект';

  @override
  String get morphNoTense => 'Без времени';

  @override
  String get morphActive => 'Действительный';

  @override
  String get morphMiddle => 'Средний';

  @override
  String get morphPassive => 'Страдательный';

  @override
  String get morphMiddlePassive => 'Средний/Страдательный';

  @override
  String get morphMiddleDeponent => 'Средний депонент';

  @override
  String get morphPassiveDeponent => 'Страдательный депонент';

  @override
  String get morphMiddlePassiveDeponent => 'Средний/Страдательный депонент';

  @override
  String get morphIndicative => 'Изъявительное';

  @override
  String get morphSubjunctive => 'Сослагательное';

  @override
  String get morphOptative => 'Оптатив';

  @override
  String get morphInfinitive => 'Инфинитив';

  @override
  String get morphParticiple => 'Причастие';

  @override
  String get morphNominative => 'Именительный';

  @override
  String get morphGenitive => 'Родительный';

  @override
  String get morphDative => 'Дательный';

  @override
  String get morphAccusative => 'Винительный';

  @override
  String get morphVocative => 'Звательный';

  @override
  String get contentSourceNote =>
      'Показано на английском; перевод пока недоступен.';

  @override
  String get recitationVoiceHebrewGap =>
      'Для иврита используется голос вашего устройства. Встроенный голос на иврите пока не прошёл проверку для Aleph.';

  @override
  String get contentLoadError =>
      'Не удалось загрузить содержимое. Попробуйте ещё раз.';

  @override
  String get diagnosticsSuccess => 'Успешность';

  @override
  String get diagnosticsMedian => 'Медианное время';

  @override
  String get diagnosticsCalls => 'Запросы';

  @override
  String get diagnosticsPoorAnswers => 'Некачественные ответы';

  @override
  String get diagnosticsErrors => 'Ошибки';

  @override
  String get diagnosticsLastProblem => 'Последняя проблема';

  @override
  String get diagnosticsInUse => 'Используется';

  @override
  String get diagnosticsNotUsed => 'Ещё не использовалась';

  @override
  String get diagnosticsTooEarly => 'Пока рано оценивать';

  @override
  String get diagnosticsEarlyProblems => 'Пока рано оценивать. Были проблемы.';

  @override
  String get diagnosticsFailing =>
      'Не работает должным образом. Смените модель.';

  @override
  String get diagnosticsUnreliable => 'Ненадёжно. Подумайте о смене модели.';

  @override
  String get diagnosticsSlow => 'Очень медленно. Подумайте о смене модели.';

  @override
  String get diagnosticsMostlyGood =>
      'В целом работает. Есть некачественные ответы.';

  @override
  String get diagnosticsHealthy => 'Работает хорошо';

  @override
  String get sensesLabel => 'Значения';

  @override
  String get sensesUnavailable =>
      'У этой словарной статьи нет нумерованных значений.';

  @override
  String get rootLabel => 'Корень';

  @override
  String get rootWordsTitle => 'Слова этого корня';

  @override
  String rootWordCount(int count) {
    return '$count слов';
  }

  @override
  String get formsInTextLabel => 'Формы в тексте';

  @override
  String get formsInTextNote =>
      'Только формы, которые действительно встречаются в тексте.';

  @override
  String showAllCount(int count) {
    return 'Показать все ($count)';
  }

  @override
  String get markAsKnown => 'Отметить как известное';

  @override
  String get markedAsKnown => 'Известно';

  @override
  String get markAsKnownDone =>
      'Отмечено как известное. В режиме чтения оно больше не поясняется.';

  @override
  String get transliterationLabel => 'Транслитерация';

  @override
  String get refersToLabel => 'Относится к';

  @override
  String get subjectLabel => 'Подлежащее';

  @override
  String get firstStepsHomeTitle => 'Начните здесь';

  @override
  String get firstStepsHomeDesc => 'Три буквы, один стих, пять слов.';

  @override
  String get firstStepsTitle => 'Ваш первый стих';

  @override
  String get firstStepsLettersTitle => 'Три буквы';

  @override
  String get firstStepsLettersDesc =>
      'Этих трёх хватит, чтобы прочесть настоящее слово. Коснитесь буквы, чтобы услышать её.';

  @override
  String get firstStepsWordTitle => 'Одно слово';

  @override
  String get firstStepsWordDesc =>
      'Только что встреченные буквы внутри слова из Библии.';

  @override
  String get firstStepsVerseTitle => 'Один стих';

  @override
  String get firstStepsVerseDesc =>
      'У каждого слова есть звучание и значение. Здесь нет проверки.';

  @override
  String get firstStepsVerseHint =>
      'Коснитесь любого слова, чтобы открыть статью словаря.';

  @override
  String get firstStepsReviewTitle => 'Пять слов';

  @override
  String get firstStepsReviewDesc =>
      'Пять слов из этого стиха, которые стоит сохранить. Один проход, и всё.';

  @override
  String get firstStepsReviewButton => 'Повторить эти пять';

  @override
  String get firstStepsStart => 'Начать';

  @override
  String get firstStepsContinue => 'Продолжить';

  @override
  String get firstStepsRestart => 'Начать заново';

  @override
  String firstVerseInMinutes(int minutes) {
    return 'Ваш первый стих за $minutes минут.';
  }

  @override
  String get firstVerseUnderMinute => 'Ваш первый стих меньше чем за минуту.';

  @override
  String get firstStepsDoneTitle => 'Вход найден';

  @override
  String get firstStepsDoneDesc =>
      'Буквы, слово, стих, пять слов, которые встретятся снова. Читатель открыт для вас.';

  @override
  String get firstStepsDoneReader => 'Открыть чтение';

  @override
  String get verseLabel => 'Стих';
}
