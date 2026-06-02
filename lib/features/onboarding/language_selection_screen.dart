import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/generated/app_localizations.dart';
import '../settings/settings_provider.dart';

class LanguageSelectionScreen extends ConsumerWidget {
  const LanguageSelectionScreen({super.key});

  static const languages = [
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧', 'translation': 'KJV'},
    {
      'code': 'pt',
      'name': 'Português',
      'flag': '🇧🇷',
      'translation': 'ALMEIDA',
    },
    {
      'code': 'de',
      'name': 'Deutsch',
      'flag': '🇩🇪',
      'translation': 'LUTHER1912',
    },
    {
      'code': 'fr',
      'name': 'Français',
      'flag': '🇫🇷',
      'translation': 'OSTERVALD',
    },
    {
      'code': 'es',
      'name': 'Español',
      'flag': '🇪🇸',
      'translation': 'VALERA1909',
    },
    {'code': 'ru', 'name': 'Русский', 'flag': '🇷🇺', 'translation': 'SYNODAL'},
    {'code': 'zh', 'name': '中文（简体）', 'flag': '🇨🇳', 'translation': 'CUVS'},
    {'code': 'ko', 'name': '한국어', 'flag': '🇰🇷', 'translation': 'KOREAN'},
  ];

  Future<void> _selectLanguage(
    BuildContext context,
    WidgetRef ref,
    String code,
  ) async {
    final notifier = ref.read(settingsProvider.notifier);
    await notifier.setAppLanguageOnly(code);
    await notifier.applyOnboardingLanguageDefault(code);
    if (context.mounted) {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const SizedBox(height: 48),

              // App icon/logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.menu_book,
                  size: 50,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),

              const SizedBox(height: 32),

              // Title
              Text(
                l10n.appTitle,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                l10n.selectLanguage,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 48),

              // Language buttons
              Expanded(
                child: ListView.separated(
                  itemCount: languages.length,
                  separatorBuilder: (context, index2) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final lang = languages[index];
                    return _LanguageButton(
                      code: lang['code']!,
                      name: lang['name']!,
                      flag: lang['flag']!,
                      translation: lang['translation']!,
                      onTap: () => _selectLanguage(context, ref, lang['code']!),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageButton extends StatelessWidget {
  final String code;
  final String name;
  final String flag;
  final String translation;
  final VoidCallback onTap;

  const _LanguageButton({
    required this.code,
    required this.name,
    required this.flag,
    required this.translation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Flag
              Text(flag, style: const TextStyle(fontSize: 32)),

              const SizedBox(width: 16),

              // Language name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      l10n.onboardingBibleLabel(translation),
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
