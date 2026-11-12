// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Aleph';

  @override
  String get continueReading => '계속 읽기';

  @override
  String get selectLanguage => '언어 선택';

  @override
  String get next => '다음';

  @override
  String get getStarted => '시작하기';

  @override
  String get skip => '건너뛰기';

  @override
  String get onboardingWelcomeTitle => '환영합니다';

  @override
  String get onboardingWelcomeDesc => '원어 성경과 번역을 나란히 읽어 보세요.';

  @override
  String get onboardingHebrewTitle => '히브리어 - 구약';

  @override
  String get onboardingHebrewDesc =>
      '구약은 히브리어로 기록되었고 오른쪽에서 왼쪽으로 읽습니다. 이 본문들은 2,500년 이상 전에 기록되었으며 토라, 시편, 예언서를 포함합니다.';

  @override
  String get onboardingGreekTitle => '그리스어 - 신약';

  @override
  String get onboardingGreekDesc =>
      '신약은 그리스어로 기록되었고 왼쪽에서 오른쪽으로 읽습니다. 복음서와 서신서는 서기 50-100년 사이에 기록되었습니다.';

  @override
  String get onboardingTapTitle => '단어를 눌러보세요';

  @override
  String get onboardingTapDesc =>
      '단어를 누르면 정의, 발음, 문법 정보를 볼 수 있습니다. 단어를 길게 누르면 읽던 자리를 벗어나지 않고 빠르게 뜻을 확인할 수 있습니다.';

  @override
  String get settings => '설정';

  @override
  String get translation => '번역';

  @override
  String get pronunciation => '발음 표시';

  @override
  String get pronunciationDesc => '단어 위에 음역 표시';

  @override
  String get fontSize => '글자 크기';

  @override
  String get theme => '테마';

  @override
  String get themeSystem => '시스템';

  @override
  String get themeLight => '라이트';

  @override
  String get themeDark => '다크';

  @override
  String get search => '검색';

  @override
  String get searchHint => '성경 본문 검색...';

  @override
  String get noResults => '검색 결과가 없습니다';

  @override
  String get verseOfDay => '오늘의 구절';

  @override
  String get quickAccess => '빠른 접근';

  @override
  String get home => '홈';

  @override
  String get books => '성경 권';

  @override
  String get oldTestament => '구약';

  @override
  String get newTestament => '신약';

  @override
  String get selectChapter => '장 선택';

  @override
  String chapters(int count) {
    return '$count장';
  }

  @override
  String get translationNotAvailable => '번역을 사용할 수 없습니다';

  @override
  String get noLexiconEntry => '사전 항목이 없습니다';

  @override
  String get copyVerse => '구절 복사';

  @override
  String get shareVerse => '구절 공유';

  @override
  String get verseCopied => '구절이 클립보드에 복사되었습니다';

  @override
  String get addBookmark => '북마크 추가';

  @override
  String get removeBookmark => '북마크 제거';

  @override
  String get bookmarks => '북마크';

  @override
  String get noBookmarks => '북마크가 없습니다';

  @override
  String get noBookmarksDesc => '구절을 길게 누르고 북마크 아이콘을 눌러 여기에 저장하세요.';

  @override
  String get removeBookmarkConfirmation => '이 북마크를 삭제할까요?';

  @override
  String bookmarkTimeYearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '#년 전',
      one: '#년 전',
    );
    return '$_temp0';
  }

  @override
  String bookmarkTimeMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '#개월 전',
      one: '#개월 전',
    );
    return '$_temp0';
  }

  @override
  String bookmarkTimeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '#일 전',
      one: '#일 전',
    );
    return '$_temp0';
  }

  @override
  String bookmarkTimeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '#시간 전',
      one: '#시간 전',
    );
    return '$_temp0';
  }

  @override
  String bookmarkTimeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '#분 전',
      one: '#분 전',
    );
    return '$_temp0';
  }

  @override
  String get bookmarkTimeJustNow => '방금 전';

  @override
  String get quickMeaning => '빠른 의미';

  @override
  String get fullDefinition => '전체 정의';

  @override
  String get pronunciationLabel => '발음';

  @override
  String get hebrewOT => '히브리어 • 구약';

  @override
  String get greekNT => '그리스어 • 신약';

  @override
  String get appResponsible => '앱 책임 주체';

  @override
  String get legalNameLabel => '법인명';

  @override
  String get tradeNameLabel => '상호명';

  @override
  String get cnpjLabel => 'CNPJ';

  @override
  String get tryAgain => '다시 시도';

  @override
  String get somethingWentWrong => '문제가 발생했습니다';

  @override
  String get error => '오류';

  @override
  String get learningMode => '학습 모드';

  @override
  String get learningModeDesc => '본문 속 원어를 보며 수동적으로 학습하세요.';

  @override
  String get learningSectionTitle => '학습';

  @override
  String get loading => '불러오는 중...';

  @override
  String onboardingBibleLabel(String translation) {
    return '성경: $translation';
  }

  @override
  String get syntaxTreeTitle => '구문 트리';

  @override
  String get viewSyntaxTree => '구문 트리 보기';

  @override
  String get hebrewLabel => '히브리어';

  @override
  String get greekLabel => '그리스어';

  @override
  String get syntaxTreeTapHint => '단어 노드를 누르면 전체 정의를 볼 수 있습니다';

  @override
  String get noMorphologicalData => '이 구절에는 형태론 데이터가 없습니다.';

  @override
  String get posVerb => '동사';

  @override
  String get posNoun => '명사';

  @override
  String get posAdjectiveShort => '형.';

  @override
  String get posPronoun => '대명사';

  @override
  String get posPrepositionShort => '전.';

  @override
  String get posConjunctionShort => '접.';

  @override
  String strongsHebrewLabel(String number) {
    return '히브리어 $number';
  }

  @override
  String strongsGreekLabel(String number) {
    return '그리스어 $number';
  }

  @override
  String get lemmaDictionaryForm => '표제어(사전형)';

  @override
  String get grammar => '문법';

  @override
  String get topUsageByBook => '책별 주요 사용';

  @override
  String get failedToLoadFrequencyData => '빈도 데이터를 불러오지 못했습니다.';

  @override
  String get noUsageDataAvailable => '사용 데이터가 없습니다.';

  @override
  String get previousChapter => '이전 장';

  @override
  String get nextChapter => '다음 장';

  @override
  String get createCinematicImage => '시네마틱 이미지 만들기';

  @override
  String get srsQuestionPrompt => '이 문맥에서 이 단어는 무슨 뜻인가요?';

  @override
  String get revealAnswer => '정답 보기';

  @override
  String get didntKnow => '몰랐어요';

  @override
  String get knewIt => '알고 있었어요';

  @override
  String get srsPositiveFeedback => '좋아요! 단어 기억도가 올라갔습니다.';

  @override
  String get srsNegativeFeedback => '계속 연습하세요. 이 단어를 더 자주 보여드릴게요.';

  @override
  String get exportVerseTitle => '구절 내보내기';

  @override
  String get shareImage => '이미지 공유';

  @override
  String get backgroundTheme => '배경 테마';

  @override
  String get aspectRatio => '비율';

  @override
  String get failedToExportImage => '이미지 내보내기에 실패했습니다.';

  @override
  String get exportUnavailableTitle => '내보내기를 사용할 수 없음';

  @override
  String get missingExportRouteData => '내보내기에 필요한 경로 데이터가 없습니다.';

  @override
  String get invalidExportRouteData => '내보내기에 필요한 경로 데이터가 올바르지 않습니다.';

  @override
  String get syntaxTreeUnavailableTitle => '구문 트리를 사용할 수 없음';

  @override
  String get missingSyntaxTreeRouteData => '구문 트리에 필요한 경로 데이터가 없습니다.';

  @override
  String get invalidSyntaxTreeRouteData => '구문 트리에 필요한 경로 데이터가 올바르지 않습니다.';

  @override
  String get noStrongsAvailable => 'Strong 번호 없음';

  @override
  String get wordStudyTitle => '단어 연구';

  @override
  String get seeAllUses => '모든 용례 보기';

  @override
  String occurrencesTotal(int count) {
    return '성경에서 $count회 사용됨';
  }

  @override
  String showingFirstOccurrences(int shown) {
    return '처음 $shown개 용례만 표시';
  }

  @override
  String get wordStudyUnavailableTitle => '단어 연구를 사용할 수 없음';

  @override
  String get missingWordStudyRouteData => '이 화면에 필요한 단어 데이터가 제공되지 않았습니다.';

  @override
  String get syntaxTreeHeuristicNotice =>
      '어순 휴리스틱에 기반한 문법 스케치이며, 검증된 구문 데이터가 아닙니다.';

  @override
  String get readerMode => '리더 모드';

  @override
  String get readerModeDesc =>
      '읽는 동안 드문 단어 아래에 짧은 번역을 표시합니다. 익힌 단어는 도움말 없이 표시됩니다.';

  @override
  String get vocabularyTitle => '어휘';

  @override
  String get dueForReviewSection => '복습할 단어';

  @override
  String get mostFrequentSection => '가장 자주 나오는 단어';

  @override
  String vocabularyCoverage(String percent) {
    return '이 단어들은 본문의 $percent%를 차지합니다 — 먼저 학습하세요.';
  }

  @override
  String get hebrewTextTitle => '히브리어 텍스트';

  @override
  String get hebrewTextDesc => '기호를 줄여 읽는 것은 학습의 이정표입니다';

  @override
  String get hebrewTextFull => '전체 (칸틸레이션 포함)';

  @override
  String get hebrewTextNoCantillation => '모음 기호만';

  @override
  String get hebrewTextConsonantal => '자음만';

  @override
  String get memorizationTitle => '암송';

  @override
  String get memorizationEmpty => '아직 아무것도 없습니다. 시편을 추가하고 단어 숨기기를 시작하세요.';

  @override
  String get addPassageTitle => '구절 추가';

  @override
  String get addPassageButton => '추가';

  @override
  String get selectBookLabel => '책';

  @override
  String get selectChapterLabel => '장';

  @override
  String masteryLabel(String percent) {
    return '숙달도 $percent%';
  }

  @override
  String get dueNowLabel => '복습 시간';

  @override
  String get deletePassageTooltip => '구절 제거';

  @override
  String get levelWarmUp => '준비 운동';

  @override
  String get levelChallenge => '도전';

  @override
  String get levelFirstLetters => '첫 글자';

  @override
  String get tapHiddenWordHint => '숨겨진 단어를 누르면 나타납니다';

  @override
  String get howDidItGo => '어땠나요?';

  @override
  String get struggledButton => '어려웠어요';

  @override
  String get gotItButton => '외웠어요';

  @override
  String nextReviewInDays(int count) {
    return '저장됨! $count일 후 복습합니다.';
  }

  @override
  String nextReviewInHours(int count) {
    return '저장됨! $count시간 후 복습합니다.';
  }

  @override
  String get missingMemorizationRouteData => '이 화면에 필요한 구절 데이터가 제공되지 않았습니다.';

  @override
  String get wordResultsSection => '단어';

  @override
  String get verseResultsSection => '구절';

  @override
  String get crossReferencesTitle => '관주 성구';

  @override
  String get noCrossReferences => '이 구절에는 관주가 없습니다.';

  @override
  String get parsingQuizTitle => '형태 분석 연습';

  @override
  String get whatFormIsThis => '이 단어는 어떤 형태일까요?';

  @override
  String get nextQuestion => '다음';

  @override
  String quizScore(int score, int total) {
    return '$total문제 중 $score개 정답';
  }

  @override
  String get practiceAgain => '다시 연습';

  @override
  String get doneButton => '완료';

  @override
  String get syntaxSourceMacula =>
      '구문 트리: MACULA 히브리어·그리스어 (Clear Bible), CC BY 4.0';

  @override
  String get showMore => '더 보기';

  @override
  String get showLess => '접기';

  @override
  String get readabilityTitle => '무엇을 읽을 수 있나요?';

  @override
  String get readabilityAllBooks => '모든 책, 읽기 쉬운 순서';

  @override
  String get readabilityNoText => '아직 본문이 불러와지지 않았습니다.';

  @override
  String get readabilityCanReadNow => '지금 읽을 수 있습니다';

  @override
  String get readabilityClosest => '가장 읽기에 가까운 책';

  @override
  String get readabilityEmptyTitle => '단어를 익히면 이 지도가 채워집니다';

  @override
  String get readabilityEmptyBody =>
      '어휘를 익혀 갈수록 각 책에서 이미 읽을 수 있는 비율이 표시됩니다. 자주 쓰이는 단어가 본문의 대부분을 차지하므로 처음에는 빠르게 늘어납니다.';

  @override
  String get openVocabulary => '어휘 열기';

  @override
  String get reciteAloud => '소리내어 읽기';

  @override
  String get stopReciting => '읽기 중지';

  @override
  String get recitationPreparing => '준비 중…';

  @override
  String get recitationStop => '중지';

  @override
  String get hearItRead => '발음 듣기';

  @override
  String get phraseSpacingTitle => '의미 단위 띄어쓰기';

  @override
  String get phraseSpacingDesc =>
      '마소라 악센트에 따라 히브리어 본문을 띄어, 절을 단어 단위가 아니라 의미 단위로 읽게 합니다.';

  @override
  String get recitationVoiceTitle => '낭독 음성';

  @override
  String get recitationVoiceDesc =>
      '기기의 음성으로 읽어 줍니다. 히브리어는 현대 이스라엘 발음, 그리스어는 현대 그리스 발음입니다. 재구성한 고대 발음이 아니라 지금도 사용되는 낭독 전통입니다.';

  @override
  String get voiceMissing =>
      '소리 내어 읽으려면 기기에 히브리어 또는 그리스어 음성이 필요합니다. 설치는 잠시면 되고 한 번만 하면 됩니다.';

  @override
  String get voiceUnsupported => '이 기기에는 사용할 수 있는 음성 엔진이 없습니다.';

  @override
  String get voiceInstall => '음성 설치';

  @override
  String get voiceInstallUnavailable => '이 기기에는 열 수 있는 음성 설치 프로그램이 없습니다.';

  @override
  String get recitationFailed => '낭독을 시작할 수 없습니다.';

  @override
  String readBook(String book) {
    return '$book 읽기';
  }

  @override
  String readabilityCoverage(int percent, int count) {
    return '이 책 어휘의 $percent%를 알고 있습니다. 장마다 모르는 단어가 약 $count개입니다.';
  }

  @override
  String recitationVerse(int number) {
    return '$number절';
  }

  @override
  String voiceMissingFor(String tradition) {
    return '이 기기에 $tradition 음성이 설치되어 있지 않습니다.';
  }

  @override
  String crossReferencesCount(int count) {
    return '교차 참조 $count개';
  }

  @override
  String get onboardingRecitationTitle => '낭독으로 들어보세요';

  @override
  String get onboardingRecitationDesc =>
      '재생 버튼을 누르면 어느 장이든 히브리어나 그리스어로 낭독되는 것을 들을 수 있습니다. 복원된 고대 발음이 아니라 지금도 쓰이는 살아 있는 발음입니다. 속도 조절로 천천히 낮춰 귀에 익을 때까지 들어 보세요.';

  @override
  String get readingHintTitle => '시작하는 세 가지 방법';

  @override
  String get readingHintBody =>
      '단어를 누르면 전체 뜻을 볼 수 있습니다. 길게 누르면 자리를 벗어나지 않고 빠르게 미리 볼 수 있습니다. 위쪽의 ▶를 누르면 이 장의 낭독을 들을 수 있습니다.';

  @override
  String get readingHintDismiss => '확인';

  @override
  String get explainTitle => '이 구절 설명하기';

  @override
  String get explainLoading => '구절을 읽는 중…';

  @override
  String get explainDisclaimer => 'AI가 작성했습니다. 틀릴 수 있으니 본문과 대조해 보세요.';

  @override
  String get explainSettingTitle => 'AI 구절 설명';

  @override
  String get explainSettingDesc =>
      '기본적으로 꺼져 있습니다. 켜면 읽고 있는 구절이 설명을 위해 인터넷으로 전송됩니다. 그 밖의 모든 기능은 완전히 오프라인으로 동작합니다.';

  @override
  String get explainErrorOffline => '연결이 없습니다. 인터넷이 필요한 유일한 기능입니다.';

  @override
  String get explainErrorRateLimited => '요청이 너무 많습니다. 잠시 후 다시 시도해 주세요.';

  @override
  String get explainErrorGeneric => '설명을 생성하지 못했습니다.';

  @override
  String get explainRetry => '다시 시도';

  @override
  String get explainLowQuality =>
      '이 답변은 이상해 보입니다. 다시 시도해 보세요. 계속 반복되면 모델을 교체해야 할 수 있습니다.';

  @override
  String explainFreeRemaining(int count) {
    return '오늘 남은 무료 설명 $count회';
  }

  @override
  String get explainLimitReached => '오늘의 무료 설명을 모두 사용했습니다.';

  @override
  String get explainUpgradeTitle => '무제한, 그리고 더 뛰어난 모델';

  @override
  String get explainDiagnosticsTitle => 'AI 진단';

  @override
  String get explainDiagnosticsDesc =>
      '질문에 답하는 모델의 성공률과 속도입니다. 답변이 평소보다 나빠 보이면 여기를 확인하세요.';

  @override
  String get explainNoData => '아직 요청한 설명이 없습니다.';

  @override
  String get explainClearDiagnostics => '기록 지우기';

  @override
  String get onboardingAiTitle => '어떤 구절이든 물어보세요';

  @override
  String get onboardingAiDesc =>
      '당신의 질문을 위한 선생님: 히브리어가 실제로 무엇을 말하는지, 그리스어가 번역이 담지 못한 무엇을 지니는지. 어떤 절에서든 ✨를 누르세요.';

  @override
  String get onboardingAiToggle => 'AI 선생님 사용';

  @override
  String get onboardingAiPrivacy =>
      '이 기능만 인터넷을 사용합니다. 질문한 절이 설명을 위해 전송됩니다. 본문, 사전, 문법, 음성 등 나머지는 모두 완전히 오프라인으로 동작합니다. 설정에서 언제든 변경할 수 있습니다.';

  @override
  String get reciteFromHere => '여기서부터 낭독';

  @override
  String get searchEmptyTitle => '성경 검색';

  @override
  String get searchEmptyBody =>
      '구절에 나오는 아무 단어나 입력하면 그 구절을 찾을 수 있습니다. 히브리어와 그리스어 사전 항목은 구절 아래에 표시됩니다.';

  @override
  String get alphabetTitle => '알파벳';

  @override
  String get alphabetHebrewIntro =>
      '히브리어는 오른쪽에서 왼쪽으로 읽습니다. 스물두 개의 글자가 있으며 모두 자음입니다. 글자 위아래에 찍힌 점과 선이 모음입니다. 한 번에 한 글자씩, 서두르지 마세요.';

  @override
  String get alphabetGreekIntro =>
      '그리스어는 왼쪽에서 오른쪽으로 읽으며 대문자와 소문자가 있습니다. 히브리어와 달리 모음이 그 자체로 글자입니다. 한 번에 한 글자씩, 서두르지 마세요.';

  @override
  String get alphabetLettersSection => '글자';

  @override
  String get alphabetVowelsSection => '모음';

  @override
  String get alphabetVowelsIntro =>
      '모음은 글자 둘레에 적는 기호입니다. 여기서는 베트(ב) 위에 보여 줍니다.';

  @override
  String get alphabetFinalForm => '어말형';

  @override
  String get alphabetExampleLabel => '성경에서';

  @override
  String get wordConnections => '단어 연결선';

  @override
  String get wordConnectionsDesc =>
      '누른 단어가 나오는 다른 곳까지 선을 그립니다. 선이 읽고 있는 본문을 가로지르기 때문에 기본값은 꺼짐입니다.';

  @override
  String get memorizationSubtitle => '이미 편하게 읽는 본문에서 단어를 가려 보세요.';

  @override
  String get onboardingTraditionTitle => '어떤 경전을 읽으시나요?';

  @override
  String get onboardingTraditionDesc =>
      '책의 순서와 부르는 이름이 이에 따라 정해집니다. 어느 쪽을 골라도 감춰지는 내용은 없으며, 설정에서 바꿀 수 있습니다.';

  @override
  String get traditionChristian => '구약과 신약';

  @override
  String get traditionChristianDesc => '창세기부터 요한계시록까지, 기독교의 순서입니다.';

  @override
  String get traditionJewish => '타나크';

  @override
  String get traditionJewishDesc => '토라, 네비임, 케투빔을 유대 전통 순서로 봅니다.';

  @override
  String get tanakhTorah => '토라';

  @override
  String get tanakhNeviim => '네비임 — 예언서';

  @override
  String get tanakhKetuvim => '케투빔 — 성문서';

  @override
  String get hebrewBibleLabel => '히브리 성경';

  @override
  String get traditionSettingTitle => '경전';

  @override
  String get reviewReminderSetting => '매일 복습 알림';

  @override
  String get reviewReminderSettingSubtitle => '복습할 단어가 있을 때 저녁에 알려 드려요';

  @override
  String reminderDueTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '복습할 단어 $count개가 준비되었어요',
    );
    return '$_temp0';
  }

  @override
  String get reminderDueBody => '지금 5분이면 잊지 않아요.';

  @override
  String get reminderReadTitle => '오늘의 말씀이 기다리고 있어요';

  @override
  String get reminderReadBody => '오늘이 가기 전에 히브리어나 헬라어로 한 구절을 읽어 보세요.';

  @override
  String get pathTitle => '책별 학습';

  @override
  String get pathHomeStart => '책을 고르고 그 책에 필요한 단어만 배우세요';

  @override
  String get pathChooseBook => '원어로 읽을 책을 고르세요';

  @override
  String pathWordsToGoal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개 단어만 더 배우면 80% 읽기',
    );
    return '$_temp0';
  }

  @override
  String pathCoverage(int percent, String book) {
    return '$book의 $percent%를 읽을 수 있어요';
  }

  @override
  String pathLearning(int percent) {
    return '배우는 중인 단어까지 $percent%';
  }

  @override
  String get pathGoalReached => '이 책의 대부분을 읽을 수 있어요. 펼쳐서 읽어 보세요!';

  @override
  String get pathLearnNext => '다음 단어 배우기';

  @override
  String get pathWordsInBook => '이 책의 단어, 자주 나오는 순';

  @override
  String get pathChangeBook => '책 바꾸기';

  @override
  String get pathShare => '진도 공유하기';

  @override
  String shareCardHebrew(int percent, String book) {
    return '히브리어 $book의 단어 $percent%를 배웠어요';
  }

  @override
  String shareCardGreek(int percent, String book) {
    return '헬라어 $book의 단어 $percent%를 배웠어요';
  }

  @override
  String get shareCardFooter => 'Aleph로 배우는 중';

  @override
  String get pathAllLearned => '이 책의 모든 단어를 시작했어요. 계속 복습하세요!';

  @override
  String get dailySessionStart => '오늘의 5분';

  @override
  String get dailySessionDone => '오늘은 끝! 내일 만나요';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count일 연속',
    );
    return '$_temp0';
  }

  @override
  String get nameTitle => '내 이름은 무슨 뜻일까?';

  @override
  String get nameHint => '이름을 입력하세요';

  @override
  String nameMeans(String name, String meaning) {
    return '$name의 뜻은 “$meaning”';
  }

  @override
  String nameCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '성경에 $count번 나와요',
    );
    return '$_temp0';
  }

  @override
  String get nameNotFound => '아직 목록에 없는 이름이에요. 다른 표기로 찾아보세요.';

  @override
  String get nameShare => '공유';

  @override
  String get usageSharingTitle => '익명 사용 통계 보내기';

  @override
  String get usageSharingSubtitle =>
      '어떤 기능이 쓰이는지만 보냅니다. 읽는 내용이나 신원을 알 수 있는 정보는 절대 보내지 않아요.';

  @override
  String get supportTitle => 'Aleph 후원하기';

  @override
  String get supportBody =>
      'Aleph은 한 사람이 만듭니다. 광고도, 구독도, 추적도 없습니다. 한 번의 후원이 본문과 음성, 업데이트를 이어 갑니다.';

  @override
  String get supportNote => '후원은 아무것도 잠금 해제하지 않습니다. Aleph의 모든 문장은 이미 당신의 것입니다.';

  @override
  String get supportTierSmall => '작은 후원';

  @override
  String get supportTierMedium => '든든한 후원';

  @override
  String get supportTierLarge => '큰 후원';

  @override
  String get supportThanks => '감사합니다. 정말 큰 힘이 됩니다.';

  @override
  String get supportUnavailable => '지금은 후원할 수 없습니다.';

  @override
  String get supportClose => '나중에';

  @override
  String get supportTerms => '약관';

  @override
  String get supportPrivacy => '개인정보';
}
