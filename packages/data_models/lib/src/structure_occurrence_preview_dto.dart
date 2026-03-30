import 'package:domain/domain.dart';

class StructureOccurrencePreviewDto {
  const StructureOccurrencePreviewDto({
    required this.id,
    required this.catalogItemId,
    required this.pathKey,
    required this.displayName,
    required this.quantityPerMachine,
    this.parentOccurrenceId,
    this.workshop,
    required this.inheritedWorkshop,
    this.sourcePositionNumber,
    this.sourceOwnerName,
  });

  factory StructureOccurrencePreviewDto.fromDomain(
    StructureOccurrence occurrence,
  ) {
    return StructureOccurrencePreviewDto(
      id: occurrence.id,
      catalogItemId: occurrence.catalogItemId,
      pathKey: occurrence.pathKey,
      displayName: occurrence.displayName,
      quantityPerMachine: occurrence.quantityPerMachine,
      parentOccurrenceId: occurrence.parentOccurrenceId,
      workshop: occurrence.workshop,
      inheritedWorkshop: occurrence.inheritedWorkshop,
      sourcePositionNumber: occurrence.sourcePositionNumber,
      sourceOwnerName: occurrence.sourceOwnerName,
    );
  }

  factory StructureOccurrencePreviewDto.fromJson(Map<String, Object?> json) {
    return StructureOccurrencePreviewDto(
      id: json['id'] as String? ?? '',
      catalogItemId: json['catalogItemId'] as String? ?? '',
      pathKey: json['pathKey'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      quantityPerMachine: (json['quantityPerMachine'] as num?)?.toDouble() ?? 0,
      parentOccurrenceId: json['parentOccurrenceId'] as String?,
      workshop: json['workshop'] as String?,
      inheritedWorkshop: json['inheritedWorkshop'] as bool? ?? false,
      sourcePositionNumber: json['sourcePositionNumber'] as String?,
      sourceOwnerName: json['sourceOwnerName'] as String?,
    );
  }

  final String id;
  final String catalogItemId;
  final String pathKey;
  final String displayName;
  final double quantityPerMachine;
  final String? parentOccurrenceId;
  final String? workshop;
  final bool inheritedWorkshop;
  final String? sourcePositionNumber;
  final String? sourceOwnerName;

  Map<String, Object?> toJson() => {
    'id': id,
    'catalogItemId': catalogItemId,
    'pathKey': pathKey,
    'displayName': displayName,
    'quantityPerMachine': quantityPerMachine,
    'parentOccurrenceId': parentOccurrenceId,
    'workshop': workshop,
    'inheritedWorkshop': inheritedWorkshop,
    'sourcePositionNumber': sourcePositionNumber,
    'sourceOwnerName': sourceOwnerName,
  };
}
