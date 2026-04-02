class IdempotencyCategoryStatDto {
  const IdempotencyCategoryStatDto({
    required this.category,
    required this.count,
  });

  factory IdempotencyCategoryStatDto.fromJson(Map<String, Object?> json) {
    return IdempotencyCategoryStatDto(
      category: json['category'] as String? ?? '',
      count: json['count'] as int? ?? 0,
    );
  }

  final String category;
  final int count;

  Map<String, Object?> toJson() => {'category': category, 'count': count};
}
