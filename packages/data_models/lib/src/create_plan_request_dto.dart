class CreatePlanRequestDto {
  const CreatePlanRequestDto({
    required this.requestId,
    required this.machineId,
    required this.versionId,
    required this.title,
    required this.items,
  });

  factory CreatePlanRequestDto.fromJson(Map<String, Object?> json) {
    final rawItems = json['items'] as List<Object?>? ?? const [];
    return CreatePlanRequestDto(
      requestId: json['requestId'] as String? ?? '',
      machineId: json['machineId'] as String? ?? '',
      versionId: json['versionId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      items: rawItems
          .map(
            (item) => CreatePlanItemRequestDto.fromJson(
              (item as Map<Object?, Object?>).cast(),
            ),
          )
          .toList(growable: false),
    );
  }

  final String requestId;
  final String machineId;
  final String versionId;
  final String title;
  final List<CreatePlanItemRequestDto> items;

  Map<String, Object?> toJson() => {
    'requestId': requestId,
    'machineId': machineId,
    'versionId': versionId,
    'title': title,
    'items': items.map((item) => item.toJson()).toList(growable: false),
  };
}

class CreatePlanItemRequestDto {
  const CreatePlanItemRequestDto({
    required this.structureOccurrenceId,
    required this.requestedQuantity,
  });

  factory CreatePlanItemRequestDto.fromJson(Map<String, Object?> json) {
    return CreatePlanItemRequestDto(
      structureOccurrenceId: json['structureOccurrenceId'] as String? ?? '',
      requestedQuantity: (json['requestedQuantity'] as num?)?.toDouble() ?? 0,
    );
  }

  final String structureOccurrenceId;
  final double requestedQuantity;

  Map<String, Object?> toJson() => {
    'structureOccurrenceId': structureOccurrenceId,
    'requestedQuantity': requestedQuantity,
  };
}
