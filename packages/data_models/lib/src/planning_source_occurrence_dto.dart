import 'package:domain/domain.dart';

class PlanningSourceOccurrenceDto {
  const PlanningSourceOccurrenceDto({
    required this.id,
    required this.catalogItemId,
    required this.displayName,
    required this.pathKey,
    required this.quantityPerMachine,
    required this.operationCount,
    this.workshop,
  });

  factory PlanningSourceOccurrenceDto.fromDomain(
    StructureOccurrence occurrence, {
    required int operationCount,
  }) {
    return PlanningSourceOccurrenceDto(
      id: occurrence.id,
      catalogItemId: occurrence.catalogItemId,
      displayName: occurrence.displayName,
      pathKey: occurrence.pathKey,
      quantityPerMachine: occurrence.quantityPerMachine,
      workshop: occurrence.workshop,
      operationCount: operationCount,
    );
  }

  factory PlanningSourceOccurrenceDto.fromJson(Map<String, Object?> json) {
    return PlanningSourceOccurrenceDto(
      id: json['id'] as String? ?? '',
      catalogItemId: json['catalogItemId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      pathKey: json['pathKey'] as String? ?? '',
      quantityPerMachine: (json['quantityPerMachine'] as num?)?.toDouble() ?? 0,
      workshop: json['workshop'] as String?,
      operationCount: json['operationCount'] as int? ?? 0,
    );
  }

  final String id;
  final String catalogItemId;
  final String displayName;
  final String pathKey;
  final double quantityPerMachine;
  final String? workshop;
  final int operationCount;

  Map<String, Object?> toJson() => {
    'id': id,
    'catalogItemId': catalogItemId,
    'displayName': displayName,
    'pathKey': pathKey,
    'quantityPerMachine': quantityPerMachine,
    'workshop': workshop,
    'operationCount': operationCount,
  };
}
