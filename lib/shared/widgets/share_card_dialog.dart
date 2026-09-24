import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/generated/app_localizations.dart';

/// A share card rendered to an image: a word or letter in the original script,
/// a big headline, one line of text and the app's name, on the brand gradient.
class ShareCardDialog extends StatefulWidget {
  const ShareCardDialog({
    super.key,
    required this.glyph,
    required this.isHebrew,
    required this.headline,
    required this.line,
  });

  final String glyph;
  final bool isHebrew;
  final String headline;
  final String line;

  static Future<void> show(
    BuildContext context, {
    required String glyph,
    required bool isHebrew,
    required String headline,
    required String line,
  }) {
    return showDialog(
      context: context,
      builder: (_) => ShareCardDialog(
        glyph: glyph,
        isHebrew: isHebrew,
        headline: headline,
        line: line,
      ),
    );
  }

  @override
  State<ShareCardDialog> createState() => _ShareCardDialogState();
}

class _ShareCardDialogState extends State<ShareCardDialog> {
  final _key = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final boundary =
          _key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('${(await getTemporaryDirectory()).path}/aleph.png');
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      await Share.shareXFiles([XFile(file.path)], text: widget.line);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // A single letter can be huge; a whole name has to fit the card.
    final glyphSize = widget.glyph.characters.length <= 1 ? 72.0 : 52.0;

    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RepaintBoundary(
            key: _key,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF3B1F0E), Color(0xFF9C4A12)],
                ),
              ),
              child: Column(
                children: [
                  Text(
                    widget.glyph,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: glyphSize,
                      height: 1.2,
                      color: const Color(0xFFF3D9A4),
                      fontFamily: widget.isHebrew ? 'EzraSIL' : 'Gentium',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.headline,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.line,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      height: 1.35,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.shareCardFooter,
                    style: const TextStyle(
                      fontSize: 13,
                      letterSpacing: 1.2,
                      color: Color(0xFFF3D9A4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.icon(
              icon: const Icon(Icons.ios_share),
              label: Text(l10n.pathShare),
              onPressed: _sharing ? null : _share,
            ),
          ),
        ],
      ),
    );
  }
}
