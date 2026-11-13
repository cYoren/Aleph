/// The syntax screen's two promises: tapping a word opens its dictionary entry,
/// and a long sentence can be folded away so the shape of the clause survives.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/data/models/real_syntax_node.dart';
import 'package:original_bible/features/reading/widgets/real_syntax_tree_view.dart';

const _sample =
    '[{"c":"cl","u":"V-S-O","k":['
    '{"t":"בָּרָא","n":1,"r":"v","c":"verb"},'
    '{"r":"s","c":"np","k":[{"r":"s","c":"np","k":['
    '{"t":"אֱלֹהִים","n":2,"c":"noun"}]}]}]}]';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));
}

void main() {
  testWidgets('tapping a word leaf reports the word, not the sentence', (
    tester,
  ) async {
    final trees = RealSyntaxNode.parseTreesJson(_sample);
    RealSyntaxNode? tapped;

    await tester.pumpWidget(
      _wrap(
        RealSyntaxTreeView(
          root: trees.first,
          isHebrew: true,
          onLeafTap: (leaf) => tapped = leaf,
        ),
      ),
    );

    await tester.tap(find.text('אֱלֹהִים'));
    await tester.pump();

    expect(tapped, isNotNull);
    expect(tapped!.text, 'אֱלֹהִים');
    expect(tapped!.wordNum, 2);
  });

  testWidgets('an internal node folds its children away and back', (
    tester,
  ) async {
    final trees = RealSyntaxNode.parseTreesJson(_sample);

    await tester.pumpWidget(
      _wrap(RealSyntaxTreeView(root: trees.first, isHebrew: true)),
    );

    expect(find.text('אֱלֹהִים'), findsOneWidget);

    // The subject phrase header is the first row carrying the "Subject" chip.
    await tester.tap(find.text('Subject').first);
    await tester.pumpAndSettle();
    expect(find.text('אֱלֹהִים'), findsNothing);

    await tester.tap(find.text('Subject').first);
    await tester.pumpAndSettle();
    expect(find.text('אֱלֹהִים'), findsOneWidget);
  });

  testWidgets('punctuation leaves are not tappable', (tester) async {
    final trees = RealSyntaxNode.parseTreesJson(
      '[{"c":"cl","k":[{"t":"׃","n":1,"c":"pc"}]}]',
    );
    var taps = 0;

    await tester.pumpWidget(
      _wrap(
        RealSyntaxTreeView(
          root: trees.first,
          isHebrew: true,
          onLeafTap: (_) => taps++,
        ),
      ),
    );

    await tester.tap(find.text('׃'));
    await tester.pump();

    expect(taps, 0);
  });
}
