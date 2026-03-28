import 'dart:io';

import 'package:import_engine/import_engine.dart';

void main() {
  const row = NormalizedImportRow(
    rowNumber: 1,
    positionNumber: '10',
    name: 'Detail 1',
    code: 'DET-1',
    objectType: ImportObjectType.detail,
    quantity: 2,
  );

  final preview = const ImportPreviewBuilder().build(
    machineVersionId: 'ver-1',
    rows: const [row],
  );

  stdout.writeln('Occurrences: ${preview.structureOccurrences.length}');
}
