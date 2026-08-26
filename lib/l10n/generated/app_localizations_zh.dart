// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Aleph';

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
  String get onboardingTapDesc => '点按任意词语即可查看释义、发音和语法信息。长按词语可快速查看含义，而不会失去阅读位置。';

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

  @override
  String get syntaxSourceMacula => '句法树：MACULA 希伯来文与希腊文（Clear Bible），CC BY 4.0';

  @override
  String get showMore => '显示更多';

  @override
  String get showLess => '收起';

  @override
  String get readabilityTitle => '我能读哪些书卷？';

  @override
  String get readabilityAllBooks => '全部书卷，按易读程度排列';

  @override
  String get readabilityNoText => '尚未加载经文。';

  @override
  String get readabilityCanReadNow => '你现在就能读这卷';

  @override
  String get readabilityClosest => '最接近可以读的一卷';

  @override
  String get readabilityEmptyTitle => '开始学习单词，这张图就会逐渐填满';

  @override
  String get readabilityEmptyBody =>
      '随着你掌握的词汇增加，每卷书都会显示你已经能读懂多少。最常见的词覆盖了大部分经文，所以起步阶段进展很快。';

  @override
  String get openVocabulary => '打开词汇';

  @override
  String get reciteAloud => '朗读';

  @override
  String get stopReciting => '停止朗读';

  @override
  String get recitationPreparing => '准备中…';

  @override
  String get recitationStop => '停止';

  @override
  String get hearItRead => '听朗读';

  @override
  String get phraseSpacingTitle => '按语义分组';

  @override
  String get phraseSpacingDesc => '依照马所拉重音在希伯来文中加入间隔，使经文以语义单位阅读，而不是逐字阅读。';

  @override
  String get recitationVoiceTitle => '朗读语音';

  @override
  String get recitationVoiceDesc =>
      '使用设备的语音朗读：希伯来文为现代以色列发音，希腊文为现代希腊发音。这是沿用至今的诵读传统，并非重建的古代发音。';

  @override
  String get voiceMissing => '朗读需要设备安装希伯来语或希腊语语音。安装只需片刻，且只需一次。';

  @override
  String get voiceUnsupported => '本设备没有可用的语音引擎。';

  @override
  String get voiceInstall => '安装语音';

  @override
  String get voiceInstallUnavailable => '此设备没有可打开的语音安装程序。';

  @override
  String get recitationFailed => '无法开始朗读。';

  @override
  String readBook(String book) {
    return '阅读$book';
  }

  @override
  String readabilityCoverage(int percent, int count) {
    return '你认识其中 $percent% 的词汇——每章约有 $count 个生词。';
  }

  @override
  String recitationVerse(int number) {
    return '第 $number 节';
  }

  @override
  String voiceMissingFor(String tradition) {
    return '本设备未安装$tradition语音。';
  }

  @override
  String crossReferencesCount(int count) {
    return '$count 处交叉引用';
  }

  @override
  String get onboardingRecitationTitle => '聆听朗读';

  @override
  String get onboardingRecitationDesc =>
      '点按播放键，即可听到任意一章用希伯来语或希腊语朗读——使用的是现代通行的发音，而非重建的古代发音。可将语速调慢，直到耳朵跟得上为止。';

  @override
  String get readingHintTitle => '三种入门方式';

  @override
  String get readingHintBody => '点按词语可查看完整释义。长按可快速预览而不失去阅读位置。点按上方的 ▶ 即可听到本章朗读。';

  @override
  String get readingHintDismiss => '知道了';

  @override
  String get explainTitle => '解释这段经文';

  @override
  String get explainLoading => '正在阅读经文…';

  @override
  String get explainDisclaimer => '由 AI 生成，可能有误，请对照原文核查。';

  @override
  String get explainSettingTitle => 'AI 经文解释';

  @override
  String get explainSettingDesc =>
      '默认关闭。开启后，你正在阅读的经文会通过网络发送以获取解释。本应用的其他功能均可完全离线使用。';

  @override
  String get explainErrorOffline => '无网络连接。这是唯一需要联网的功能。';

  @override
  String get explainErrorRateLimited => '当前请求过多，请稍后再试。';

  @override
  String get explainErrorGeneric => '无法生成解释。';

  @override
  String get explainRetry => '重试';

  @override
  String get explainLowQuality => '这条回答看起来有问题。请重试——如果持续出现，可能需要更换模型。';

  @override
  String explainFreeRemaining(int count) {
    return '今日还剩 $count 次免费解释';
  }

  @override
  String get explainLimitReached => '你已用完今天的免费解释次数。';

  @override
  String get explainUpgradeTitle => '无限次数，且模型更强';

  @override
  String get explainDiagnosticsTitle => 'AI 诊断';

  @override
  String get explainDiagnosticsDesc => '回答你问题的模型的成功率与速度。若回答质量下降，可在此查看。';

  @override
  String get explainNoData => '尚未请求过解释。';

  @override
  String get explainClearDiagnostics => '清除记录';

  @override
  String get onboardingAiTitle => '随时提问任何经文';

  @override
  String get onboardingAiDesc =>
      '为你的疑问而设的导师：希伯来文究竟说了什么，希腊文承载了译文无法传达的哪些含义。点按任意经文旁的 ✨。';

  @override
  String get onboardingAiToggle => '启用 AI 导师';

  @override
  String get onboardingAiPrivacy =>
      '这是本应用唯一联网的部分：你所提问的经文会被发送以获取解释。其余一切——经文、词典、语法、音频——均可完全离线使用。你可以随时在设置中更改。';

  @override
  String get reciteFromHere => '从这里开始诵读';

  @override
  String get searchEmptyTitle => '搜索圣经';

  @override
  String get searchEmptyBody => '输入经文中的任意词语即可找到该节。希伯来语和希腊语词典条目显示在经文下方。';

  @override
  String get alphabetTitle => '字母表';

  @override
  String get alphabetHebrewIntro =>
      '希伯来文从右向左读。共有二十二个字母，全部是辅音——写在字母上下的点和短横才是元音。一次学一个字母，不必着急。';

  @override
  String get alphabetGreekIntro =>
      '希腊文从左向右读，有大写和小写两种形式。与希伯来文不同，它的元音本身就是字母。一次学一个字母，不必着急。';

  @override
  String get alphabetLettersSection => '字母';

  @override
  String get alphabetVowelsSection => '元音';

  @override
  String get alphabetVowelsIntro => '元音是写在字母周围的符号。这里以字母 bet（ב）为例。';

  @override
  String get alphabetFinalForm => '词尾形';

  @override
  String get alphabetExampleLabel => '圣经中的例词';

  @override
  String get wordConnections => '词语连线';

  @override
  String get wordConnectionsDesc => '在你点击的词与它的其他出处之间画线。默认关闭，因为连线会穿过正在阅读的经文。';

  @override
  String get memorizationSubtitle => '在你已经读得顺畅的段落里遮住词语。';

  @override
  String get onboardingTraditionTitle => '你读的是哪一部经典？';

  @override
  String get onboardingTraditionDesc =>
      '这决定书卷的排列顺序和称呼方式。两种选择都不会隐藏任何内容，你也可以在设置中更改。';

  @override
  String get traditionChristian => '旧约与新约';

  @override
  String get traditionChristianDesc => '基督教的排列顺序，从创世记到启示录。';

  @override
  String get traditionJewish => '塔纳赫';

  @override
  String get traditionJewishDesc => '妥拉、先知书与文集，按犹太传统顺序排列。';

  @override
  String get tanakhTorah => '妥拉';

  @override
  String get tanakhNeviim => '先知书';

  @override
  String get tanakhKetuvim => '文集';

  @override
  String get hebrewBibleLabel => '希伯来圣经';

  @override
  String get traditionSettingTitle => '经典';
}
