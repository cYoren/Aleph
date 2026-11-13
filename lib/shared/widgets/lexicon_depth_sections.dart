/// The depth panes of the definition sheet: numbered senses, the Hebrew root,
/// and the forms of the word that actually occur in the text.
///
/// Each of these reads one table and degrades to nothing when the database
/// predates it, so the sheet still shows the flattened dictionary entry on an
/// older install rather than an empty box.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/lexicon_sense.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/word_provider.dart';
import '../utils/paradigm.dart';

/// Section heading, styled like the rest of the sheet.
class DepthSectionLabel extends StatelessWidget {
  const DepthSectionLabel(this.label, {super.key, this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
            letterSpacing: 1,
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );
  }
}

/// Numbered senses from BDB / Abbott-Smith.
class SensesSection extends ConsumerStatefulWidget {
  const SensesSection({super.key, required this.lexiconKey});

  final String lexiconKey;

  @override
  ConsumerState<SensesSection> createState() => _SensesSectionState();
}

class _SensesSectionState extends ConsumerState<SensesSection> {
  static const _previewRows = 5;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final senses = ref.watch(lexiconSensesProvider(widget.lexiconKey));
    final rows = layoutSenses(senses.valueOrNull ?? const []);

    // No table, or an entry the dictionary left as prose: nothing to show, and
    // the sheet's existing paragraph already covers it.
    if (rows.isEmpty) return const SizedBox.shrink();

    final visible = _expanded ? rows : rows.take(_previewRows).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DepthSectionLabel(l10n.sensesLabel),
          const SizedBox(height: 8),
          for (final row in visible)
            Padding(
              padding: EdgeInsets.only(
                left: row.depth * 14.0,
                bottom: 6,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      row.marker,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(child: _senseBody(row, colorScheme)),
                ],
              ),
            ),
          if (rows.length > _previewRows)
            TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                _expanded
                    ? l10n.showLess
                    : l10n.showAllCount(rows.length),
                style: const TextStyle(fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Widget _senseBody(SenseRow row, ColorScheme colorScheme) {
    final heading = row.heading;
    final summary = row.summary;
    // When the dictionary wrote only prose for this node, the prose is the
    // sense; showing it twice would read like a stutter.
    final summaryIsRedundant =
        summary.isEmpty ||
        (heading.isNotEmpty && summary.startsWith(heading)) ||
        summary == heading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (heading.isNotEmpty)
          Text(
            heading,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.35,
              color: colorScheme.onSurface,
            ),
          ),
        if (!summaryIsRedundant)
          Padding(
            padding: EdgeInsets.only(top: heading.isEmpty ? 0 : 2),
            child: Text(
              summary,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

/// The Hebrew root behind this word, and the way into its root family.
class RootSection extends ConsumerWidget {
  const RootSection({
    super.key,
    required this.lexiconKey,
    required this.isHebrew,
  });

  final String lexiconKey;
  final bool isHebrew;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isHebrew) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final root = ref.watch(lexiconRootProvider(lexiconKey)).valueOrNull;
    if (root == null || root.root.isEmpty) return const SizedBox.shrink();

    final membersAsync = ref.watch(rootMembersProvider(root.twot));
    final members = membersAsync.valueOrNull ?? const [];
    final memberCount = members.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(
          '/root',
          extra: {
            'root': root.root,
            'gloss': root.gloss,
            'twot': root.twot,
          },
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outlineVariant, width: 0.8),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DepthSectionLabel(l10n.rootLabel),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        root.root,
                        style: const TextStyle(
                          fontSize: 24,
                          fontFamily: 'EzraSIL',
                        ),
                      ),
                      if (root.gloss.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Text(
                          root.gloss,
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const Spacer(),
              if (memberCount > 0)
                Text(
                  l10n.rootWordCount(memberCount),
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              Icon(Icons.chevron_right, color: colorScheme.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// The forms of this word that occur in the text, grouped as a paradigm is
/// read: Hebrew by binyan, Greek by tense and voice.
class AttestedFormsSection extends ConsumerStatefulWidget {
  const AttestedFormsSection({
    super.key,
    required this.lemma,
    required this.isHebrew,
  });

  final String lemma;
  final bool isHebrew;

  @override
  ConsumerState<AttestedFormsSection> createState() =>
      _AttestedFormsSectionState();
}

class _AttestedFormsSectionState extends ConsumerState<AttestedFormsSection> {
  static const _previewPerGroup = 6;
  static const _previewGroups = 4;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final groupsAsync = ref.watch(
      attestedFormsProvider((widget.lemma, widget.isHebrew)),
    );
    final groups = groupsAsync.valueOrNull ?? const <ParadigmGroup>[];
    if (groups.isEmpty) return const SizedBox.shrink();

    final visibleGroups = _expanded ? groups : groups.take(_previewGroups);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DepthSectionLabel(l10n.formsInTextLabel),
          const SizedBox(height: 4),
          Text(
            l10n.formsInTextNote,
            style: TextStyle(
              fontSize: 11.5,
              fontStyle: FontStyle.italic,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          for (final group in visibleGroups) ...[
            Row(
              children: [
                Text(
                  group.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${group.forms.length}',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final form in _formsFor(group))
                  Tooltip(
                    message: form.decoded(isHebrew: widget.isHebrew),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        form.form,
                        style: TextStyle(
                          fontSize: 17,
                          fontFamily: widget.isHebrew ? 'EzraSIL' : 'Gentium',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          if (groups.length > _previewGroups)
            TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                _expanded ? l10n.showLess : l10n.showAllCount(groups.length),
                style: const TextStyle(fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Iterable<AttestedForm> _formsFor(ParadigmGroup group) {
    if (_expanded) return group.forms;
    return group.forms.take(_previewPerGroup);
  }
}


/// Where the scroll and the reading tradition disagree about a word.
///
/// The written form (ketiv) and the reading (qere) are both shown, labelled,
/// with the reading's own dictionary form when it is a different word — the
/// one place where the reader can see that the text in front of them is a
/// decision the tradition made, not a transcription.
class QereKetivSection extends ConsumerWidget {
  const QereKetivSection({
    super.key,
    required this.qereText,
    required this.ketivText,
    required this.qereLemma,
    required this.isHebrew,
  });

  final String? qereText;
  final String? ketivText;
  final String? qereLemma;
  final bool isHebrew;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (qereText == null || ketivText == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final rows = <({String label, String text})>[
      (label: l10n.qereReadLabel, text: qereText!),
      (label: l10n.qereWrittenLabel, text: ketivText!),
      if (qereLemma != null)
        (label: l10n.qereLemmaLabel, text: qereLemma!),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DepthSectionLabel(l10n.qereTitle),
          const SizedBox(height: 8),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 104,
                    child: Text(
                      row.label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  Text(
                    row.text,
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: isHebrew ? 'EzraSIL' : 'Gentium',
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// "Who is he in this verse": the subject of a verb, or the word a pronoun
/// points back to, from MACULA's participant data.
class ParticipantSection extends ConsumerWidget {
  const ParticipantSection({
    super.key,
    required this.subjectText,
    required this.subjectStrongs,
    required this.referentText,
    required this.referentStrongs,
    required this.isHebrew,
  });

  final String? subjectText;
  final String? subjectStrongs;
  final String? referentText;
  final String? referentStrongs;
  final bool isHebrew;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final rows = <({String label, String text, String? strongs})>[
      if (referentText != null)
        (label: l10n.refersToLabel, text: referentText!, strongs: referentStrongs),
      if (subjectText != null)
        (label: l10n.subjectLabel, text: subjectText!, strongs: subjectStrongs),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 104,
                    child: Text(
                      row.label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  Text(
                    row.text,
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: isHebrew ? 'EzraSIL' : 'Gentium',
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (row.strongs != null)
                    Expanded(
                      child: Text(
                        ref
                                .watch(
                                  lexiconsForStrongsProvider(row.strongs!),
                                )
                                .valueOrNull?[row.strongs!]
                                ?.gloss ??
                            '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
