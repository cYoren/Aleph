import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/data/models/real_syntax_node.dart';

void main() {
  const sample =
      '[{"c":"cl","u":"PP-V-S-O","k":['
      '{"r":"pp","c":"pp","k":[{"t":"בְּ","n":1,"c":"prep"},'
      '{"t":"רֵאשִׁית","n":1,"c":"noun"}]},'
      '{"t":"בָּרָא","n":2,"r":"v","c":"verb"}]}]';

  group('RealSyntaxNode', () {
    test('parses the compact trees JSON', () {
      final trees = RealSyntaxNode.parseTreesJson(sample);
      expect(trees.length, 1);
      final root = trees.first;
      expect(root.nodeClass, 'cl');
      expect(root.rule, 'PP-V-S-O');
      expect(root.children.length, 2);
      expect(root.isLeaf, isFalse);
    });

    test('leaves carry text, word number, and class', () {
      final root = RealSyntaxNode.parseTreesJson(sample).first;
      final pp = root.children.first;
      expect(pp.role, 'pp');
      expect(pp.isLeafGroup, isTrue);
      final leaf = pp.children.first;
      expect(leaf.isLeaf, isTrue);
      expect(leaf.text, 'בְּ');
      expect(leaf.wordNum, 1);
      expect(leaf.nodeClass, 'prep');
    });

    test('verb leaf keeps its role', () {
      final root = RealSyntaxNode.parseTreesJson(sample).first;
      final verb = root.children[1];
      expect(verb.role, 'v');
      expect(verb.isLeaf, isTrue);
    });

    test('malformed input yields empty list', () {
      expect(RealSyntaxNode.parseTreesJson('not json'), isEmpty);
      expect(RealSyntaxNode.parseTreesJson('{"t":"x"}'), isEmpty);
      expect(RealSyntaxNode.parseTreesJson('[]'), isEmpty);
    });
  });
}
