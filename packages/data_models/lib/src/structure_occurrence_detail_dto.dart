import 'package:domain/domain.dart';

class StructureOccurrenceDetailDto {
  const StructureOccurrenceDetailDto({
    required this.id,
    required this.versionId,
    required this.catalogItemId,
    required this.displayName,
    required this.pathKey,
    required this.quantityPerMachine,
    this.parentOccurrenceId,
    this.workshop,
  });

  factory StructureOccurrenceDetailDto.fromDomain(
    StructureOccurrence occurrence,
  ) {
    return StructureOccurrenceDetailDto(
      id: occurrence.id,
      versionId: occurrence.versionId,
      catalogItemId: occurrence.catalogItemId,
      displayName: occurrence.displayName,
      pathKey: occurrence.pathKey,
      quantityPerMachine: occurrence.quantityPerMachine,
      parentOccurrenceId: occurrence.parentOccurrenceId,
      workshop: occurrence.workshop,
    );
  }

  factory StructureOccurrenceDetailDto.fromJson(Map<String, Object?> json) {
    return StructureOccurrenceDetailDto(
      id: json['id'] as String? ?? '',
      versionId: json['versionId'] as String? ?? '',
      catalogItemId: json['catalogItemId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      pathKey: json['pathKey'] as String? ?? '',
      quantityPerMachine: (json['quantityPerMachine'] as num?)?.toDouble() ?? 0,
      parentOccurrenceId: json['parentOccurrenceId'] as String?,
      workshop: json['workshop'] as String?,
    );
  }

  final String id;
  final String versionId;
  final String catalogItemId;
  final String displayName;
  final String pathKey;
  final double quantityPerMachine;
  final String? parentOccurrenceId;
  final String? workshop;

  Map<String, Object?> toJson() => {
    'id': id,
    'versionId': versionId,
    'catalogItemId': catalogItemId,
    'displayName': displayName,
    'pathKey': pathKey,
    'quantityPerMachine': quantityPerMachine,
    'parentOccurrenceId': parentOccurrenceId,
    'workshop': workshop,
  };
}
