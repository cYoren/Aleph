import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/visual_context_provider.dart';
import '../../settings/settings_provider.dart';

class VisualContextOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const VisualContextOverlay({super.key, required this.child});

  @override
  ConsumerState<VisualContextOverlay> createState() =>
      _VisualContextOverlayState();
}

class _VisualContextOverlayState extends ConsumerState<VisualContextOverlay> {
  final GlobalKey _stackKey = GlobalKey();
  final ValueNotifier<int> _repaintTick = ValueNotifier<int>(0);

  @override
  void dispose() {
    _repaintTick.dispose();
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    _repaintTick.value = _repaintTick.value + 1;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Off by default. The connectors are drawn straight across the passage
    // being read, so they interrupt the very line the reader is on; tapping a
    // word still tints its other occurrences, which answers the same question
    // without drawing over the text.
    final showConnections = ref.watch(
      settingsProvider.select((s) => s.showWordConnections),
    );
    if (!showConnections) {
      return widget.child;
    }

    return Stack(
      key: _stackKey,
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: widget.child,
        ),
        // The overlay painter ignores pointer events, acting purely visually
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _VisualContextPainter(
                activeStrongs: ref.watch(activeStrongsProvider),
                wordCoordinates: ref.watch(visibleWordCoordinatesProvider),
                colorScheme: Theme.of(context).colorScheme,
                stackKey: _stackKey,
                repaintListenable: _repaintTick,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VisualContextPainter extends CustomPainter {
  final String? activeStrongs;
  final Map<String, WordCoordinates> wordCoordinates;
  final ColorScheme colorScheme;
  final GlobalKey stackKey;

  _VisualContextPainter({
    required this.activeStrongs,
    required this.wordCoordinates,
    required this.colorScheme,
    required this.stackKey,
    required Listenable repaintListenable,
  }) : super(repaint: repaintListenable);

  @override
  void paint(Canvas canvas, Size size) {
    if (activeStrongs == null || wordCoordinates.isEmpty) return;

    final stackRenderObject = stackKey.currentContext?.findRenderObject();
    if (stackRenderObject is! RenderBox) return;

    // Filter to only words that match the currently active lexicon key.
    final matchingAnchors = wordCoordinates.values.where(
      (WordCoordinates wc) => wc.lexiconKey == activeStrongs,
    );
    final matchingRects = <Rect>[];
    for (final anchor in matchingAnchors) {
      final renderObject = anchor.widgetKey.currentContext?.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.attached) continue;

      final localTopLeft = renderObject.localToGlobal(
        Offset.zero,
        ancestor: stackRenderObject,
      );
      matchingRects.add(localTopLeft & renderObject.size);
    }

    if (matchingRects.length < 2) return;

    final paint = Paint()
      ..color = colorScheme.secondary.withValues(alpha: 0.4)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Sort rects vertically so we draw from top to bottom
    matchingRects.sort((Rect a, Rect b) => a.top.compareTo(b.top));

    for (int i = 0; i < matchingRects.length - 1; i++) {
      final startRect = matchingRects[i];
      final endRect = matchingRects[i + 1];

      // Draw from the bottom center of the top word to the top center of the bottom word
      final startPoint = Offset(startRect.center.dx, startRect.bottom + 2);
      final endPoint = Offset(endRect.center.dx, endRect.top - 2);

      final path = Path();
      path.moveTo(startPoint.dx, startPoint.dy);

      // Create a smooth bezier curve between the two words
      final controlPoint1 = Offset(
        startPoint.dx,
        startPoint.dy + (endPoint.dy - startPoint.dy) / 2,
      );
      final controlPoint2 = Offset(
        endPoint.dx,
        startPoint.dy + (endPoint.dy - startPoint.dy) / 2,
      );

      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        endPoint.dx,
        endPoint.dy,
      );

      canvas.drawPath(path, paint);

      // Draw subtle dots at the connection points
      final dotPaint = Paint()
        ..color = colorScheme.secondary.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(startPoint, 3, dotPaint);
      canvas.drawCircle(endPoint, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _VisualContextPainter oldDelegate) {
    // Only repaint if the active word changed, or the scroll position/coordinates changed
    return activeStrongs != oldDelegate.activeStrongs ||
        wordCoordinates != oldDelegate.wordCoordinates ||
        stackKey != oldDelegate.stackKey;
  }
}
