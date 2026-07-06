import 'package:flutter/material.dart';

import '../../../data/models/real_syntax_node.dart';

/// English display labels for MACULA role codes.
const Map<String, String> kRoleLabels = {
  's': 'Subject',
  'o': 'Object',
  'o2': 'Second object',
  'io': 'Indirect object',
  'v': 'Verb',
  'vc': 'Copula',
  'p': 'Predicate',
  'adv': 'Adverbial',
  'aj': 'Adjectival',
  'pp': 'Prepositional',
  'cj': 'Conjunction',
  'det': 'Determiner',
  'apposition': 'Apposition',
  'vocative': 'Vocative',
};

/// English display labels for MACULA phrase/clause classes.
const Map<String, String> kClassLabels = {
  'cl': 'Clause',
  'np': 'Noun phrase',
  'pp': 'Prep. phrase',
  'vp': 'Verb phrase',
  'adjp': 'Adj. phrase',
  'advp': 'Adv. phrase',
  'nump': 'Numeral phrase',
  'intjp': 'Interjection',
  'pc': 'Punctuation',
};

/// Renders one MACULA sentence tree as an indented outline. Groups whose
/// children are all words collapse into a single RTL/LTR text run so short
/// phrases stay readable on one line.
class RealSyntaxTreeView extends StatelessWidget {
  final RealSyntaxNode root;
  final bool isHebrew;
  final double fontSize;

  const RealSyntaxTreeView({
    super.key,
    required this.root,
    required this.isHebrew,
    this.fontSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _buildNode(root, colorScheme, depth: 0);
  }

  Widget _buildNode(
    RealSyntaxNode node,
    ColorScheme colorScheme, {
    required int depth,
  }) {
    if (node.isLeaf) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: _labeledRow(node, _leafText(node, colorScheme), colorScheme),
      );
    }

    if (node.isLeafGroup) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: _labeledRow(
          node,
          Wrap(
            spacing: 6,
            textDirection: isHebrew ? TextDirection.rtl : TextDirection.ltr,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: node.children
                .map((leaf) => _leafText(leaf, colorScheme))
                .toList(),
          ),
          colorScheme,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (node.role != null || node.nodeClass != null || node.rule != null)
            _headerChips(node, colorScheme),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: colorScheme.outlineVariant,
                    width: 1.5,
                  ),
                ),
              ),
              padding: const EdgeInsets.only(left: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: node.children
                    .map(
                      (child) =>
                          _buildNode(child, colorScheme, depth: depth + 1),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _labeledRow(
    RealSyntaxNode node,
    Widget content,
    ColorScheme colorScheme,
  ) {
    final label = _roleLabel(node);
    if (label == null) return content;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _chip(label, colorScheme.primary, colorScheme),
        const SizedBox(width: 8),
        Flexible(child: content),
      ],
    );
  }

  Widget _headerChips(RealSyntaxNode node, ColorScheme colorScheme) {
    final chips = <Widget>[];
    final role = _roleLabel(node);
    if (role != null) {
      chips.add(_chip(role, colorScheme.primary, colorScheme));
    }
    if (node.nodeClass != null) {
      chips.add(
        _chip(
          kClassLabels[node.nodeClass] ?? node.nodeClass!,
          colorScheme.tertiary,
          colorScheme,
        ),
      );
    }
    if (node.rule != null) {
      chips.add(
        Text(
          node.rule!,
          style: TextStyle(
            fontSize: 10,
            fontFamily: 'monospace',
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Wrap(
        spacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: chips,
      ),
    );
  }

  String? _roleLabel(RealSyntaxNode node) {
    final role = node.role;
    if (role == null) return null;
    return kRoleLabels[role] ?? role;
  }

  Widget _chip(String label, Color color, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _leafText(RealSyntaxNode leaf, ColorScheme colorScheme) {
    final isPunctuation = leaf.nodeClass == 'pc';
    return Text(
      leaf.text ?? '',
      textDirection: isHebrew ? TextDirection.rtl : TextDirection.ltr,
      style: TextStyle(
        fontFamily: isHebrew ? 'EzraSIL' : 'Gentium',
        fontSize: fontSize,
        color: isPunctuation
            ? colorScheme.onSurfaceVariant
            : colorScheme.onSurface,
      ),
    );
  }
}
