import 'package:domain/domain.dart';

import 'import_object_type.dart';
import 'import_preview.dart';
import 'normalized_import_row.dart';

class ImportPreviewBuilder {
  const ImportPreviewBuilder();

  ImportPreview build({
    required String machineVersionId,
    required List<NormalizedImportRow> rows,
    List<ImportConflict> externalConflicts = const [],
    List<ImportWarning> externalWarnings = const [],
  }) {
    final catalogItemsByCode = <String, CatalogItem>{};
    final occurrencesByRow = <int, StructureOccurrence>{};
    final occurrencesByPosition = <String, StructureOccurrence>{};
    final structuralRowsByName = <String, List<NormalizedImportRow>>{};
    final structureOccurrences = <StructureOccurrence>[];
    final operationOccurrences = <OperationOccurrence>[];
    final conflicts = <ImportConflict>[...externalConflicts];
    final skippedRows = <SkippedImportRow>[];

    for (final row in rows.where((row) => !row.isOperation)) {
      if (_isSkippedSpecialProcess(row)) {
        skippedRows.add(
          SkippedImportRow(
            rowNumber: row.rowNumber,
            reason: 'special_process_skipped',
            name: row.name,
          ),
        );
        continue;
      }

      final parent = _resolveParent(
        row: row,
        rowsByName: structuralRowsByName,
        rowsByPosition: occurrencesByPosition,
        occurrencesByRow: occurrencesByRow,
      );
      if (row.ownerName != null &&
          row.ownerName!.trim().isNotEmpty &&
          parent.conflict != null) {
        conflicts.add(parent.conflict!);
        continue;
      }

      final catalogItem = catalogItemsByCode.putIfAbsent(
        row.code,
        () => CatalogItem(
          id: 'catalog:${row.code}',
          code: row.code,
          name: row.name,
          kind: _mapCatalogKind(row.objectType),
        ),
      );

      final inheritedWorkshop =
          (row.workshop == null || row.workshop!.trim().isEmpty) &&
          parent.occurrence?.workshop != null;
      final occurrence = StructureOccurrence(
        id: 'occ:${row.rowNumber}',
        versionId: machineVersionId,
        catalogItemId: catalogItem.id,
        pathKey:
            '${parent.occurrence?.pathKey ?? 'root'}/${row.positionNumber}:${row.code}',
        displayName: row.name,
        quantityPerMachine: row.quantity ?? 1,
        parentOccurrenceId: parent.occurrence?.id,
        workshop: inheritedWorkshop
            ? parent.occurrence?.workshop
            : row.workshop,
        inheritedWorkshop: inheritedWorkshop,
        sourcePositionNumber: row.positionNumber,
        sourceOwnerName: row.ownerName,
      );

      structureOccurrences.add(occurrence);
      occurrencesByRow[row.rowNumber] = occurrence;
      occurrencesByPosition[row.positionNumber] = occurrence;
      structuralRowsByName.putIfAbsent(row.name, () => []).add(row);
    }

    for (final row in rows.where((row) => row.isOperation)) {
      final parent = _resolveParent(
        row: row,
        rowsByName: structuralRowsByName,
        rowsByPosition: occurrencesByPosition,
        occurrencesByRow: occurrencesByRow,
      );
      if (parent.occurrence == null) {
        conflicts.add(
          parent.conflict ??
              ImportConflict(
                rowNumber: row.rowNumber,
                reason: 'operation_parent_not_found',
              ),
        );
        continue;
      }

      final inheritedWorkshop =
          (row.workshop == null || row.workshop!.trim().isEmpty) &&
          parent.occurrence?.workshop != null;
      operationOccurrences.add(
        OperationOccurrence(
          id: 'op:${row.rowNumber}',
          versionId: machineVersionId,
          structureOccurrenceId: parent.occurrence!.id,
          name: row.name,
          quantityPerMachine: parent.occurrence!.quantityPerMachine,
          workshop: inheritedWorkshop
              ? parent.occurrence?.workshop
              : row.workshop,
          inheritedWorkshop: inheritedWorkshop,
          sourcePositionNumber: row.positionNumber,
          sourceQuantity: row.quantity,
        ),
      );
    }

    return ImportPreview(
      catalogItems: catalogItemsByCode.values.toList(growable: false),
      structureOccurrences: structureOccurrences,
      operationOccurrences: operationOccurrences,
      conflicts: conflicts,
      skippedRows: skippedRows,
      warnings: externalWarnings,
    );
  }

  _ParentResolution _resolveParent({
    required NormalizedImportRow row,
    required Map<String, List<NormalizedImportRow>> rowsByName,
    required Map<String, StructureOccurrence> rowsByPosition,
    required Map<int, StructureOccurrence> occurrencesByRow,
  }) {
    final ownerName = row.ownerName?.trim();
    if (ownerName == null || ownerName.isEmpty) {
      return const _ParentResolution.root();
    }

    if (row.nomSv != null && row.nomSv!.trim().isNotEmpty) {
      final nomSvOccurrence = rowsByPosition[row.nomSv!.trim()];
      if (nomSvOccurrence != null && nomSvOccurrence.displayName == ownerName) {
        return _ParentResolution(occurrence: nomSvOccurrence);
      }
    }

    final candidates = rowsByName[ownerName] ?? const [];
    if (candidates.isEmpty) {
      return _ParentResolution(
        conflict: ImportConflict(
          rowNumber: row.rowNumber,
          reason: 'parent_not_found',
        ),
      );
    }

    if (candidates.length > 1) {
      return _ParentResolution(
        conflict: ImportConflict(
          rowNumber: row.rowNumber,
          reason: 'parent_ambiguous',
          candidates: candidates
              .map((candidate) => candidate.positionNumber)
              .toList(growable: false),
        ),
      );
    }

    return _ParentResolution(
      occurrence: occurrencesByRow[candidates.single.rowNumber],
    );
  }

  bool _isSkippedSpecialProcess(NormalizedImportRow row) {
    if (row.objectType == ImportObjectType.specialProcess) {
      return true;
    }

    const blockedNames = {'ХимОбработка', 'Литье'};
    return blockedNames.contains(row.name.trim()) ||
        blockedNames.contains(row.ownerName?.trim());
  }

  CatalogItemKind _mapCatalogKind(ImportObjectType objectType) {
    switch (objectType) {
      case ImportObjectType.machine:
        return CatalogItemKind.machine;
      case ImportObjectType.place:
        return CatalogItemKind.place;
      case ImportObjectType.node:
        return CatalogItemKind.node;
      case ImportObjectType.detail:
        return CatalogItemKind.detail;
      case ImportObjectType.material:
        return CatalogItemKind.material;
      case ImportObjectType.operation:
      case ImportObjectType.specialProcess:
        return CatalogItemKind.detail;
    }
  }
}

class _ParentResolution {
  const _ParentResolution({this.occurrence, this.conflict});

  const _ParentResolution.root() : occurrence = null, conflict = null;

  final StructureOccurrence? occurrence;
  final ImportConflict? conflict;
}
