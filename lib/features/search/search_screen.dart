import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/database_provider.dart';
import '../../providers/books_provider.dart';
import '../../data/models/verse.dart';
import '../reading/reading_provider.dart';
import '../settings/settings_provider.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/loading_skeleton.dart';
import 'word_search_provider.dart';
import '../../providers/book_names_provider.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider.autoDispose<List<Verse>>((
  ref,
) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty || query.length < 3) return [];

  final dao = ref.watch(bibleDaoProvider);
  final selectedTranslation = ref.watch(
    settingsProvider.select((state) => state.translation),
  );
  return dao.search(query, translationId: selectedTranslation);
});

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
    ref.read(searchQueryProvider.notifier).state = '';
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

      // Navigate to reading view
      ref.read(readingProvider.notifier).loadChapter(bookId, chapter);
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
              autofocus: true,
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
          else if (query.length < 3)
            Expanded(
              child: Center(
                child: Text(
                  '${l10n.search}... (${3 - query.length})',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
            )
          else
            // Results
            Expanded(
              child: searchResults.when(
                data: (verses) {
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
                          l10n.verseResultsSection,
                          colorScheme,
                        ),
                        ...verses.map(
                          (verse) => _buildSearchResult(verse, colorScheme),
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
                  message: err.toString(),
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

  Widget _buildSearchResult(Verse verse, ColorScheme colorScheme) {
    // Get book name for display
    final booksAsync = ref.watch(booksProvider);
    final parts = verse.id.split('.');
    final bookAbbrev = parts.isNotEmpty ? parts[0] : '';
    final chapter = parts.length > 1 ? parts[1] : '';
    final verseNum = parts.length > 2 ? parts[2] : '';

    final bookName = ref
        .watch(bookNamesProvider)
        .nameFor(
          bookAbbrev,
          fallback: booksAsync.whenOrNull(
            data: (books) => books
                .where((b) => b.abbreviation == bookAbbrev)
                .firstOrNull
                ?.name,
          ),
        );

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
              // Content
              Text(
                verse.textContent,
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
