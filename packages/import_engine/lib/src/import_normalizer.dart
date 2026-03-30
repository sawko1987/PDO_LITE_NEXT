import 'import_object_type.dart';
import 'import_preview.dart';
import 'normalized_import_row.dart';
import 'parsed_import_document.dart';

class ImportNormalizationResult {
  const ImportNormalizationResult({
    required this.rows,
    required this.conflicts,
    required this.warnings,
    this.machineName,
    this.machineCode,
  });

  final List<NormalizedImportRow> rows;
  final List<ImportConflict> conflicts;
  final List<ImportWarning> warnings;
  final String? machineName;
  final String? machineCode;
}

class ImportNormalizer {
  const ImportNormalizer();

  static const Map<String, String> _headerAliases = {
    'position_number': 'position_number',
    'position': 'position_number',
    'nomcl': 'position_number',
    'name': 'name',
    'item_name': 'name',
    'code': 'code',
    'item_code': 'code',
    'object_type': 'object_type',
    'type': 'object_type',
    'owner_name': 'owner_name',
    'owner': 'owner_name',
    'parent_name': 'owner_name',
    'nom_sv': 'nom_sv',
    'parent_position_number': 'nom_sv',
    'workshop': 'workshop',
    'shop': 'workshop',
    'quantity': 'quantity',
    'qty': 'quantity',
    'total_quantity': 'quantity',
    'level': 'level',
    'machine_name': 'machine_name',
    'machine_code': 'machine_code',
  };

  ImportNormalizationResult normalize(ParsedImportDocument document) {
    final conflicts = <ImportConflict>[];
    final warnings = <ImportWarning>[];
    final requiredHeaders = {'position_number', 'name', 'code', 'object_type'};
    final presentHeaders = document.headers
        .map(_canonicalHeader)
        .where(_headerAliases.containsKey)
        .map((header) => _headerAliases[header]!)
        .toSet();
    final missingHeaders = requiredHeaders.difference(presentHeaders).toList()
      ..sort();
    if (missingHeaders.isNotEmpty) {
      return ImportNormalizationResult(
        rows: const [],
        conflicts: [
          ImportConflict(
            rowNumber: 0,
            reason: 'missing_required_columns',
            candidates: missingHeaders,
          ),
        ],
        warnings: const [],
      );
    }

    final normalizedRows = <NormalizedImportRow>[];
    String? machineName = _normalizeMachineField(document.machineName);
    String? machineCode = _normalizeMachineField(document.machineCode);

    for (final row in document.rows) {
      final values = <String, String>{};
      row.values.forEach((header, value) {
        final canonical = _headerAliases[_canonicalHeader(header)];
        if (canonical != null) {
          values[canonical] = value.trim();
        }
      });

      final positionNumber = values['position_number'] ?? '';
      final name = values['name'] ?? '';
      final code = values['code'] ?? '';
      final objectTypeValue = values['object_type'] ?? '';
      machineName ??= _normalizeMachineField(values['machine_name']);
      machineCode ??= _normalizeMachineField(values['machine_code']);

      if (positionNumber.isEmpty &&
          name.isEmpty &&
          code.isEmpty &&
          objectTypeValue.isEmpty) {
        warnings.add(
          ImportWarning(
            code: 'empty_row_skipped',
            message: 'Row does not contain import data and was skipped.',
            rowNumber: row.rowNumber,
          ),
        );
        continue;
      }

      final objectType = _parseObjectType(objectTypeValue);
      if (positionNumber.isEmpty ||
          name.isEmpty ||
          code.isEmpty ||
          objectType == null) {
        final missingFields = <String>[
          if (positionNumber.isEmpty) 'position_number',
          if (name.isEmpty) 'name',
          if (code.isEmpty) 'code',
          if (objectType == null) 'object_type:$objectTypeValue',
        ];
        conflicts.add(
          ImportConflict(
            rowNumber: row.rowNumber,
            reason: objectType == null
                ? 'unsupported_object_type'
                : 'missing_required_value',
            candidates: missingFields,
          ),
        );
        continue;
      }

      final quantityText = values['quantity'];
      final quantity = _parseDouble(quantityText);
      if (quantityText != null && quantityText.isNotEmpty && quantity == null) {
        conflicts.add(
          ImportConflict(
            rowNumber: row.rowNumber,
            reason: 'invalid_quantity',
            candidates: [quantityText],
          ),
        );
        continue;
      }

      if (quantity != null && quantity <= 0) {
        conflicts.add(
          ImportConflict(
            rowNumber: row.rowNumber,
            reason: 'non_positive_quantity',
            candidates: [quantity.toString()],
          ),
        );
        continue;
      }

      final levelText = values['level'];
      final level = levelText == null || levelText.isEmpty
          ? null
          : int.tryParse(levelText);
      if (levelText != null && levelText.isNotEmpty && level == null) {
        warnings.add(
          ImportWarning(
            code: 'invalid_level_ignored',
            message: 'Level value was ignored because it is not an integer.',
            rowNumber: row.rowNumber,
          ),
        );
      }

      normalizedRows.add(
        NormalizedImportRow(
          rowNumber: row.rowNumber,
          positionNumber: positionNumber,
          name: name,
          code: code,
          objectType: objectType,
          ownerName: _nullIfEmpty(values['owner_name']),
          nomSv: _nullIfEmpty(values['nom_sv']),
          workshop: _nullIfEmpty(values['workshop']),
          quantity: quantity,
          level: level,
        ),
      );
    }

    if (machineName == null || machineCode == null) {
      warnings.add(
        const ImportWarning(
          code: 'machine_metadata_missing',
          message:
              'Machine metadata is incomplete in the file. Version preview can still be inspected.',
        ),
      );
    }

    return ImportNormalizationResult(
      rows: normalizedRows,
      conflicts: conflicts,
      warnings: warnings,
      machineName: machineName,
      machineCode: machineCode,
    );
  }

  String _canonicalHeader(String header) {
    return header
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  ImportObjectType? _parseObjectType(String rawType) {
    final normalized = rawType.trim().toLowerCase();
    switch (normalized) {
      case 'machine':
      case 'машина':
        return ImportObjectType.machine;
      case 'place':
      case 'место':
        return ImportObjectType.place;
      case 'node':
      case 'узел':
        return ImportObjectType.node;
      case 'detail':
      case 'деталь':
        return ImportObjectType.detail;
      case 'material':
      case 'материал':
        return ImportObjectType.material;
      case 'operation':
      case 'операция':
        return ImportObjectType.operation;
      case 'special_process':
      case 'specialprocess':
      case 'special process':
      case 'спецпроцесс':
        return ImportObjectType.specialProcess;
      default:
        return null;
    }
  }

  double? _parseDouble(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    return double.tryParse(value.replaceAll(',', '.'));
  }

  String? _normalizeMachineField(String? value) => _nullIfEmpty(value);

  String? _nullIfEmpty(String? value) {
    if (value == null) {
      return null;
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
