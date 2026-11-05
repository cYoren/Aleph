import 'package:flutter/material.dart';
import '../../shared/utils/reading_tradition.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/generated/app_localizations.dart';
import '../explain/explain_provider.dart';
import '../../providers/word_provider.dart';
import '../../shared/widgets/tappable_word.dart';
import '../../shared/utils/vocabulary_filter.dart';
import '../settings/settings_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<_OnboardingPageData> _getPages(AppLocalizations l10n) {
    // Onboarding used stock Material accents (indigo, amber, teal, purple),
    // which read as a different app from the parchment-and-gold reader they
    // introduce. Everything here is drawn from the same palette instead.
    final scheme = Theme.of(context).colorScheme;

    return [
      _OnboardingPageData(
        icon: Icons.touch_app_outlined,
        title: l10n.onboardingTapTitle,
        description: l10n.onboardingTapDesc,
        color: scheme.primary,
        isWordPreview: true,
      ),
      _OnboardingPageData(
        icon: Icons.import_contacts_outlined,
        title: l10n.onboardingTraditionTitle,
        description: l10n.onboardingTraditionDesc,
        color: scheme.primary,
        isTraditionChoice: true,
      ),
      // Only offered when configured. New installs stay offline until the reader
      // explicitly enables the tutor after seeing what leaves the device.
      if (ref.read(explainConfiguredProvider))
        _OnboardingPageData(
          icon: Icons.auto_awesome_outlined,
          title: l10n.onboardingAiTitle,
          description: l10n.onboardingAiDesc,
          color: scheme.secondary,
          isAiConsent: true,
        ),
    ];
  }

  void _nextPage() {
    final pages = _getPages(AppLocalizations.of(context)!);
    if (_currentPage < pages.length - 1) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _pageController.jumpToPage(_currentPage + 1);
      } else {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      }
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    await ref.read(settingsProvider.notifier).completeOnboarding();
    if (mounted) context.go('/reading');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final pages = _getPages(l10n);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: Text(
                  l10n.skip,
                  style: TextStyle(color: colorScheme.primary),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: pages.length,
                itemBuilder: (context, index) =>
                    _OnboardingPage(data: pages[index]),
              ),
            ),

            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(pages.length, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? colorScheme.primary
                        : colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),

            const SizedBox(height: 24),

            // Next/Get Started button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560, minHeight: 56),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _nextPage,
                    child: Text(
                      _currentPage == pages.length - 1
                          ? l10n.getStarted
                          : l10n.next,
                      style: const TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class _OnboardingPageData {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final bool isWordPreview;

  /// When true the page shows the AI opt-in switch and its privacy note.
  final bool isAiConsent;

  /// Renders the Christian / Jewish chooser under the description.
  final bool isTraditionChoice;

  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    this.isWordPreview = false,
    this.isAiConsent = false,
    this.isTraditionChoice = false,
  });
}

class _OnboardingPage extends ConsumerWidget {
  final _OnboardingPageData data;

  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 512,
                minHeight: (constraints.maxHeight - 48).clamp(
                  0,
                  double.infinity,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: data.color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(data.icon, size: 30, color: data.color),
                  ),

                  const SizedBox(height: 24),

                  // Title
                  Text(
                    data.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // Description
                  Text.rich(
                    TextSpan(
                      children: [
                        for (final (index, part)
                            in data.description.split('✨').indexed) ...[
                          if (index > 0)
                            const WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Icon(
                                Icons.auto_awesome_outlined,
                                size: 18,
                              ),
                            ),
                          TextSpan(text: part),
                        ],
                      ],
                    ),
                    semanticsLabel: data.description.replaceAll(
                      '✨',
                      AppLocalizations.of(context)!.explainTitle,
                    ),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Which scriptures, and under which names. Neither answer hides any
                  // text; it decides the arrangement and the vocabulary the app uses
                  // when it talks about the books.
                  if (data.isTraditionChoice) ...[
                    const SizedBox(height: 28),
                    Consumer(
                      builder: (context, ref, _) {
                        final l10n = AppLocalizations.of(context)!;
                        final selected = ref.watch(
                          settingsProvider.select((s) => s.tradition),
                        );
                        return Column(
                          children: [
                            for (final option in ReadingTradition.values)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _TraditionOption(
                                  label: option == ReadingTradition.jewish
                                      ? l10n.traditionJewish
                                      : l10n.traditionChristian,
                                  description: option == ReadingTradition.jewish
                                      ? l10n.traditionJewishDesc
                                      : l10n.traditionChristianDesc,
                                  selected: selected == option,
                                  onTap: () => ref
                                      .read(settingsProvider.notifier)
                                      .setTradition(option),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],

                  // AI opt-in: preserve an existing choice; new installs default off.
                  // Skipping onboarding never grants consent.
                  if (data.isAiConsent) ...[
                    const SizedBox(height: 24),
                    Consumer(
                      builder: (context, ref, _) {
                        final l10n = AppLocalizations.of(context)!;
                        final enabled = ref.watch(
                          settingsProvider.select((s) => s.aiExplainEnabled),
                        );
                        return Column(
                          children: [
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                l10n.onboardingAiToggle,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              value: enabled,
                              onChanged: (value) => ref
                                  .read(settingsProvider.notifier)
                                  .setAiExplainEnabled(value),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.onboardingAiPrivacy,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],

                  if (data.isWordPreview) ...[
                    const SizedBox(height: 32),
                    const _FirstWordsPreview(),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Actual words from the bundled text, using the same lookup as the reader.
/// The first useful action happens here rather than after a feature tour.
class _FirstWordsPreview extends ConsumerWidget {
  const _FirstWordsPreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ref
          .watch(wordsForVerseProvider('GEN.1.1'))
          .when(
            loading: () => const SizedBox(
              height: 72,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => TextButton.icon(
              onPressed: () => ref.invalidate(wordsForVerseProvider('GEN.1.1')),
              icon: const Icon(Icons.refresh),
              label: Text(l10n.tryAgain),
            ),
            data: (words) => words.isEmpty
                ? Text(l10n.noResults)
                : Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    textDirection: TextDirection.rtl,
                    spacing: 8,
                    runSpacing: 12,
                    children: words
                        .where(
                          (word) => !isProcliticPrefix(
                            word.lemma ?? word.displayText,
                            isHebrew: true,
                          ),
                        )
                        .take(3)
                        .map(
                          (word) => TappableWord(
                            word: word,
                            isOT: true,
                            fontSize: 32,
                          ),
                        )
                        .toList(),
                  ),
          ),
    );
  }
}

/// One selectable tradition, styled as a card rather than a radio row so the
/// two options read as equals.
class _TraditionOption extends StatelessWidget {
  const _TraditionOption({
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? scheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? scheme.primary : scheme.outlineVariant,
                width: selected ? 1.4 : 0.8,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? scheme.onPrimaryContainer
                        : scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: selected
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
