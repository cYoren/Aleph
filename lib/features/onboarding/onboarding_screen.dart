import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/generated/app_localizations.dart';
import '../explain/explain_provider.dart';
import '../settings/settings_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<_OnboardingPageData> _getPages(AppLocalizations l10n) => [
    _OnboardingPageData(
      icon: Icons.menu_book,
      title: l10n.onboardingWelcomeTitle,
      description: l10n.onboardingWelcomeDesc,
      color: Colors.indigo,
    ),
    _OnboardingPageData(
      icon: Icons.format_textdirection_r_to_l,
      title: l10n.onboardingHebrewTitle,
      description: l10n.onboardingHebrewDesc,
      color: Colors.amber,
      exampleText: 'בְּרֵאשִׁית בָּרָא אֱלֹהִים',
      exampleTranslation: '"In the beginning God created..."',
      isRTL: true,
    ),
    _OnboardingPageData(
      icon: Icons.format_textdirection_l_to_r,
      title: l10n.onboardingGreekTitle,
      description: l10n.onboardingGreekDesc,
      color: Colors.blue,
      exampleText: 'Ἐν ἀρχῇ ἦν ὁ λόγος',
      exampleTranslation: '"In the beginning was the Word..."',
      isRTL: false,
    ),
    _OnboardingPageData(
      icon: Icons.touch_app,
      title: l10n.onboardingTapTitle,
      description: l10n.onboardingTapDesc,
      color: Colors.teal,
    ),
    _OnboardingPageData(
      icon: Icons.play_circle_outline,
      title: l10n.onboardingRecitationTitle,
      description: l10n.onboardingRecitationDesc,
      color: Colors.deepOrange,
    ),
    // Only offered when this build can actually do it. The switch defaults to
    // on, but the page states plainly what leaves the device, so the reader is
    // choosing rather than discovering it later.
    if (ref.read(explainConfiguredProvider))
      _OnboardingPageData(
        icon: Icons.auto_awesome_outlined,
        title: l10n.onboardingAiTitle,
        description: l10n.onboardingAiDesc,
        color: Colors.purple,
        isAiConsent: true,
      ),
  ];

  void _nextPage() {
    final pages = _getPages(AppLocalizations.of(context)!);
    if (_currentPage < pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() {
    ref.read(settingsProvider.notifier).completeOnboarding();
    context.go('/');
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
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _nextPage,
                  child: Text(
                    _currentPage == pages.length - 1
                        ? l10n.getStarted
                        : l10n.next,
                    style: const TextStyle(fontSize: 18),
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
  final String? exampleText;
  final String? exampleTranslation;
  final bool isRTL;

  /// When true the page shows the AI opt-in switch and its privacy note.
  final bool isAiConsent;

  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    this.exampleText,
    this.exampleTranslation,
    this.isRTL = false,
    this.isAiConsent = false,
  });
}

class _OnboardingPage extends ConsumerWidget {
  final _OnboardingPageData data;

  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, size: 50, color: data.color),
          ),

          const SizedBox(height: 32),

          // Title
          Text(
            data.title,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            data.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          // AI opt-in: the switch is on by default, but the note below it
          // says exactly what leaves the device, so the reader is making a
          // choice here rather than finding out later.
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
                        style: const TextStyle(fontWeight: FontWeight.w600),
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
                        fontSize: 11,
                        height: 1.4,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],

          // Example text (if provided)
          if (data.exampleText != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    data.exampleText!,
                    style: TextStyle(
                      fontFamily: data.isRTL ? 'EzraSIL' : null,
                      fontSize: 24,
                      color: colorScheme.onSurface,
                    ),
                    textDirection: data.isRTL
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    textAlign: TextAlign.center,
                  ),
                  if (data.exampleTranslation != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      data.exampleTranslation!,
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
