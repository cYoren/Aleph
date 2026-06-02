import 'word.dart';

/// Represents a single node in a morphology-driven syntax tree.
/// Each node corresponds to one [Word] from the original text,
/// annotated with a grammatical [role] label and a list of [children]
/// that depend on or modify it structurally.
class SyntaxNode {
  /// The original Word from the database.
  final Word word;

  /// Human-readable grammatical role, e.g. "Verb", "Subject", "Object",
  /// "Adjective", "Prepositional Phrase", "Conjunction", etc.
  final String role;

  /// Child nodes that grammatically depend on or modify this node.
  final List<SyntaxNode> children;

  const SyntaxNode({
    required this.word,
    required this.role,
    this.children = const [],
  });

  /// Returns true if this node has any children.
  bool get hasChildren => children.isNotEmpty;

  /// Depth-first traversal of this node and all its descendants.
  Iterable<SyntaxNode> get allNodes sync* {
    yield this;
    for (final child in children) {
      yield* child.allNodes;
    }
  }

  /// Creates a copy of this node with optional modifications.
  SyntaxNode copyWith({
    Word? word,
    String? role,
    List<SyntaxNode>? children,
  }) {
    return SyntaxNode(
      word: word ?? this.word,
      role: role ?? this.role,
      children: children ?? this.children,
    );
  }
}
