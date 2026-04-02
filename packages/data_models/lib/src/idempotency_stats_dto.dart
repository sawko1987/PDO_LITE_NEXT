import 'idempotency_category_stat_dto.dart';

class IdempotencyStatsDto {
  const IdempotencyStatsDto({
    required this.totalRecords,
    required this.byCategory,
  });

  factory IdempotencyStatsDto.fromJson(Map<String, Object?> json) {
    final rawItems = json['byCategory'] as List<Object?>? ?? const [];
    return IdempotencyStatsDto(
      totalRecords: json['totalRecords'] as int? ?? 0,
      byCategory: rawItems
          .map(
            (item) => IdempotencyCategoryStatDto.fromJson(
              (item as Map<Object?, Object?>).cast(),
            ),
          )
          .toList(growable: false),
    );
  }

  final int totalRecords;
  final List<IdempotencyCategoryStatDto> byCategory;

  Map<String, Object?> toJson() => {
    'totalRecords': totalRecords,
    'byCategory': byCategory
        .map((item) => item.toJson())
        .toList(growable: false),
  };
}
