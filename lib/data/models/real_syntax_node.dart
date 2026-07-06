import 'dart:convert';

/// A node of a real MACULA syntax tree (compact JSON from the build
/// pipeline: t=text, n=word number, r=role, c=class, u=rule, k=children).
class RealSyntaxNode {
  final String? text;
  final int? wordNum;
  final String? role;
  final String? nodeClass;
  final String? rule;
  final List<RealSyntaxNode> children;

  const RealSyntaxNode({
    this.text,
    this.wordNum,
    this.role,
    this.nodeClass,
    this.rule,
    this.children = const [],
  });

  bool get isLeaf => text != null;

  /// True when every child is a word/punctuation leaf, so the group can be
  /// rendered as a single text run.
  bool get isLeafGroup =>
      children.isNotEmpty && children.every((c) => c.isLeaf);

  factory RealSyntaxNode.fromJson(Map<String, dynamic> json) {
    final rawChildren = json['k'];
    return RealSyntaxNode(
      text: json['t']?.toString(),
      wordNum: (json['n'] as num?)?.toInt(),
      role: json['r']?.toString(),
      nodeClass: json['c']?.toString(),
      rule: json['u']?.toString(),
      children: rawChildren is List
          ? rawChildren
                .whereType<Map<String, dynamic>>()
                .map(RealSyntaxNode.fromJson)
                .toList()
          : const [],
    );
  }

  /// Parses the `trees` column: a JSON array of sentence trees.
  static List<RealSyntaxNode> parseTreesJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(RealSyntaxNode.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
