import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/syntax_node.dart';
import '../../../providers/word_provider.dart';
import '../../../shared/utils/morphology_decoder.dart';
import '../../../shared/widgets/definition_sheet.dart';
import '../../../providers/visual_context_provider.dart';

// ——————————————————————————————————————————————
// Layout constants
// ——————————————————————————————————————————————
const double _kNodeW = 110.0;
const double _kNodeH = 72.0;
const double _kHGap = 24.0; // horizontal gap between sibling nodes
const double _kVGap = 56.0; // vertical gap between tree levels

// ——————————————————————————————————————————————
// SyntaxTreeView
// ——————————————————————————————————————————————

class SyntaxTreeView extends ConsumerStatefulWidget {
  final SyntaxNode root;
  final bool isOT;

  const SyntaxTreeView({
    super.key,
    required this.root,
    required this.isOT,
  });

  @override
  ConsumerState<SyntaxTreeView> createState() => _SyntaxTreeViewState();
}

class _SyntaxTreeViewState extends ConsumerState<SyntaxTreeView> {
  /// Layout map: nodeId → (x, y) centre position
  final Map<int, Offset> _positions = {};

  @override
  Widget build(BuildContext context) {
    _positions.clear();

    // Measure layout in a first pass
    final totalWidth = _subtreeWidth(widget.root);
    final totalHeight = _subtreeHeight(widget.root);
    _layoutNode(widget.root, 0, 0);

    final colorScheme = Theme.of(context).colorScheme;

    return InteractiveViewer(
      constrained: false,
      boundaryMargin: const EdgeInsets.all(80),
      minScale: 0.4,
      maxScale: 2.5,
      child: SizedBox(
        width: totalWidth + _kNodeW,
        height: totalHeight + _kNodeH + 32,
        child: Stack(
          children: [
            // Draw the bezier branch lines
            Positioned.fill(
              child: CustomPaint(
                painter: _BranchPainter(
                  root: widget.root,
                  positions: _positions,
                  lineColor: colorScheme.outlineVariant,
                ),
              ),
            ),
            // Render each node
            ..._buildNodeWidgets(
              widget.root,
              colorScheme,
            ),
          ],
        ),
      ),
    );
  }

  // ——————————————————————————————————————————————
  // Layout helpers
  // ——————————————————————————————————————————————

  double _subtreeWidth(SyntaxNode node) {
    if (node.children.isEmpty) return _kNodeW;
    final childrenWidth = node.children
        .fold(0.0, (sum, c) => sum + _subtreeWidth(c) + _kHGap);
    return childrenWidth - _kHGap; // no trailing gap
  }

  double _subtreeHeight(SyntaxNode node) {
    if (node.children.isEmpty) return _kNodeH;
    final maxChildH = node.children
        .fold(0.0, (max, c) => _subtreeHeight(c) > max ? _subtreeHeight(c) : max);
    return _kNodeH + _kVGap + maxChildH;
  }

  void _layoutNode(SyntaxNode node, double x, double y) {
    if (node.children.isEmpty) {
      _positions[node.word.id] = Offset(x + _kNodeW / 2, y + _kNodeH / 2);
      return;
    }

    // Position root at the horizontal centre of all children
    final childrenTotalWidth = node.children.fold(
      0.0,
      (sum, c) => sum + _subtreeWidth(c) + _kHGap,
    ) - _kHGap;

    final rootCentreX = x + childrenTotalWidth / 2;
    _positions[node.word.id] = Offset(rootCentreX, y + _kNodeH / 2);

    // Layout each child
    double childX = x;
    for (final child in node.children) {
      _layoutNode(child, childX, y + _kNodeH + _kVGap);
      childX += _subtreeWidth(child) + _kHGap;
    }
  }

  // ——————————————————————————————————————————————
  // Node widget builder
  // ——————————————————————————————————————————————

  List<Widget> _buildNodeWidgets(SyntaxNode node, ColorScheme colorScheme) {
    final widgets = <Widget>[];

    final pos = _positions[node.word.id];
    if (pos != null) {
      widgets.add(_buildNodeWidget(node, pos, colorScheme));
    }

    for (final child in node.children) {
      widgets.addAll(_buildNodeWidgets(child, colorScheme));
    }
    return widgets;
  }

  Widget _buildNodeWidget(
    SyntaxNode node,
    Offset centre,
    ColorScheme colorScheme,
  ) {
    final morphCode = node.word.morphCode ?? '';
    final posColor = Color(
      MorphologyDecoder.getPartOfSpeechColor(morphCode, isHebrew: widget.isOT),
    );

    final fontFamily = widget.isOT ? 'EzraSIL' : 'Gentium';

    return Positioned(
      left: centre.dx - _kNodeW / 2,
      top: centre.dy - _kNodeH / 2,
      width: _kNodeW,
      height: _kNodeH,
      child: GestureDetector(
        onTap: () {
          ref.read(selectedWordProvider.notifier).state = node.word;
          if (node.word.strongs?.isNotEmpty == true) {
            ref.read(activeStrongsProvider.notifier).state = node.word.strongs;
          }
          DefinitionSheet.show(context);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: posColor.withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: posColor.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Original language word
              Text(
                node.word.displayText,
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: posColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              // Role label pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: posColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  node.role,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: posColor,
                    letterSpacing: 0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ——————————————————————————————————————————————
// CustomPainter for bezier branch lines
// ——————————————————————————————————————————————

class _BranchPainter extends CustomPainter {
  final SyntaxNode root;
  final Map<int, Offset> positions;
  final Color lineColor;

  const _BranchPainter({
    required this.root,
    required this.positions,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    _drawBranches(canvas, root, paint);
  }

  void _drawBranches(Canvas canvas, SyntaxNode node, Paint paint) {
    final parentPos = positions[node.word.id];
    if (parentPos == null) return;

    for (final child in node.children) {
      final childPos = positions[child.word.id];
      if (childPos != null) {
        // Bezier curve from bottom-centre of parent to top-centre of child
        final start = Offset(parentPos.dx, parentPos.dy + _kNodeH / 2);
        final end = Offset(childPos.dx, childPos.dy - _kNodeH / 2);
        final cp1 = Offset(start.dx, start.dy + _kVGap * 0.5);
        final cp2 = Offset(end.dx, end.dy - _kVGap * 0.5);

        final path = Path()
          ..moveTo(start.dx, start.dy)
          ..cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, end.dx, end.dy);
        canvas.drawPath(path, paint);
      }
      _drawBranches(canvas, child, paint);
    }
  }

  @override
  bool shouldRepaint(_BranchPainter old) =>
      old.root != root || old.positions != positions;
}
