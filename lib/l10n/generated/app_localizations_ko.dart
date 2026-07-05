// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '원문 성경';

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
      '단어를 누르면 정의, 발음, 문법 정보를 볼 수 있습니다. 발음 버튼을 켜면 단어 발음을 확인할 수 있습니다.';

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
  String get learningModeEnglishOnlyNotice => '학습 모드는 현재 영어 번역만 지원합니다.';

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
}
