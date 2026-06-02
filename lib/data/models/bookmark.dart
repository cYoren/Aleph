/// Bookmark model for saving favorite verses
class Bookmark {
  final int? id;
  final String verseId;
  final DateTime createdAt;
  final String? collectionName;

  Bookmark({
    this.id,
    required this.verseId,
    DateTime? createdAt,
    this.collectionName,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Bookmark.fromMap(Map<String, dynamic> map) {
    return Bookmark(
      id: map['id'] as int?,
      verseId: map['verse_id']?.toString() ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
          : DateTime.now(),
      collectionName: map['collection_name']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'verse_id': verseId,
      'created_at': createdAt.millisecondsSinceEpoch,
      'collection_name': collectionName,
    };
  }

  /// Parse verse ID to get book, chapter, verse number
  /// e.g., "GEN.1.5" -> ("GEN", 1, 5)
  (String bookId, int chapter, int verse) get parsed {
    final parts = verseId.split('.');
    return (
      parts.isNotEmpty ? parts[0] : '',
      parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
      parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0,
    );
  }

  String get bookId => parsed.$1;
  int get chapter => parsed.$2;
  int get verseNumber => parsed.$3;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Bookmark &&
          runtimeType == other.runtimeType &&
          verseId == other.verseId;

  @override
  int get hashCode => verseId.hashCode;
}
