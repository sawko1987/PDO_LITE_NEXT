import 'structure_occurrence_detail_dto.dart';
import 'operation_occurrence_detail_dto.dart';

class MachineVersionDetailDto {
  const MachineVersionDetailDto({
    required this.id,
    required this.machineId,
    required this.label,
    required this.createdAt,
    required this.status,
    required this.isImmutable,
    required this.isActiveVersion,
    required this.structureOccurrences,
    required this.operationOccurrences,
  });

  factory MachineVersionDetailDto.fromJson(Map<String, Object?> json) {
    final structureOccurrences =
        (json['structureOccurrences'] as List<Object?>? ?? const [])
            .whereType<Map<Object?, Object?>>()
            .map(
              (item) =>
                  StructureOccurrenceDetailDto.fromJson(
                    item.cast<String, Object?>(),
                  ),
            )
            .toList(growable: false);
    final operationOccurrences =
        (json['operationOccurrences'] as List<Object?>? ?? const [])
            .whereType<Map<Object?, Object?>>()
            .map(
              (item) =>
                  OperationOccurrenceDetailDto.fromJson(
                    item.cast<String, Object?>(),
                  ),
            )
            .toList(growable: false);
    return MachineVersionDetailDto(
      id: json['id'] as String? ?? '',
      machineId: json['machineId'] as String? ?? '',
      label: json['label'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      status: json['status'] as String? ?? '',
      isImmutable: json['isImmutable'] as bool? ?? false,
      isActiveVersion: json['isActiveVersion'] as bool? ?? false,
      structureOccurrences: structureOccurrences,
      operationOccurrences: operationOccurrences,
    );
  }

  final String id;
  final String machineId;
  final String label;
  final DateTime createdAt;
  final String status;
  final bool isImmutable;
  final bool isActiveVersion;
  final List<StructureOccurrenceDetailDto> structureOccurrences;
  final List<OperationOccurrenceDetailDto> operationOccurrences;

  Map<String, Object?> toJson() => {
    'id': id,
    'machineId': machineId,
    'label': label,
    'createdAt': createdAt.toIso8601String(),
    'status': status,
    'isImmutable': isImmutable,
    'isActiveVersion': isActiveVersion,
    'structureOccurrences': structureOccurrences
        .map((occurrence) => occurrence.toJson())
        .toList(growable: false),
    'operationOccurrences': operationOccurrences
        .map((occurrence) => occurrence.toJson())
        .toList(growable: false),
  };
}
