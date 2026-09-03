import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../features/settings/settings_provider.dart';
import '../../providers/translations_provider.dart';
import '../../shared/utils/hebrew_display.dart';
import '../../shared/utils/reading_tradition.dart';
import '../audio/voice_setup.dart';
import 'package:go_router/go_router.dart';

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

/// The reader's settings, grouped by what they actually change.
///
/// The first section used to be headed "Theme" and contain ten rows —
/// typography, language, Hebrew display, phrase spacing, word connections and
/// the reading tradition among them. Tradition in particular renames and
/// reorders the entire canon, and it was filed under Theme. The groups here
/// are Reading, Learning, Audio, Appearance and About, in that order, because
/// that is roughly how often a reader touches them.
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
          // ---- Reading -------------------------------------------------
          _buildSectionHeader(l10n.readingSectionTitle, colorScheme),

          // First, because it renames and reorders everything else.
          ListTile(
            leading: const Icon(Icons.import_contacts_outlined),
            title: Text(l10n.traditionSettingTitle),
            subtitle: Text(l10n.traditionSettingDesc),
            trailing: DropdownButton<ReadingTradition>(
              value: settings.tradition,
              underline: const SizedBox.shrink(),
              onChanged: (value) {
                if (value != null) notifier.setTradition(value);
              },
              items: [
                DropdownMenuItem(
                  value: ReadingTradition.christian,
                  child: Text(l10n.traditionChristian),
                ),
                DropdownMenuItem(
                  value: ReadingTradition.jewish,
                  child: Text(l10n.traditionJewish),
                ),
              ],
            ),
          ),

          translationsAsync.when(
            loading: () => ListTile(
              leading: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              title: Text(l10n.loading),
            ),
            error: (err, stack) => ListTile(
              leading: Icon(Icons.error_outline, color: colorScheme.error),
              title: Text(l10n.translation),
              subtitle: Text(l10n.errorGenericBody),
            ),
            data: (translations) {
              final enabledTranslations = translations
                  .where((t) => t.enabled)
                  .toList();
              if (enabledTranslations.isEmpty) {
                return ListTile(
                  leading: Icon(
                    Icons.warning_amber_outlined,
                    color: colorScheme.tertiary,
                  ),
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
                  underline: const SizedBox.shrink(),
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

          // The slider sets the size of the scripture itself, so the row
          // shows it at that size rather than as a bare number.
          ListTile(
            leading: const Icon(Icons.format_size),
            title: Text(l10n.fontSize),
            subtitle: Text(
              l10n.fontSizeSample,
              style: TextStyle(fontSize: settings.fontSize),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Slider(
              value: settings.fontSize,
              min: 12,
              max: 32,
              divisions: 10,
              label: settings.fontSize.round().toString(),
              onChanged: notifier.setFontSize,
            ),
          ),

          SwitchListTile(
            secondary: const Icon(Icons.record_voice_over),
            title: Text(l10n.pronunciation),
            subtitle: Text(l10n.pronunciationDesc),
            value: settings.showPronunciation,
            onChanged: notifier.setShowPronunciation,
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
            onChanged: notifier.setShowSenseUnits,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.timeline),
            title: Text(l10n.wordConnections),
            subtitle: Text(l10n.wordConnectionsDesc),
            value: settings.showWordConnections,
            onChanged: notifier.setShowWordConnections,
          ),
          const Divider(),

          // ---- Learning ------------------------------------------------
          _buildSectionHeader(l10n.learningSectionTitle, colorScheme),
          SwitchListTile(
            secondary: const Icon(Icons.school_outlined),
            title: Text(l10n.learningMode),
            subtitle: Text(l10n.learningModeDesc),
            value: settings.learningModeEnabled,
            onChanged: notifier.setLearningMode,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.auto_stories_outlined),
            title: Text(l10n.readerMode),
            subtitle: Text(l10n.readerModeDesc),
            value: settings.readerModeEnabled,
            onChanged: notifier.setReaderMode,
          ),
          ListTile(
            leading: const Icon(Icons.abc_outlined),
            title: Text(l10n.alphabetTitle),
            subtitle: Text(l10n.alphabetLettersSection),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/alphabet'),
          ),

          // ---- Audio ---------------------------------------------------
          // Only where there is a screen to send the reader to. iOS ships and
          // downloads its own voices, so the row would be an offer the
          // platform cannot honour.
          if (canInstallVoices) ...[
            const Divider(),
            _buildSectionHeader(l10n.audioSectionTitle, colorScheme),
            ListTile(
              leading: const Icon(Icons.graphic_eq),
              title: Text(l10n.recitationVoiceTitle),
              subtitle: Text(l10n.recitationVoiceDesc),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () async {
                final opened = await openVoiceDownload();
                if (!opened && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.recitationVoiceUnavailable)),
                  );
                }
              },
            ),
          ],

          // Only shown when a key was compiled into this build; otherwise the
          // feature does not exist and the setting would be a dead switch.
          if (ref.watch(explainConfiguredProvider)) ...[
            const Divider(),
            _buildSectionHeader(l10n.explainSettingTitle, colorScheme),
            // The daily allowance lives on the switch itself. It used to sit on
            // a separate "upgrade" row whose toggle unlocked the paid tier for
            // free — a control that either lies about a purchase or gives the
            // paid model away. `aiProUnlocked` stays in state, waiting on a
            // real StoreKit / Play Billing entitlement to set it.
            Builder(
              builder: (context) {
                final remaining = ref.watch(explainRemainingTodayProvider);
                final subtitle = settings.aiExplainEnabled && remaining != null
                    ? l10n.explainFreeRemaining(remaining)
                    : l10n.explainSettingDesc;

                return SwitchListTile(
                  secondary: const Icon(Icons.auto_awesome_outlined),
                  title: Text(l10n.explainSettingTitle),
                  subtitle: Text(subtitle),
                  value: settings.aiExplainEnabled,
                  onChanged: notifier.setAiExplainEnabled,
                );
              },
            ),
            if (settings.aiExplainEnabled)
              ListTile(
                leading: const Icon(Icons.monitor_heart_outlined),
                title: Text(l10n.explainDiagnosticsTitle),
                subtitle: Text(l10n.explainDiagnosticsDesc),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/ai-diagnostics'),
              ),
          ],
          const Divider(),

          // ---- Appearance ----------------------------------------------
          _buildSectionHeader(l10n.appearanceSectionTitle, colorScheme),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(l10n.theme),
            trailing: DropdownButton<ThemeMode>(
              value: settings.themeMode,
              underline: const SizedBox.shrink(),
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
            leading: const Icon(Icons.language),
            title: Text(l10n.selectLanguage),
            trailing: DropdownButton<String>(
              value: _interfaceLanguages.containsKey(settings.appLanguage)
                  ? settings.appLanguage
                  : 'en',
              underline: const SizedBox.shrink(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  notifier.setAppLanguage(newValue);
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
          const Divider(),

          // ---- About ---------------------------------------------------
          _buildSectionHeader(l10n.aboutSectionTitle, colorScheme),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.aboutSourcesTitle),
            subtitle: Text(l10n.aboutSourcesDesc),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/about'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
          fontSize: 11,
          letterSpacing: 1.6,
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
