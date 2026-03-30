import 'package:domain/domain.dart';

class ImportPreview {
  const ImportPreview({
    required this.catalogItems,
    required this.structureOccurrences,
    required this.operationOccurrences,
    required this.conflicts,
    required this.skippedRows,
    this.warnings = const [],
  });

  final List<CatalogItem> catalogItems;
  final List<StructureOccurrence> structureOccurrences;
  final List<OperationOccurrence> operationOccurrences;
  final List<ImportConflict> conflicts;
  final List<SkippedImportRow> skippedRows;
  final List<ImportWarning> warnings;
}

class ImportConflict {
  const ImportConflict({
    required this.rowNumber,
    required this.reason,
    this.candidates = const [],
  });

  final int rowNumber;
  final String reason;
  final List<String> candidates;
}

class SkippedImportRow {
  const SkippedImportRow({
    required this.rowNumber,
    required this.reason,
    required this.name,
  });

  final int rowNumber;
  final String reason;
  final String name;
}

class ImportWarning {
  const ImportWarning({
    required this.code,
    required this.message,
    this.rowNumber,
  });

  final String code;
  final String message;
  final int? rowNumber;
}
