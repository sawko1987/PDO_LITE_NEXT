import 'import_conflict_dto.dart';
import 'import_warning_dto.dart';
import 'operation_occurrence_preview_dto.dart';
import 'structure_occurrence_preview_dto.dart';

class ImportPreviewDto {
  const ImportPreviewDto({
    required this.fileName,
    required this.sourceFormat,
    required this.detectionReason,
    required this.rowCount,
    required this.canConfirm,
    required this.catalogItemCount,
    required this.structureOccurrenceCount,
    required this.operationOccurrenceCount,
    required this.conflictCount,
    required this.warningCount,
    required this.conflicts,
    required this.warnings,
    required this.structureOccurrences,
    required this.operationOccurrences,
    this.machineName,
    this.machineCode,
  });

  factory ImportPreviewDto.fromJson(Map<String, Object?> json) {
    final rawConflicts = json['conflicts'] as List<Object?>? ?? const [];
    final rawWarnings = json['warnings'] as List<Object?>? ?? const [];
    final rawStructureOccurrences =
        json['structureOccurrences'] as List<Object?>? ?? const [];
    final rawOperationOccurrences =
        json['operationOccurrences'] as List<Object?>? ?? const [];

    return ImportPreviewDto(
      fileName: json['fileName'] as String? ?? '',
      sourceFormat: json['sourceFormat'] as String? ?? '',
      detectionReason: json['detectionReason'] as String? ?? '',
      rowCount: json['rowCount'] as int? ?? 0,
      canConfirm: json['canConfirm'] as bool? ?? false,
      catalogItemCount: json['catalogItemCount'] as int? ?? 0,
      structureOccurrenceCount: json['structureOccurrenceCount'] as int? ?? 0,
      operationOccurrenceCount: json['operationOccurrenceCount'] as int? ?? 0,
      conflictCount: json['conflictCount'] as int? ?? 0,
      warningCount: json['warningCount'] as int? ?? 0,
      machineName: json['machineName'] as String?,
      machineCode: json['machineCode'] as String?,
      conflicts: rawConflicts
          .map(
            (item) => ImportConflictDto.fromJson(
              (item as Map<Object?, Object?>).cast(),
            ),
          )
          .toList(growable: false),
      warnings: rawWarnings
          .map(
            (item) => ImportWarningDto.fromJson(
              (item as Map<Object?, Object?>).cast(),
            ),
          )
          .toList(growable: false),
      structureOccurrences: rawStructureOccurrences
          .map(
            (item) => StructureOccurrencePreviewDto.fromJson(
              (item as Map<Object?, Object?>).cast(),
            ),
          )
          .toList(growable: false),
      operationOccurrences: rawOperationOccurrences
          .map(
            (item) => OperationOccurrencePreviewDto.fromJson(
              (item as Map<Object?, Object?>).cast(),
            ),
          )
          .toList(growable: false),
    );
  }

  final String fileName;
  final String sourceFormat;
  final String detectionReason;
  final int rowCount;
  final bool canConfirm;
  final int catalogItemCount;
  final int structureOccurrenceCount;
  final int operationOccurrenceCount;
  final int conflictCount;
  final int warningCount;
  final List<ImportConflictDto> conflicts;
  final List<ImportWarningDto> warnings;
  final List<StructureOccurrencePreviewDto> structureOccurrences;
  final List<OperationOccurrencePreviewDto> operationOccurrences;
  final String? machineName;
  final String? machineCode;

  Map<String, Object?> toJson() => {
    'fileName': fileName,
    'sourceFormat': sourceFormat,
    'detectionReason': detectionReason,
    'rowCount': rowCount,
    'canConfirm': canConfirm,
    'catalogItemCount': catalogItemCount,
    'structureOccurrenceCount': structureOccurrenceCount,
    'operationOccurrenceCount': operationOccurrenceCount,
    'conflictCount': conflictCount,
    'warningCount': warningCount,
    'machineName': machineName,
    'machineCode': machineCode,
    'conflicts': conflicts.map((item) => item.toJson()).toList(growable: false),
    'warnings': warnings.map((item) => item.toJson()).toList(growable: false),
    'structureOccurrences': structureOccurrences
        .map((item) => item.toJson())
        .toList(growable: false),
    'operationOccurrences': operationOccurrences
        .map((item) => item.toJson())
        .toList(growable: false),
  };
}
