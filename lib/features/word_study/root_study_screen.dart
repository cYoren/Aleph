/// One root, every word built on it, and every verse those words appear in.
///
/// This is the difference between a concordance and a word study: אָבַד, אִבּוּד
/// and אֹבֵד are separate Strong's numbers, so searching one of them hides the
/// others. Searching the root shows the whole family at once.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/lexicon_root.dart';
import '../../data/models/verse.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/books_provider.dart';
import '../../providers/word_provider.dart';
import '../reading/reading_provider.dart';

class RootStudyScreen extends ConsumerWidget {
  const RootStudyScreen({
    super.key,
    required this.root,
    required this.gloss,
    required this.twot,
  });

  final String root;
  final String gloss;
  final String twot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final membersAsync = ref.watch(rootMembersProvider(twot));
    final occurrencesAsync = ref.watch(rootOccurrencesProvider(twot));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              root,
              style: const TextStyle(fontFamily: 'EzraSIL', fontSize: 24),
            ),
            Text(
              l10n.rootWordsTitle,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (gloss.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                gloss,
                style: TextStyle(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Text(
                  l10n.rootWordsTitle.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: colorScheme.primary,
                  ),
                ),
                const Spacer(),
                occurrencesAsync.when(
                  data: (data) => Text(
                    l10n.occurrencesTotal(data.total),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          ...membersAsync.when(
            data: (members) => members.map(
              (member) => _RootMemberTile(member: member),
            ),
            loading: () => const [
              Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (error, _) => [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('${l10n.error}: $error'),
              ),
            ],
          ),
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              l10n.verseLabel.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: colorScheme.primary,
              ),
            ),
          ),
          ...occurrencesAsync.when(
            data: (data) => [
              for (final verse in data.verses)
                _RootOccurrenceTile(verse: verse),
              if (data.total > data.verses.length)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.showingFirstOccurrences(data.verses.length),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
            loading: () => const [
              Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (error, _) => [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('${l10n.error}: $error'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RootMemberTile extends StatelessWidget {
  const _RootMemberTile({required this.member});

  final RootMember member;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(
        member.lemma.isEmpty ? member.strongsId : member.lemma,
        style: const TextStyle(fontSize: 20, fontFamily: 'EzraSIL'),
      ),
      subtitle: member.gloss.isEmpty
          ? null
          : Text(
              member.gloss,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
      trailing: Text(
        '${member.count}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colorScheme.primary,
        ),
      ),
      onTap: () => context.push(
        '/word-study',
        extra: {
          'lexiconKey': member.strongsId,
          'displayWord': member.lemma,
          'isHebrew': true,
        },
      ),
    );
  }
}

class _RootOccurrenceTile extends ConsumerWidget {
  const _RootOccurrenceTile({required this.verse});

  final Verse verse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final book = ref.watch(bookByAbbreviationProvider(verse.bookId));
    final reference =
        '${book?.name ?? verse.bookId} ${verse.chapter}:${verse.verseNumber}';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          reference,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
          ),
        ),
      ),
      subtitle: Text(
        verse.textContent,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontSize: 18,
          height: 1.6,
          fontFamily: 'EzraSIL',
          color: colorScheme.onSurface,
        ),
      ),
      onTap: () {
        ref
            .read(readingProvider.notifier)
            .loadChapter(verse.bookId, verse.chapter);
        context.go('/reading');
      },
    );
  }
}
