import 'dart:convert';
import 'dart:io';

import 'package:import_engine/import_engine.dart';
import 'package:test/test.dart';

void main() {
  const service = ImportPreviewService();

  test('xlsx fixture is detected and converted into preview', () {
    final result = service.buildPreview(
      machineVersionId: 'ver-xlsx',
      source: ImportSourceFile(
        fileName: 'valid_import.xlsx',
        bytes: base64.decode(
          _readFixture('valid_import.xlsx.b64').replaceAll(RegExp(r'\s+'), ''),
        ),
      ),
    );

    expect(result.sourceInfo.format, ImportSourceFormat.excel);
    expect(result.sourceInfo.rowCount, 3);
    expect(result.canConfirm, isTrue);
    expect(result.preview.catalogItems, hasLength(2));
    expect(result.preview.structureOccurrences, hasLength(2));
    expect(result.preview.operationOccurrences, hasLength(1));
    expect(result.preview.conflicts, isEmpty);
    expect(result.machineName, isNotNull);
    expect(result.machineCode, isNotNull);
  });

  test('mxl fixture is detected and keeps operation quantity inherited', () {
    final result = service.buildPreview(
      machineVersionId: 'ver-mxl',
      source: ImportSourceFile(
        fileName: 'valid_import.mxl',
        bytes: utf8.encode(_readFixture('valid_import.mxl')),
      ),
    );

    expect(result.sourceInfo.format, ImportSourceFormat.mxl);
    expect(result.canConfirm, isTrue);
    expect(result.preview.structureOccurrences, hasLength(2));
    expect(result.preview.operationOccurrences.single.quantityPerMachine, 5);
    expect(
      result.preview.operationOccurrences.single.inheritedWorkshop,
      isTrue,
    );
  });

  test(
    'ambiguous parent fixture blocks confirmation with explicit conflict',
    () {
      final result = service.buildPreview(
        machineVersionId: 'ver-conflict',
        source: ImportSourceFile(
          fileName: 'conflict_ambiguous_parent.mxl',
          bytes: utf8.encode(_readFixture('conflict_ambiguous_parent.mxl')),
        ),
      );

      expect(result.sourceInfo.format, ImportSourceFormat.mxl);
      expect(result.canConfirm, isFalse);
      expect(result.preview.operationOccurrences, isEmpty);
      expect(
        result.preview.conflicts.map((conflict) => conflict.reason),
        contains('parent_ambiguous'),
      );
    },
  );

  test('unsupported source returns deterministic unsupported conflict', () {
    final result = service.buildPreview(
      machineVersionId: 'ver-unsupported',
      source: ImportSourceFile(
        fileName: 'broken.txt',
        bytes: utf8.encode('not a spreadsheet'),
      ),
    );

    expect(result.canConfirm, isFalse);
    expect(result.preview.conflicts.single.reason, 'unsupported_extension_txt');
  });
}

String _readFixture(String fileName) {
  return File('test/fixtures/$fileName').readAsStringSync();
}
