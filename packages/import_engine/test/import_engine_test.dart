import 'package:import_engine/import_engine.dart';
import 'package:test/test.dart';

void main() {
  const builder = ImportPreviewBuilder();

  test('same code in different places stays as separate structure occurrences', () {
    final preview = builder.build(
      machineVersionId: 'ver-1',
      rows: const [
        NormalizedImportRow(
          rowNumber: 1,
          positionNumber: '10',
          name: 'Место 1/4',
          code: 'PLACE-1',
          objectType: ImportObjectType.place,
          quantity: 1,
        ),
        NormalizedImportRow(
          rowNumber: 2,
          positionNumber: '11',
          name: 'КИР 03.060',
          code: 'DET-42',
          objectType: ImportObjectType.detail,
          ownerName: 'Место 1/4',
          nomSv: '10',
          quantity: 28,
        ),
        NormalizedImportRow(
          rowNumber: 3,
          positionNumber: '20',
          name: 'Место 3/4',
          code: 'PLACE-3',
          objectType: ImportObjectType.place,
          quantity: 1,
        ),
        NormalizedImportRow(
          rowNumber: 4,
          positionNumber: '21',
          name: 'КИР 03.060',
          code: 'DET-42',
          objectType: ImportObjectType.detail,
          ownerName: 'Место 3/4',
          nomSv: '20',
          quantity: 4,
        ),
      ],
    );

    expect(preview.catalogItems.length, 3);
    expect(preview.structureOccurrences.where((item) => item.displayName == 'КИР 03.060'), hasLength(2));
  });

  test('ambiguous parent is reported as conflict instead of auto-picking nearest row', () {
    final preview = builder.build(
      machineVersionId: 'ver-1',
      rows: const [
        NormalizedImportRow(
          rowNumber: 1,
          positionNumber: '10',
          name: 'КИР 03.060',
          code: 'DET-42',
          objectType: ImportObjectType.detail,
          quantity: 28,
        ),
        NormalizedImportRow(
          rowNumber: 2,
          positionNumber: '20',
          name: 'КИР 03.060',
          code: 'DET-42',
          objectType: ImportObjectType.detail,
          quantity: 4,
        ),
        NormalizedImportRow(
          rowNumber: 3,
          positionNumber: '30',
          name: 'Сверление',
          code: 'OP-1',
          objectType: ImportObjectType.operation,
          ownerName: 'КИР 03.060',
          quantity: 999,
        ),
      ],
    );

    expect(preview.operationOccurrences, isEmpty);
    expect(preview.conflicts.single.reason, 'parent_ambiguous');
  });

  test('operation quantity inherits from resolved structure occurrence', () {
    final preview = builder.build(
      machineVersionId: 'ver-1',
      rows: const [
        NormalizedImportRow(
          rowNumber: 1,
          positionNumber: '10',
          name: 'Место 1/4',
          code: 'PLACE-1',
          objectType: ImportObjectType.place,
          quantity: 1,
          workshop: 'Сборочный участок',
        ),
        NormalizedImportRow(
          rowNumber: 2,
          positionNumber: '11',
          name: 'КИР 03.060',
          code: 'DET-42',
          objectType: ImportObjectType.detail,
          ownerName: 'Место 1/4',
          nomSv: '10',
          quantity: 28,
        ),
        NormalizedImportRow(
          rowNumber: 3,
          positionNumber: '12',
          name: 'Сверление',
          code: 'OP-1',
          objectType: ImportObjectType.operation,
          ownerName: 'КИР 03.060',
          nomSv: '11',
          quantity: 3,
        ),
      ],
    );

    expect(preview.operationOccurrences.single.quantityPerMachine, 28);
    expect(preview.operationOccurrences.single.inheritedWorkshop, isTrue);
  });

  test('special processes are skipped', () {
    final preview = builder.build(
      machineVersionId: 'ver-1',
      rows: const [
        NormalizedImportRow(
          rowNumber: 1,
          positionNumber: '10',
          name: 'Литье',
          code: 'SP-1',
          objectType: ImportObjectType.specialProcess,
          quantity: 1,
        ),
      ],
    );

    expect(preview.structureOccurrences, isEmpty);
    expect(preview.skippedRows.single.reason, 'special_process_skipped');
  });
}
