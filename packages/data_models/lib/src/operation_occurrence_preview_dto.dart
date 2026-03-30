import 'package:domain/domain.dart';

class OperationOccurrencePreviewDto {
  const OperationOccurrencePreviewDto({
    required this.id,
    required this.structureOccurrenceId,
    required this.name,
    required this.quantityPerMachine,
    this.workshop,
    required this.inheritedWorkshop,
    this.sourcePositionNumber,
    this.sourceQuantity,
  });

  factory OperationOccurrencePreviewDto.fromDomain(
    OperationOccurrence occurrence,
  ) {
    return OperationOccurrencePreviewDto(
      id: occurrence.id,
      structureOccurrenceId: occurrence.structureOccurrenceId,
      name: occurrence.name,
      quantityPerMachine: occurrence.quantityPerMachine,
      workshop: occurrence.workshop,
      inheritedWorkshop: occurrence.inheritedWorkshop,
      sourcePositionNumber: occurrence.sourcePositionNumber,
      sourceQuantity: occurrence.sourceQuantity,
    );
  }

  factory OperationOccurrencePreviewDto.fromJson(Map<String, Object?> json) {
    return OperationOccurrencePreviewDto(
      id: json['id'] as String? ?? '',
      structureOccurrenceId: json['structureOccurrenceId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      quantityPerMachine: (json['quantityPerMachine'] as num?)?.toDouble() ?? 0,
      workshop: json['workshop'] as String?,
      inheritedWorkshop: json['inheritedWorkshop'] as bool? ?? false,
      sourcePositionNumber: json['sourcePositionNumber'] as String?,
      sourceQuantity: (json['sourceQuantity'] as num?)?.toDouble(),
    );
  }

  final String id;
  final String structureOccurrenceId;
  final String name;
  final double quantityPerMachine;
  final String? workshop;
  final bool inheritedWorkshop;
  final String? sourcePositionNumber;
  final double? sourceQuantity;

  Map<String, Object?> toJson() => {
    'id': id,
    'structureOccurrenceId': structureOccurrenceId,
    'name': name,
    'quantityPerMachine': quantityPerMachine,
    'workshop': workshop,
    'inheritedWorkshop': inheritedWorkshop,
    'sourcePositionNumber': sourcePositionNumber,
    'sourceQuantity': sourceQuantity,
  };
}
