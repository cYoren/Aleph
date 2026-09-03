import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/database_provider.dart';
import '../../data/database/daos/bible_dao.dart';
import '../../data/models/verse.dart';
import '../reading/reading_provider.dart';
import '../settings/settings_provider.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/loading_skeleton.dart';
import 'word_search_provider.dart';
import '../../providers/book_names_provider.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

/// Kept alive rather than auto-disposed: the search tab is a [ShellRoute]
/// child, so tapping a result and coming back rebuilt this from scratch and
/// the reader lost the results they had just navigated from.
final searchResultsProvider = FutureProvider<SearchResults>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty || query.length < kMinSearchLength) {
    return SearchResults.empty;
  }

  final dao = ref.watch(bibleDaoProvider);
  final selectedTranslation = ref.watch(
    settingsProvider.select((state) => state.translation),
  );
  return dao.search(query, translationId: selectedTranslation);
});

/// Shortest query worth running. Below this every chapter matches.
const int kMinSearchLength = 3;

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(searchQueryProvider);
    _searchController.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onControllerChanged);
    _searchController.dispose();
    // The query deliberately survives this screen. Clearing it here meant
    // opening a result and coming back to an empty field and no results.
    super.dispose();
  }

  void _onSearchChanged(String value) {
    final trimmed = value.trim();
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(searchQueryProvider.notifier).state = trimmed;
    });
  }

  void _navigateToVerse(Verse verse) {
    // Parse verse.id (e.g., "GEN.1.5") to get book and chapter
    final parts = verse.id.split('.');
    if (parts.length >= 2) {
      final bookId = parts[0];
      final chapter = int.tryParse(parts[1]) ?? 1;

      final verseNumber = parts.length > 2 ? int.tryParse(parts[2]) : null;
      ref
          .read(readingProvider.notifier)
          .loadChapter(
            bookId,
            chapter,
            targetVerse: verseNumber,
            recordHistory: true,
          );
      context.go('/reading');
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchResultsProvider);
    final query = ref.watch(searchQueryProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.search)),
      body: Column(
        children: [
          // Search input
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              // Only when there is nothing to come back to. Focusing on every
              // visit threw the keyboard over results the reader had just
              // returned to read.
              autofocus: _searchController.text.isEmpty,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _debounce?.cancel();
                          _searchController.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // Instructions when empty. This screen searches the Bible text; the
          // dictionary hits underneath are a bonus. Saying so plainly is the
          // whole fix — readers were opening it expecting a word lookup and
          // never discovering it finds verses.
          if (query.isEmpty)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.menu_book_outlined,
                        size: 56,
                        color: colorScheme.primary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.searchEmptyTitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.searchEmptyBody,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          height: 1.5,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (query.length < kMinSearchLength)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    l10n.searchKeepTyping(kMinSearchLength),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
            )
          else
            // Results
            Expanded(
              child: searchResults.when(
                data: (results) {
                  final verses = results.verses;
                  final wordResults =
                      ref.watch(wordSearchResultsProvider).valueOrNull ??
                      const <WordSearchResult>[];
                  if (verses.isEmpty && wordResults.isEmpty) {
                    return NoSearchResultsState(query: query);
                  }
                  // Verses first, always. Leading with dictionary entries made
                  // the screen read as a lexicon that happened to list some
                  // verses underneath.
                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      if (verses.isNotEmpty) ...[
                        _buildSectionLabel(
                          // The cap has to be visible, or a truncated list
                          // reads as the whole answer.
                          results.isTruncated
                              ? l10n.verseResultsShowing(
                                  verses.length,
                                  results.totalMatches,
                                )
                              : l10n.verseResultsSection,
                          colorScheme,
                        ),
                        ...verses.map(
                          (verse) =>
                              _buildSearchResult(verse, colorScheme, query),
                        ),
                      ],
                      if (wordResults.isNotEmpty) ...[
                        _buildSectionLabel(
                          l10n.wordResultsSection,
                          colorScheme,
                        ),
                        ...wordResults.map(
                          (word) => _buildWordResult(word, colorScheme),
                        ),
                      ],
                    ],
                  );
                },
                loading: () => ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 5,
                  itemBuilder: (context, index) => const SearchResultSkeleton(),
                ),
                error: (err, stack) => ErrorState(
                  message: l10n.searchFailedBody,
                  onRetry: () => ref.invalidate(searchResultsProvider),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String title, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildWordResult(WordSearchResult word, ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () {
          context.push(
            '/word-study',
            extra: {
              'lexiconKey': word.lexiconKey,
              'displayWord': word.lemma,
              'isHebrew': word.isHebrew,
            },
          );
        },
        leading: Icon(Icons.translate, color: colorScheme.primary),
        title: Row(
          children: [
            Text(
              word.lemma,
              style: TextStyle(
                fontSize: 20,
                fontFamily: word.isHebrew ? 'EzraSIL' : 'Gentium',
                color: colorScheme.onSurface,
              ),
            ),
            if (word.transliteration != null &&
                word.transliteration!.isNotEmpty) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  word.transliteration!,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: word.gloss != null && word.gloss!.isNotEmpty
            ? Text(word.gloss!, maxLines: 1, overflow: TextOverflow.ellipsis)
            : null,
        trailing: word.strongsId.isNotEmpty
            ? Text(
                word.strongsId,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            : null,
      ),
    );
  }

  /// Splits [text] so the matched run can be emphasised.
  ///
  /// A result list that does not show what matched makes the reader re-read
  /// every line to find out why it is there.
  List<TextSpan> _highlight(String text, String query, ColorScheme scheme) {
    if (query.isEmpty) return [TextSpan(text: text)];

    final haystack = text.toLowerCase();
    final needle = query.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;

    while (true) {
      final index = haystack.indexOf(needle, start);
      if (index < 0) break;
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      spans.add(
        TextSpan(
          text: text.substring(index, index + needle.length),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            backgroundColor: scheme.primaryContainer,
            color: scheme.onPrimaryContainer,
          ),
        ),
      );
      start = index + needle.length;
    }

    if (start < text.length) spans.add(TextSpan(text: text.substring(start)));
    return spans.isEmpty ? [TextSpan(text: text)] : spans;
  }

  Widget _buildSearchResult(
    Verse verse,
    ColorScheme colorScheme,
    String query,
  ) {
    final parts = verse.id.split('.');
    final bookAbbrev = parts.isNotEmpty ? parts[0] : '';
    final chapter = parts.length > 1 ? parts[1] : '';
    final verseNum = parts.length > 2 ? parts[2] : '';

    // The reader's language, not the database's English column.
    final bookName = ref.watch(localizedBookNameProvider(bookAbbrev));

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToVerse(verse),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reference
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$bookName $chapter:$verseNum',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Content, with the matched run marked
              Text.rich(
                TextSpan(
                  children: _highlight(verse.textContent, query, colorScheme),
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
