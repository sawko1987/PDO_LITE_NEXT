class ImportConflictDto {
  const ImportConflictDto({
    required this.rowNumber,
    required this.reason,
    this.candidates = const [],
  });

  factory ImportConflictDto.fromJson(Map<String, Object?> json) {
    final rawCandidates = json['candidates'] as List<Object?>? ?? const [];
    return ImportConflictDto(
      rowNumber: json['rowNumber'] as int? ?? 0,
      reason: json['reason'] as String? ?? '',
      candidates: rawCandidates
          .map((item) => item as String)
          .toList(growable: false),
    );
  }

  final int rowNumber;
  final String reason;
  final List<String> candidates;

  Map<String, Object?> toJson() => {
    'rowNumber': rowNumber,
    'reason': reason,
    'candidates': candidates,
  };
}
