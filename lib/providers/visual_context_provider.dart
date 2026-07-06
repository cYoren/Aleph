import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks the currently active Strong's number across the reading view.
/// Null means no word is actively selected for context highlighting.
final activeStrongsProvider = StateProvider<String?>((ref) => null);

/// Represents the global screen coordinates of a specific drawn word widget.
class WordCoordinates {
  final String wordId;
  final String lexiconKey;
  final GlobalKey widgetKey;

  WordCoordinates({
    required this.wordId,
    required this.lexiconKey,
    required this.widgetKey,
  });
}

/// A provider that holds the coordinates of all currently visible words
/// on the screen. The VisualContextPainter uses this to draw the curves.
class VisibleWordCoordinatesNotifier
    extends StateNotifier<Map<String, WordCoordinates>> {
  VisibleWordCoordinatesNotifier() : super({});

  void registerWord(String wordId, String lexiconKey, GlobalKey widgetKey) {
    // Word widgets (un)register via post-frame/microtask callbacks that can
    // fire after this notifier is disposed (e.g. leaving the reading screen).
    if (!mounted) return;
    state = {
      ...state,
      wordId: WordCoordinates(
        wordId: wordId,
        lexiconKey: lexiconKey,
        widgetKey: widgetKey,
      ),
    };
  }

  void unregisterWord(String wordId) {
    if (!mounted) return;
    if (state.containsKey(wordId)) {
      final newState = Map<String, WordCoordinates>.from(state);
      newState.remove(wordId);
      state = newState;
    }
  }
}

final visibleWordCoordinatesProvider =
    StateNotifierProvider<
      VisibleWordCoordinatesNotifier,
      Map<String, WordCoordinates>
    >((ref) {
      return VisibleWordCoordinatesNotifier();
    });
