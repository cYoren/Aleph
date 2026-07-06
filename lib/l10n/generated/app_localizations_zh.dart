// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '原文圣经';

  @override
  String get continueReading => '继续阅读';

  @override
  String get selectLanguage => '选择你的语言';

  @override
  String get next => '下一步';

  @override
  String get getStarted => '开始';

  @override
  String get skip => '跳过';

  @override
  String get onboardingWelcomeTitle => '欢迎';

  @override
  String get onboardingWelcomeDesc => '以原始语言和对照译本阅读圣经。';

  @override
  String get onboardingHebrewTitle => '希伯来文 - 旧约';

  @override
  String get onboardingHebrewDesc =>
      '旧约写于希伯来文，阅读方向为从右到左。这些文本写成于两千五百多年前，包含律法书、诗篇和先知书。';

  @override
  String get onboardingGreekTitle => '希腊文 - 新约';

  @override
  String get onboardingGreekDesc => '新约写于希腊文，阅读方向为从左到右。福音书与书信写于公元 50-100 年间。';

  @override
  String get onboardingTapTitle => '点按任意词语';

  @override
  String get onboardingTapDesc => '点按任意词语即可查看释义、发音和语法信息。开启发音按钮可查看词语读音。';

  @override
  String get settings => '设置';

  @override
  String get translation => '译本';

  @override
  String get pronunciation => '显示发音';

  @override
  String get pronunciationDesc => '在词语上方显示音译';

  @override
  String get fontSize => '字体大小';

  @override
  String get theme => '主题';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get search => '搜索';

  @override
  String get searchHint => '在圣经文本中搜索...';

  @override
  String get noResults => '未找到结果';

  @override
  String get verseOfDay => '每日经文';

  @override
  String get quickAccess => '快捷入口';

  @override
  String get home => '首页';

  @override
  String get books => '书卷';

  @override
  String get oldTestament => '旧约';

  @override
  String get newTestament => '新约';

  @override
  String get selectChapter => '选择章节';

  @override
  String chapters(int count) {
    return '$count 章';
  }

  @override
  String get translationNotAvailable => '译文不可用';

  @override
  String get noLexiconEntry => '暂无词典条目';

  @override
  String get copyVerse => '复制经文';

  @override
  String get shareVerse => '分享经文';

  @override
  String get verseCopied => '经文已复制到剪贴板';

  @override
  String get addBookmark => '添加书签';

  @override
  String get removeBookmark => '移除书签';

  @override
  String get bookmarks => '书签';

  @override
  String get noBookmarks => '还没有书签';

  @override
  String get noBookmarksDesc => '长按经文并点按书签图标可保存到这里。';

  @override
  String get removeBookmarkConfirmation => '要移除此书签吗？';

  @override
  String bookmarkTimeYearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# 年前',
      one: '# 年前',
    );
    return '$_temp0';
  }

  @override
  String bookmarkTimeMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# 个月前',
      one: '# 个月前',
    );
    return '$_temp0';
  }

  @override
  String bookmarkTimeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# 天前',
      one: '# 天前',
    );
    return '$_temp0';
  }

  @override
  String bookmarkTimeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# 小时前',
      one: '# 小时前',
    );
    return '$_temp0';
  }

  @override
  String bookmarkTimeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# 分钟前',
      one: '# 分钟前',
    );
    return '$_temp0';
  }

  @override
  String get bookmarkTimeJustNow => '刚刚';

  @override
  String get quickMeaning => '快速释义';

  @override
  String get fullDefinition => '完整释义';

  @override
  String get pronunciationLabel => '发音';

  @override
  String get hebrewOT => '希伯来文 • 旧约';

  @override
  String get greekNT => '希腊文 • 新约';

  @override
  String get appResponsible => '应用责任主体';

  @override
  String get legalNameLabel => '法定名称';

  @override
  String get tradeNameLabel => '商号';

  @override
  String get cnpjLabel => 'CNPJ';

  @override
  String get tryAgain => '重试';

  @override
  String get somethingWentWrong => '出现错误';

  @override
  String get error => '错误';

  @override
  String get learningMode => '学习模式';

  @override
  String get learningModeDesc => '通过在阅读中看到原文来被动学习。';

  @override
  String get learningModeEnglishOnlyNotice => '学习模式目前仅支持英文译本。';

  @override
  String get learningSectionTitle => '学习';

  @override
  String get loading => '加载中...';

  @override
  String onboardingBibleLabel(String translation) {
    return '圣经：$translation';
  }

  @override
  String get syntaxTreeTitle => '句法树';

  @override
  String get viewSyntaxTree => '查看句法树';

  @override
  String get hebrewLabel => '希伯来文';

  @override
  String get greekLabel => '希腊文';

  @override
  String get syntaxTreeTapHint => '点按任意词节点可查看完整释义';

  @override
  String get noMorphologicalData => '该节暂无形态学数据。';

  @override
  String get posVerb => '动词';

  @override
  String get posNoun => '名词';

  @override
  String get posAdjectiveShort => '形.';

  @override
  String get posPronoun => '代词';

  @override
  String get posPrepositionShort => '介.';

  @override
  String get posConjunctionShort => '连.';

  @override
  String strongsHebrewLabel(String number) {
    return '希伯来文 $number';
  }

  @override
  String strongsGreekLabel(String number) {
    return '希腊文 $number';
  }

  @override
  String get lemmaDictionaryForm => '词元（词典形式）';

  @override
  String get grammar => '语法';

  @override
  String get topUsageByBook => '按书卷统计高频用法';

  @override
  String get failedToLoadFrequencyData => '频次数据加载失败。';

  @override
  String get noUsageDataAvailable => '暂无用法数据。';

  @override
  String get previousChapter => '上一章';

  @override
  String get nextChapter => '下一章';

  @override
  String get createCinematicImage => '创建电影风图片';

  @override
  String get srsQuestionPrompt => '这个词在此处是什么意思？';

  @override
  String get revealAnswer => '显示答案';

  @override
  String get didntKnow => '不知道';

  @override
  String get knewIt => '我知道';

  @override
  String get srsPositiveFeedback => '很好！该词记忆已提升。';

  @override
  String get srsNegativeFeedback => '继续练习。我们会更频繁地展示这个词。';

  @override
  String get exportVerseTitle => '导出经文';

  @override
  String get shareImage => '分享图片';

  @override
  String get backgroundTheme => '背景主题';

  @override
  String get aspectRatio => '宽高比';

  @override
  String get failedToExportImage => '导出图片失败。';

  @override
  String get exportUnavailableTitle => '导出不可用';

  @override
  String get missingExportRouteData => '导出所需路由数据缺失。';

  @override
  String get invalidExportRouteData => '导出所需路由数据无效。';

  @override
  String get syntaxTreeUnavailableTitle => '句法树不可用';

  @override
  String get missingSyntaxTreeRouteData => '句法树所需路由数据缺失。';

  @override
  String get invalidSyntaxTreeRouteData => '句法树所需路由数据无效。';

  @override
  String get noStrongsAvailable => '无 Strong 编号';

  @override
  String get wordStudyTitle => '词语研读';

  @override
  String get seeAllUses => '查看所有出现位置';

  @override
  String occurrencesTotal(int count) {
    return '在圣经中出现 $count 次';
  }

  @override
  String showingFirstOccurrences(int shown) {
    return '仅显示前 $shown 次出现';
  }

  @override
  String get wordStudyUnavailableTitle => '词语研读不可用';

  @override
  String get missingWordStudyRouteData => '未提供该页面所需的词语数据。';

  @override
  String get syntaxTreeHeuristicNotice => '基于词序启发式规则的语法示意图，并非经过校验的句法数据。';

  @override
  String get readerMode => '读者模式';

  @override
  String get readerModeDesc => '阅读时在罕见词语下方显示简短翻译。已掌握的词语不再显示提示。';

  @override
  String get vocabularyTitle => '词汇';

  @override
  String get dueForReviewSection => '待复习';

  @override
  String get mostFrequentSection => '最常见词语';

  @override
  String vocabularyCoverage(String percent) {
    return '这些词语覆盖了 $percent% 的经文——请优先学习。';
  }

  @override
  String get hebrewTextTitle => '希伯来文显示';

  @override
  String get hebrewTextDesc => '以更少的符号阅读是学习的里程碑';

  @override
  String get hebrewTextFull => '完整（含音调符号）';

  @override
  String get hebrewTextNoCantillation => '仅元音符号';

  @override
  String get hebrewTextConsonantal => '仅辅音';

  @override
  String get memorizationTitle => '背诵';

  @override
  String get memorizationEmpty => '这里还没有内容。添加一篇诗篇，开始隐藏词语吧。';

  @override
  String get addPassageTitle => '添加段落';

  @override
  String get addPassageButton => '添加';

  @override
  String get selectBookLabel => '书卷';

  @override
  String get selectChapterLabel => '章';

  @override
  String masteryLabel(String percent) {
    return '掌握度 $percent%';
  }

  @override
  String get dueNowLabel => '待复习';

  @override
  String get deletePassageTooltip => '移除段落';

  @override
  String get levelWarmUp => '热身';

  @override
  String get levelChallenge => '挑战';

  @override
  String get levelFirstLetters => '首字母';

  @override
  String get tapHiddenWordHint => '点击隐藏的词语即可显示';

  @override
  String get howDidItGo => '感觉如何？';

  @override
  String get struggledButton => '有困难';

  @override
  String get gotItButton => '记住了';

  @override
  String nextReviewInDays(int count) {
    return '已保存！$count 天后复习。';
  }

  @override
  String nextReviewInHours(int count) {
    return '已保存！$count 小时后复习。';
  }

  @override
  String get missingMemorizationRouteData => '未提供该页面所需的段落数据。';

  @override
  String get wordResultsSection => '词语';

  @override
  String get verseResultsSection => '经文';

  @override
  String get crossReferencesTitle => '串珠经文';

  @override
  String get noCrossReferences => '本节经文没有串珠参考。';

  @override
  String get parsingQuizTitle => '词形练习';

  @override
  String get whatFormIsThis => '这是什么词形？';

  @override
  String get nextQuestion => '下一题';

  @override
  String quizScore(int score, int total) {
    return '答对 $score / $total';
  }

  @override
  String get practiceAgain => '再练一次';

  @override
  String get doneButton => '完成';
}
