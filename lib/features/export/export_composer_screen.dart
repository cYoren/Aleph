import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../../data/models/verse.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/word_provider.dart';

class ExportComposerScreen extends ConsumerStatefulWidget {
  final Verse verse;
  final String translationText;
  final String reference;
  final bool isOT;

  const ExportComposerScreen({
    super.key,
    required this.verse,
    required this.translationText,
    required this.reference,
    required this.isOT,
  });

  @override
  ConsumerState<ExportComposerScreen> createState() =>
      _ExportComposerScreenState();
}

class _ExportComposerScreenState extends ConsumerState<ExportComposerScreen> {
  final GlobalKey _globalKey = GlobalKey();
  bool _isExporting = false;

  // Customization state
  int _selectedBackgroundIndex = 0;
  bool _isSquare = true;

  final List<List<Color>> _backgroundGradients = [
    [
      const Color(0xFF1A1A24),
      const Color(0xFF0F0F14),
    ], // Dark minimal (subtle purple tint)
    [
      const Color(0xFF1B2E4B),
      const Color(0xFF0C1421),
    ], // Deep Blue to Black Space
    [const Color(0xFF511A9C), const Color(0xFF230647)], // Purple majesty deep
    [const Color(0xFFF0F2F5), const Color(0xFFDCDFE5)], // Holy White clean
    [const Color(0xFF751410), const Color(0xFF240201)], // Crimson blood dark
  ];

  Future<void> _exportAndShare() async {
    if (_isExporting) return;

    setState(() => _isExporting = true);

    try {
      // 1. Capture the exact pixels from the RepaintBoundary
      final boundary =
          _globalKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;

      // Render at a higher pixel ratio for crisp text
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // 2. Save it to a temporary file
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/verse_export.png');
      await file.writeAsBytes(pngBytes);

      // 3. Share it via system sheet
      await Share.shareXFiles([XFile(file.path)], text: widget.translationText);
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.failedToExportImage)));
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final wordsAsync = ref.watch(wordsForVerseProvider(widget.verse.id));
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(l10n.exportVerseTitle),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          _isExporting
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: _exportAndShare,
                  tooltip: l10n.shareImage,
                ),
        ],
      ),
      body: Column(
        children: [
          // The canvas area
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: _isSquare ? 1.0 : 9.0 / 16.0,
                child: RepaintBoundary(
                  key: _globalKey,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _backgroundGradients[_selectedBackgroundIndex],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Massive faint background watermark
                        Positioned(
                          top: -60,
                          left: -40,
                          child: Icon(
                            Icons.format_quote,
                            color: _selectedBackgroundIndex == 3
                                ? Colors.black.withValues(
                                    alpha: 0.03,
                                  ) // Dark text light bg
                                : Colors.white.withValues(
                                    alpha: 0.03,
                                  ), // Light text dark bg
                            size: 300,
                          ),
                        ),
                        // Content
                        Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Small quote icon (optional, could be removed now that we have the watermark, but let's keep it subtle)
                              Icon(
                                Icons.format_quote,
                                color: _selectedBackgroundIndex == 3
                                    ? Colors.black.withValues(alpha: 0.15)
                                    : Colors.white.withValues(alpha: 0.2),
                                size: 40,
                              ),
                              const SizedBox(height: 24),

                              // English Translation (Large Typography)
                              Text(
                                widget.translationText,
                                style: TextStyle(
                                  fontSize: _isSquare ? 24 : 28,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedBackgroundIndex == 3
                                      ? Colors.black.withValues(alpha: 0.85)
                                      : Colors.white.withValues(alpha: 0.95),
                                  height: 1.4,
                                  letterSpacing: 0.5,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.15,
                                      ),
                                      offset: const Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 32),

                              // Original Language Text (Subtle)
                              wordsAsync.when(
                                data: (words) {
                                  final text = words
                                      .map((w) => w.displayText)
                                      .join(' ');
                                  return Text(
                                    text,
                                    style: TextStyle(
                                      fontFamily: widget.isOT
                                          ? 'EzraSIL'
                                          : 'Gentium',
                                      fontSize: 18,
                                      color: _selectedBackgroundIndex == 3
                                          ? Colors.black.withValues(alpha: 0.6)
                                          : Colors.white.withValues(alpha: 0.7),
                                      height: 1.5,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.1,
                                          ),
                                          offset: const Offset(0, 1),
                                          blurRadius: 3,
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                    textDirection: widget.isOT
                                        ? TextDirection.rtl
                                        : TextDirection.ltr,
                                  );
                                },
                                loading: () => const SizedBox(),
                                error: (error, stackTrace) => const SizedBox(),
                              ),

                              const SizedBox(height: 32),

                              // Reference Footer
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _selectedBackgroundIndex == 3
                                          ? Colors.black.withValues(alpha: 0.1)
                                          : Colors.white.withValues(
                                              alpha: 0.15,
                                            ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      widget.reference.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _selectedBackgroundIndex == 3
                                            ? Colors.black87
                                            : Colors.white,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Controls Area with Glassmorphism
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.backgroundTheme,
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 50,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _backgroundGradients.length,
                          itemBuilder: (context, index) {
                            final isSelected =
                                _selectedBackgroundIndex == index;
                            return GestureDetector(
                              onTap: () => setState(
                                () => _selectedBackgroundIndex = index,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutCubic,
                                width: 50,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: _backgroundGradients[index],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.8)
                                        : Colors.white.withValues(alpha: 0.1),
                                    width: isSelected ? 3 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: _backgroundGradients[index]
                                                .first
                                                .withValues(alpha: 0.5),
                                            blurRadius: 12,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                      : [],
                                ),
                                transform: isSelected
                                    ? (Matrix4.identity()
                                        ..scaleByDouble(1.05, 1.05, 1.0, 1.0))
                                    : Matrix4.identity(),
                                transformAlignment: Alignment.center,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Text(
                            l10n.aspectRatio,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(
                                value: true,
                                label: Text('1:1'),
                                icon: Icon(Icons.crop_square),
                              ),
                              ButtonSegment(
                                value: false,
                                label: Text('9:16'),
                                icon: Icon(Icons.crop_portrait),
                              ),
                            ],
                            selected: {_isSquare},
                            onSelectionChanged: (Set<bool> newSelection) {
                              setState(() => _isSquare = newSelection.first);
                            },
                            style: ButtonStyle(
                              backgroundColor:
                                  WidgetStateProperty.resolveWith<Color>((
                                    Set<WidgetState> states,
                                  ) {
                                    if (states.contains(WidgetState.selected)) {
                                      return Colors.white24;
                                    }
                                    return Colors.transparent;
                                  }),
                              foregroundColor: WidgetStateProperty.all(
                                Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
