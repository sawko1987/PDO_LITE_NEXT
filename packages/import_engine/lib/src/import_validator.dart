import 'import_object_type.dart';
import 'import_preview.dart';
import 'normalized_import_row.dart';

class ImportValidationResult {
  const ImportValidationResult({
    required this.conflicts,
    required this.warnings,
  });

  final List<ImportConflict> conflicts;
  final List<ImportWarning> warnings;
}

class ImportValidator {
  const ImportValidator();

  ImportValidationResult validate(List<NormalizedImportRow> rows) {
    final conflicts = <ImportConflict>[];
    final warnings = <ImportWarning>[];
    if (rows.isEmpty) {
      conflicts.add(const ImportConflict(rowNumber: 0, reason: 'empty_import'));
      return ImportValidationResult(conflicts: conflicts, warnings: warnings);
    }

    final positions = <String, int>{};
    final machineRows = rows
        .where((row) => row.objectType == ImportObjectType.machine)
        .toList();
    if (machineRows.length > 1) {
      warnings.add(
        ImportWarning(
          code: 'multiple_machine_rows',
          message:
              'Multiple machine rows were found. The preview keeps them as structure rows.',
          rowNumber: machineRows.first.rowNumber,
        ),
      );
    }

    for (final row in rows) {
      final existingRow = positions[row.positionNumber];
      if (existingRow != null) {
        warnings.add(
          ImportWarning(
            code: 'duplicate_position_number',
            message:
                'Position number ${row.positionNumber} is repeated in multiple rows.',
            rowNumber: row.rowNumber,
          ),
        );
      } else {
        positions[row.positionNumber] = row.rowNumber;
      }
    }

    return ImportValidationResult(conflicts: conflicts, warnings: warnings);
  }
}
