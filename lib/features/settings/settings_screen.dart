import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:original_bible/shared/constants/app_identity.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../features/settings/settings_provider.dart';
import '../../providers/translations_provider.dart';
import '../../shared/utils/hebrew_display.dart';
import '../explain/explain_provider.dart';

const _interfaceLanguages = <String, String>{
  'en': 'English',
  'pt': 'Português',
  'de': 'Deutsch',
  'fr': 'Français',
  'es': 'Español',
  'ru': 'Русский',
  'zh': '中文（简体）',
  'ko': '한국어',
};

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final translationsAsync = ref.watch(translationsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          // Appearance Section
          _buildSectionHeader(l10n.theme, colorScheme),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(l10n.theme),
            subtitle: Text(_themeName(settings.themeMode, l10n)),
            trailing: DropdownButton<ThemeMode>(
              value: settings.themeMode,
              onChanged: (ThemeMode? newValue) {
                if (newValue != null) {
                  notifier.setThemeMode(newValue);
                }
              },
              items: ThemeMode.values.map<DropdownMenuItem<ThemeMode>>((
                ThemeMode value,
              ) {
                return DropdownMenuItem<ThemeMode>(
                  value: value,
                  child: Text(_themeName(value, l10n)),
                );
              }).toList(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: Text(l10n.fontSize),
            subtitle: Text('${settings.fontSize.toInt()}'),
            trailing: SizedBox(
              width: 150,
              child: Slider(
                value: settings.fontSize,
                min: 12,
                max: 32,
                divisions: 10,
                label: settings.fontSize.round().toString(),
                onChanged: (double value) {
                  notifier.setFontSize(value);
                },
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.selectLanguage),
            subtitle: Text(
              _interfaceLanguages[settings.appLanguage] ??
                  _interfaceLanguages['en']!,
            ),
            trailing: DropdownButton<String>(
              value: _interfaceLanguages.containsKey(settings.appLanguage)
                  ? settings.appLanguage
                  : 'en',
              onChanged: (String? newValue) {
                if (newValue != null) {
                  notifier.setAppLanguageOnly(newValue);
                }
              },
              items: _interfaceLanguages.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.record_voice_over),
            title: Text(l10n.pronunciation),
            subtitle: Text(l10n.pronunciationDesc),
            value: settings.showPronunciation,
            onChanged: (bool value) {
              notifier.setShowPronunciation(value);
            },
          ),
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: Text(l10n.hebrewTextTitle),
            subtitle: Text(l10n.hebrewTextDesc),
            trailing: DropdownButton<HebrewTextDisplay>(
              value: settings.hebrewTextDisplay,
              underline: const SizedBox.shrink(),
              onChanged: (mode) {
                if (mode != null) {
                  notifier.setHebrewTextDisplay(mode);
                }
              },
              items: [
                DropdownMenuItem(
                  value: HebrewTextDisplay.full,
                  child: Text(l10n.hebrewTextFull),
                ),
                DropdownMenuItem(
                  value: HebrewTextDisplay.noCantillation,
                  child: Text(l10n.hebrewTextNoCantillation),
                ),
                DropdownMenuItem(
                  value: HebrewTextDisplay.consonantal,
                  child: Text(l10n.hebrewTextConsonantal),
                ),
              ],
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.format_align_right),
            title: Text(l10n.phraseSpacingTitle),
            subtitle: Text(l10n.phraseSpacingDesc),
            value: settings.showSenseUnits,
            onChanged: (bool value) {
              notifier.setShowSenseUnits(value);
            },
          ),
          ListTile(
            leading: const Icon(Icons.graphic_eq),
            title: Text(l10n.recitationVoiceTitle),
            subtitle: Text(l10n.recitationVoiceDesc),
          ),
          const Divider(),

          // Learning Section
          _buildSectionHeader(l10n.learningSectionTitle, colorScheme),
          SwitchListTile(
            secondary: const Icon(Icons.school_outlined),
            title: Text(l10n.learningMode),
            subtitle: Text(l10n.learningModeDesc),
            value: settings.learningModeEnabled,
            onChanged: (bool value) {
              notifier.setLearningMode(value);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.auto_stories_outlined),
            title: Text(l10n.readerMode),
            subtitle: Text(l10n.readerModeDesc),
            value: settings.readerModeEnabled,
            onChanged: (bool value) {
              notifier.setReaderMode(value);
            },
          ),
          // Only shown when a key was compiled into this build; otherwise the
          // feature does not exist and the setting would be a dead switch.
          if (ref.watch(explainConfiguredProvider)) ...[
            const Divider(),
            _buildSectionHeader(l10n.explainSettingTitle, colorScheme),
            SwitchListTile(
              secondary: const Icon(Icons.auto_awesome_outlined),
              title: Text(l10n.explainSettingTitle),
              subtitle: Text(l10n.explainSettingDesc),
              value: settings.aiExplainEnabled,
              onChanged: (bool value) {
                notifier.setAiExplainEnabled(value);
              },
            ),
          ],
          const Divider(),

          // Translation Section
          _buildSectionHeader(l10n.translation, colorScheme),
          translationsAsync.when(
            loading: () => ListTile(
              leading: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              title: Text(l10n.loading),
            ),
            error: (err, stack) => ListTile(
              leading: const Icon(Icons.error, color: Colors.red),
              title: Text(l10n.error),
              subtitle: Text('$err'),
            ),
            data: (translations) {
              final enabledTranslations = translations
                  .where((t) => t.enabled)
                  .toList();
              if (enabledTranslations.isEmpty) {
                return ListTile(
                  leading: const Icon(Icons.warning, color: Colors.orange),
                  title: Text(l10n.translationNotAvailable),
                );
              }
              final selectedTranslation = enabledTranslations
                  .where(
                    (t) =>
                        t.id.toLowerCase() ==
                        settings.translation.toLowerCase(),
                  )
                  .firstOrNull;
              return ListTile(
                leading: const Icon(Icons.translate),
                title: Text(l10n.translation),
                subtitle: Text(
                  selectedTranslation?.name ?? settings.translation,
                ),
                trailing: DropdownButton<String>(
                  value:
                      selectedTranslation?.id ?? enabledTranslations.first.id,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      notifier.setTranslation(newValue);
                    }
                  },
                  items: enabledTranslations.map<DropdownMenuItem<String>>((t) {
                    return DropdownMenuItem<String>(
                      value: t.id,
                      child: Text(t.abbreviation),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          const Divider(),

          // Responsible Entity Section
          _buildSectionHeader(l10n.appResponsible, colorScheme),
          ListTile(
            leading: const Icon(Icons.storefront_outlined),
            title: Text(l10n.tradeNameLabel),
            subtitle: const Text(AppIdentity.responsibleTradeName),
          ),
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: Text(l10n.cnpjLabel),
            subtitle: const Text(AppIdentity.responsibleCnpj),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  String _themeName(ThemeMode mode, AppLocalizations l10n) {
    switch (mode) {
      case ThemeMode.system:
        return l10n.themeSystem;
      case ThemeMode.light:
        return l10n.themeLight;
      case ThemeMode.dark:
        return l10n.themeDark;
    }
  }
}
