import 'package:domain/domain.dart';

class PlanDetailItemDto {
  const PlanDetailItemDto({
    required this.id,
    required this.structureOccurrenceId,
    required this.catalogItemId,
    required this.displayName,
    required this.pathKey,
    required this.requestedQuantity,
    required this.hasRecordedExecution,
    required this.canEdit,
    this.workshop,
  });

  factory PlanDetailItemDto.fromDomain(
    PlanItem item, {
    required StructureOccurrence occurrence,
    required bool canEdit,
  }) {
    return PlanDetailItemDto(
      id: item.id,
      structureOccurrenceId: item.structureOccurrenceId,
      catalogItemId: item.source.catalogItemId,
      displayName: occurrence.displayName,
      pathKey: occurrence.pathKey,
      requestedQuantity: item.requestedQuantity,
      hasRecordedExecution: item.hasRecordedExecution,
      canEdit: canEdit,
      workshop: occurrence.workshop,
    );
  }

  factory PlanDetailItemDto.fromJson(Map<String, Object?> json) {
    return PlanDetailItemDto(
      id: json['id'] as String? ?? '',
      structureOccurrenceId: json['structureOccurrenceId'] as String? ?? '',
      catalogItemId: json['catalogItemId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      pathKey: json['pathKey'] as String? ?? '',
      requestedQuantity: (json['requestedQuantity'] as num?)?.toDouble() ?? 0,
      hasRecordedExecution: json['hasRecordedExecution'] as bool? ?? false,
      canEdit: json['canEdit'] as bool? ?? false,
      workshop: json['workshop'] as String?,
    );
  }

  final String id;
  final String structureOccurrenceId;
  final String catalogItemId;
  final String displayName;
  final String pathKey;
  final double requestedQuantity;
  final bool hasRecordedExecution;
  final bool canEdit;
  final String? workshop;

  Map<String, Object?> toJson() => {
    'id': id,
    'structureOccurrenceId': structureOccurrenceId,
    'catalogItemId': catalogItemId,
    'displayName': displayName,
    'pathKey': pathKey,
    'requestedQuantity': requestedQuantity,
    'hasRecordedExecution': hasRecordedExecution,
    'canEdit': canEdit,
    'workshop': workshop,
  };
}
