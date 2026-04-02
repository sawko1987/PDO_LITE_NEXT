class ApiListResponseDto<T> {
  const ApiListResponseDto({
    required this.items,
    this.meta = const <String, Object?>{},
    this.total,
  });

  factory ApiListResponseDto.fromJson(
    Map<String, Object?> json,
    T Function(Map<String, Object?> item) decodeItem,
  ) {
    final rawItems = json['items'] as List<Object?>? ?? const [];
    final rawMeta = json['meta'] as Map<Object?, Object?>? ?? const {};

    return ApiListResponseDto(
      items: rawItems
          .map((item) => decodeItem((item as Map<Object?, Object?>).cast()))
          .toList(growable: false),
      meta: rawMeta.cast(),
      total: json['total'] as int?,
    );
  }

  final List<T> items;
  final Map<String, Object?> meta;
  final int? total;

  Map<String, Object?> toJson(
    Map<String, Object?> Function(T item) encodeItem,
  ) => {
    'items': items.map(encodeItem).toList(growable: false),
    'count': items.length,
    if (total != null) 'total': total,
    'meta': meta,
  };
}
