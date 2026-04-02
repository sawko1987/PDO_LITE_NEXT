import 'package:domain/domain.dart';

class OperationOccurrenceDetailDto {
  const OperationOccurrenceDetailDto({
    required this.id,
    required this.versionId,
    required this.structureOccurrenceId,
    required this.name,
    required this.quantityPerMachine,
    this.workshop,
  });

  factory OperationOccurrenceDetailDto.fromDomain(
    OperationOccurrence occurrence,
  ) {
    return OperationOccurrenceDetailDto(
      id: occurrence.id,
      versionId: occurrence.versionId,
      structureOccurrenceId: occurrence.structureOccurrenceId,
      name: occurrence.name,
      quantityPerMachine: occurrence.quantityPerMachine,
      workshop: occurrence.workshop,
    );
  }

  factory OperationOccurrenceDetailDto.fromJson(Map<String, Object?> json) {
    return OperationOccurrenceDetailDto(
      id: json['id'] as String? ?? '',
      versionId: json['versionId'] as String? ?? '',
      structureOccurrenceId: json['structureOccurrenceId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      quantityPerMachine: (json['quantityPerMachine'] as num?)?.toDouble() ?? 0,
      workshop: json['workshop'] as String?,
    );
  }

  final String id;
  final String versionId;
  final String structureOccurrenceId;
  final String name;
  final double quantityPerMachine;
  final String? workshop;

  Map<String, Object?> toJson() => {
    'id': id,
    'versionId': versionId,
    'structureOccurrenceId': structureOccurrenceId,
    'name': name,
    'quantityPerMachine': quantityPerMachine,
    'workshop': workshop,
  };
}
