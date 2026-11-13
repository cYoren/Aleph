/// "Other editions": where the Byzantine text or the Statistical Restoration
/// reads differently from the SBLGNT in this verse.
///
/// It is a text comparison, not a critical apparatus — no manuscripts, no
/// judgement about which reading is original — so it says which edition and
/// nothing more. It appears only where a difference exists, and stays on one
/// line until the reader asks for the readings: 57% of New Testament verses
/// differ from the Byzantine text somewhere, and a pane that opens itself in
/// every one of them is noise, not depth.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/textual_variant.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../providers/word_provider.dart';

class TextualVariantsPane extends ConsumerStatefulWidget {
  const TextualVariantsPane({
    super.key,
    required this.bookId,
    required this.chapter,
    required this.verse,
    required this.fontSize,
  });

  final String bookId;
  final int chapter;
  final int verse;
  final double fontSize;

  @override
  ConsumerState<TextualVariantsPane> createState() =>
      _TextualVariantsPaneState();
}

class _TextualVariantsPaneState extends ConsumerState<TextualVariantsPane> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final variants = ref
        .watch(
          textualVariantsProvider((
            widget.bookId,
            widget.chapter,
            widget.verse,
          )),
        )
        .valueOrNull;
    if (variants == null || variants.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final editions = variants.map((v) => v.edition).toSet().toList()..sort();

    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Row(
                children: [
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.otherEditions,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      editions.join(' · '),
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.75,
                        ),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            for (final variant in variants)
              _reading(context, variant, colorScheme, l10n),
        ],
      ),
    );
  }

  Widget _reading(
    BuildContext context,
    TextualVariant variant,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    final base = variant.baseReading.isEmpty
        ? l10n.otherEditionsOmitted
        : variant.baseReading;
    final other = variant.otherReading.isEmpty
        ? l10n.otherEditionsOmitted
        : variant.otherReading;

    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            variant.editionLabel,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 2),
          _line(context, 'SBLGNT', base, colorScheme, italic: false),
          _line(
            context,
            variant.edition,
            other,
            colorScheme,
            italic: variant.otherReading.isEmpty,
          ),
        ],
      ),
    );
  }

  Widget _line(
    BuildContext context,
    String label,
    String reading,
    ColorScheme colorScheme, {
    required bool italic,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 0.4,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
          ),
          Expanded(
            child: Text(
              reading,
              style: TextStyle(
                fontFamily: 'Gentium',
                fontSize: widget.fontSize - 4,
                fontStyle: italic ? FontStyle.italic : FontStyle.normal,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
