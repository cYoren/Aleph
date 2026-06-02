class Translation {
  final String id; // "kjv", "acf", etc.
  final String name; // "King James Version"
  final String language; // "en", "pt"
  final String abbreviation; // "KJV", "ACF"
  final bool enabled;
  final double coveragePercent;

  Translation({
    required this.id,
    required this.name,
    required this.language,
    required this.abbreviation,
    this.enabled = true,
    this.coveragePercent = 0,
  });

  factory Translation.fromMap(Map<String, dynamic> map) {
    final id = map['id']?.toString() ?? '';
    final enabledRaw = map['enabled'];
    final enabled = enabledRaw is int
        ? enabledRaw != 0
        : enabledRaw is bool
        ? enabledRaw
        : true;
    final coverageRaw = map['coverage_percent'];
    final coveragePercent = coverageRaw is num
        ? coverageRaw.toDouble()
        : double.tryParse(coverageRaw?.toString() ?? '0') ?? 0;

    return Translation(
      id: id,
      name: map['name']?.toString() ?? '',
      language: map['language']?.toString() ?? '',
      abbreviation: map['abbreviation']?.toString() ?? id.toUpperCase(),
      enabled: enabled,
      coveragePercent: coveragePercent,
    );
  }
}
