import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/lexicon_entry.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/database_provider.dart';
import '../../shared/widgets/share_card_dialog.dart';
import 'bible_names.dart';
import '../../shared/utils/readable_width.dart';

class NameMeaningScreen extends ConsumerStatefulWidget {
  const NameMeaningScreen({super.key});

  @override
  ConsumerState<NameMeaningScreen> createState() => _NameMeaningScreenState();
}

class _NameMeaningScreenState extends ConsumerState<NameMeaningScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final namesAsync = ref.watch(bibleNamesProvider);
    final loaded = namesAsync.hasValue;
    final all = namesAsync.valueOrNull ?? const [];
    final matches = matchNames(all, _query);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.nameTitle)),
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: readableGutter(context),
          vertical: 16,
        ),
        children: [
          TextField(
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: l10n.nameHint,
              prefixIcon: const Icon(Icons.person_outline),
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 16),
          // Only once the list has loaded: while it loads, a fast typist would
          // otherwise be told their name is missing.
          if (loaded && _query.trim().length >= 2 && matches.isEmpty)
            Text(l10n.nameNotFound),
          for (final entry in matches)
            _NameCard(entry: entry, typed: _displayName(_query, entry)),
        ],
      ),
    );
  }

  /// The reader's own spelling when it matches exactly, else the entry's
  /// spelling that their prefix led to.
  String _displayName(String query, BibleName entry) {
    final typed = query.trim();
    final exact = entry.names.where(
      (n) => n.toLowerCase() == typed.toLowerCase(),
    );
    if (exact.isNotEmpty) return exact.first;
    return entry.names.firstWhere(
      (n) => n.toLowerCase().startsWith(typed.toLowerCase()),
      orElse: () => entry.names.first,
    );
  }
}

/// Lexicon row and occurrence count for one name.
final _nameDetailsProvider =
    FutureProvider.family<(LexiconEntry?, int), String>((ref, strongs) async {
      final dao = ref.watch(bibleDaoProvider);
      final entries = await dao.getLexiconEntriesForStrongs([strongs]);
      final counts = await dao.getFrequenciesForLexiconKeys([strongs]);
      return (entries[strongs], counts[strongs] ?? 0);
    });

class _NameCard extends ConsumerWidget {
  const _NameCard({required this.entry, required this.typed});

  final BibleName entry;
  final String typed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final language = Localizations.localeOf(context).languageCode;
    final details = ref.watch(_nameDetailsProvider(entry.strongs)).valueOrNull;
    final lexicon = details?.$1;
    final count = details?.$2 ?? 0;
    final meaning = l10n.nameMeans(typed, entry.meaningIn(language));
    final original = lexicon?.lemma ?? '';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              original,
              style: TextStyle(
                fontSize: 44,
                fontFamily: entry.isHebrew ? 'EzraSIL' : 'Gentium',
                color: colorScheme.primary,
              ),
            ),
            if ((lexicon?.transliteration ?? '').isNotEmpty)
              Text(
                lexicon!.transliteration!,
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              entry.isHebrew ? l10n.hebrewLabel : l10n.greekLabel,
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 1,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              meaning,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (entry.showCount && count > 0) ...[
              const SizedBox(height: 6),
              Text(
                l10n.nameCount(count),
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.ios_share),
              label: Text(l10n.nameShare),
              onPressed: original.isEmpty
                  ? null
                  : () => ShareCardDialog.show(
                      context,
                      glyph: original,
                      isHebrew: entry.isHebrew,
                      headline: typed,
                      line: meaning,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
