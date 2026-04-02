import 'package:admin_windows/src/import/admin_backend_client.dart';
import 'package:admin_windows/src/structure/structure_editor_controller.dart';
import 'package:data_models/data_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StructureEditorController', () {
    test(
      'creates editable draft from published version and publishes it',
      () async {
        final client = _FakeStructureBackendClient();
        final controller = StructureEditorController(client: client);

        await controller.bootstrap();

        expect(controller.selectedVersion?.id, 'ver-1');
        expect(controller.versionDetail?.isImmutable, isTrue);

        await controller.createDraftFromCurrentVersion();

        expect(controller.selectedVersion?.status, 'draft');
        expect(controller.versionDetail?.isImmutable, isFalse);
        expect(controller.versionDetail?.id, startsWith('ver-draft-'));

        final published = await controller.publishCurrentVersion();

        expect(published, isNotNull);
        expect(controller.versionDetail?.isImmutable, isTrue);
        expect(
          controller.selectedMachine?.activeVersionId,
          controller.selectedVersionId,
        );
      },
    );

    test(
      'supports structure and operation CRUD inside draft version',
      () async {
        final client = _FakeStructureBackendClient();
        final controller = StructureEditorController(client: client);

        await controller.bootstrap();
        await controller.createDraftFromCurrentVersion();

        final initialStructureCount =
            controller.versionDetail!.structureOccurrences.length;
        final initialOperationCount =
            controller.versionDetail!.operationOccurrences.length;

        await controller.addStructureOccurrence(
          displayName: 'Clamp',
          quantityPerMachine: '2',
          workshop: 'WS-3',
          parentOccurrenceId: controller.selectedOccurrenceId,
        );

        expect(
          controller.versionDetail!.structureOccurrences.length,
          initialStructureCount + 1,
        );
        expect(
          controller.versionDetail!.structureOccurrences.any(
            (item) => item.displayName == 'Clamp',
          ),
          isTrue,
        );

        final createdOccurrence = controller.versionDetail!.structureOccurrences
            .firstWhere((item) => item.displayName == 'Clamp');
        controller.selectOccurrence(createdOccurrence.id);

        await controller.updateSelectedOccurrence(
          displayName: 'Clamp Updated',
          quantityPerMachine: '3',
          workshop: 'WS-4',
        );

        expect(controller.selectedOccurrence?.displayName, 'Clamp Updated');
        expect(controller.selectedOccurrence?.quantityPerMachine, 3);
        expect(controller.selectedOccurrence?.workshop, 'WS-4');

        await controller.addOperation(
          name: 'Assemble',
          quantityPerMachine: '1',
          workshop: 'WS-4',
        );

        expect(
          controller.versionDetail!.operationOccurrences.length,
          initialOperationCount + 1,
        );
        expect(controller.selectedOccurrenceOperations.single.name, 'Assemble');

        final operationId = controller.selectedOccurrenceOperations.single.id;
        controller.selectOperation(operationId);

        await controller.updateSelectedOperation(
          name: 'Assemble Updated',
          quantityPerMachine: '2',
          workshop: 'WS-5',
        );

        expect(controller.selectedOperation?.name, 'Assemble Updated');
        expect(controller.selectedOperation?.quantityPerMachine, 2);
        expect(controller.selectedOperation?.workshop, 'WS-5');

        await controller.deleteSelectedOperation();
        expect(controller.selectedOccurrenceOperations, isEmpty);

        await controller.deleteSelectedOccurrence();
        expect(
          controller.versionDetail!.structureOccurrences.any(
            (item) => item.displayName == 'Clamp Updated',
          ),
          isFalse,
        );
      },
    );
  });
}

class _FakeStructureBackendClient implements AdminBackendClient {
  final List<MachineSummaryDto> _machines = [
    const MachineSummaryDto(
      id: 'machine-1',
      code: 'PDO-100',
      name: 'Machine 100',
      activeVersionId: 'ver-1',
    ),
  ];

  final Map<String, List<MachineVersionSummaryDto>> _versionsByMachine = {
    'machine-1': [
      MachineVersionSummaryDto(
        id: 'ver-1',
        machineId: 'machine-1',
        label: 'v1',
        createdAt: DateTime.utc(2026, 4, 1),
        status: 'published',
        isImmutable: true,
      ),
    ],
  };

  final Map<String, MachineVersionDetailDto> _detailsByVersion = {
    'ver-1': MachineVersionDetailDto(
      id: 'ver-1',
      machineId: 'machine-1',
      label: 'v1',
      createdAt: DateTime.utc(2026, 4, 1),
      status: 'published',
      isImmutable: true,
      isActiveVersion: true,
      structureOccurrences: const [
        StructureOccurrenceDetailDto(
          id: 'occ-1',
          versionId: 'ver-1',
          catalogItemId: 'catalog-1',
          displayName: 'Frame',
          pathKey: 'machine/frame',
          quantityPerMachine: 1,
          workshop: 'WS-1',
        ),
      ],
      operationOccurrences: const [
        OperationOccurrenceDetailDto(
          id: 'op-1',
          versionId: 'ver-1',
          structureOccurrenceId: 'occ-1',
          name: 'Cut',
          quantityPerMachine: 1,
          workshop: 'WS-1',
        ),
      ],
    ),
  };

  int _draftSequence = 0;
  int _occurrenceSequence = 1;
  int _operationSequence = 1;

  @override
  Future<ApiListResponseDto<MachineSummaryDto>> listMachines() async {
    return ApiListResponseDto(
      items: List<MachineSummaryDto>.unmodifiable(_machines),
      meta: const {'resource': 'machines'},
    );
  }

  @override
  Future<ApiListResponseDto<MachineVersionSummaryDto>> listMachineVersions(
    String machineId,
  ) async {
    return ApiListResponseDto(
      items: List<MachineVersionSummaryDto>.unmodifiable(
        _versionsByMachine[machineId] ?? const [],
      ),
      meta: const {'resource': 'machine_versions'},
    );
  }

  @override
  Future<MachineVersionDetailDto> getMachineVersionDetail(
    String machineId,
    String versionId,
  ) async {
    return _detailsByVersion[versionId]!;
  }

  @override
  Future<MachineVersionDetailDto> createDraftMachineVersion(
    String machineId,
    String versionId,
    CreateDraftMachineVersionRequestDto request,
  ) async {
    _draftSequence += 1;
    final source = _detailsByVersion[versionId]!;
    final draftId = 'ver-draft-$_draftSequence';
    final occurrenceIds = <String, String>{};
    for (final occurrence in source.structureOccurrences) {
      _occurrenceSequence += 1;
      occurrenceIds[occurrence.id] = 'occ-$_occurrenceSequence';
    }

    final draft = MachineVersionDetailDto(
      id: draftId,
      machineId: machineId,
      label: '${source.label}-draft',
      createdAt: DateTime.utc(2026, 4, 2),
      status: 'draft',
      isImmutable: false,
      isActiveVersion: false,
      structureOccurrences: source.structureOccurrences
          .map(
            (occurrence) => StructureOccurrenceDetailDto(
              id: occurrenceIds[occurrence.id]!,
              versionId: draftId,
              catalogItemId: occurrence.catalogItemId,
              displayName: occurrence.displayName,
              pathKey: occurrence.pathKey,
              quantityPerMachine: occurrence.quantityPerMachine,
              parentOccurrenceId: occurrence.parentOccurrenceId == null
                  ? null
                  : occurrenceIds[occurrence.parentOccurrenceId!],
              workshop: occurrence.workshop,
            ),
          )
          .toList(growable: false),
      operationOccurrences: source.operationOccurrences
          .map((operation) {
            _operationSequence += 1;
            return OperationOccurrenceDetailDto(
              id: 'op-$_operationSequence',
              versionId: draftId,
              structureOccurrenceId:
                  occurrenceIds[operation.structureOccurrenceId]!,
              name: operation.name,
              quantityPerMachine: operation.quantityPerMachine,
              workshop: operation.workshop,
            );
          })
          .toList(growable: false),
    );

    _detailsByVersion[draftId] = draft;
    _versionsByMachine[machineId] = [
      ..._versionsByMachine[machineId]!,
      MachineVersionSummaryDto(
        id: draftId,
        machineId: machineId,
        label: draft.label,
        createdAt: draft.createdAt,
        status: 'draft',
        isImmutable: false,
      ),
    ];
    return draft;
  }

  @override
  Future<MachineVersionDetailDto> createStructureOccurrence(
    String machineId,
    String versionId,
    CreateStructureOccurrenceRequestDto request,
  ) async {
    final detail = _detailsByVersion[versionId]!;
    _occurrenceSequence += 1;
    final occurrenceId = 'occ-$_occurrenceSequence';
    final parent = request.parentOccurrenceId == null
        ? null
        : detail.structureOccurrences.firstWhere(
            (item) => item.id == request.parentOccurrenceId,
          );
    final segment = request.displayName.toLowerCase().replaceAll(' ', '-');
    final pathKey = parent == null
        ? 'machine/$segment'
        : '${parent.pathKey}/$segment';
    final updated = MachineVersionDetailDto(
      id: detail.id,
      machineId: detail.machineId,
      label: detail.label,
      createdAt: detail.createdAt,
      status: detail.status,
      isImmutable: detail.isImmutable,
      isActiveVersion: detail.isActiveVersion,
      structureOccurrences: [
        ...detail.structureOccurrences,
        StructureOccurrenceDetailDto(
          id: occurrenceId,
          versionId: versionId,
          catalogItemId: 'catalog-$occurrenceId',
          displayName: request.displayName,
          pathKey: pathKey,
          quantityPerMachine: request.quantityPerMachine,
          parentOccurrenceId: request.parentOccurrenceId,
          workshop: request.workshop,
        ),
      ],
      operationOccurrences: detail.operationOccurrences,
    );
    _detailsByVersion[versionId] = updated;
    return updated;
  }

  @override
  Future<MachineVersionDetailDto> updateStructureOccurrence(
    String machineId,
    String versionId,
    String occurrenceId,
    UpdateStructureOccurrenceRequestDto request,
  ) async {
    final detail = _detailsByVersion[versionId]!;
    final updated = MachineVersionDetailDto(
      id: detail.id,
      machineId: detail.machineId,
      label: detail.label,
      createdAt: detail.createdAt,
      status: detail.status,
      isImmutable: detail.isImmutable,
      isActiveVersion: detail.isActiveVersion,
      structureOccurrences: detail.structureOccurrences
          .map(
            (item) => item.id != occurrenceId
                ? item
                : StructureOccurrenceDetailDto(
                    id: item.id,
                    versionId: item.versionId,
                    catalogItemId: item.catalogItemId,
                    displayName: request.displayName,
                    pathKey: item.pathKey,
                    quantityPerMachine: request.quantityPerMachine,
                    parentOccurrenceId: item.parentOccurrenceId,
                    workshop: request.workshop,
                  ),
          )
          .toList(growable: false),
      operationOccurrences: detail.operationOccurrences,
    );
    _detailsByVersion[versionId] = updated;
    return updated;
  }

  @override
  Future<MachineVersionDetailDto> deleteStructureOccurrence(
    String machineId,
    String versionId,
    String occurrenceId,
    DeleteStructureOccurrenceRequestDto request,
  ) async {
    final detail = _detailsByVersion[versionId]!;
    final updated = MachineVersionDetailDto(
      id: detail.id,
      machineId: detail.machineId,
      label: detail.label,
      createdAt: detail.createdAt,
      status: detail.status,
      isImmutable: detail.isImmutable,
      isActiveVersion: detail.isActiveVersion,
      structureOccurrences: detail.structureOccurrences
          .where((item) => item.id != occurrenceId)
          .toList(growable: false),
      operationOccurrences: detail.operationOccurrences
          .where((item) => item.structureOccurrenceId != occurrenceId)
          .toList(growable: false),
    );
    _detailsByVersion[versionId] = updated;
    return updated;
  }

  @override
  Future<MachineVersionDetailDto> createOperationOccurrence(
    String machineId,
    String versionId,
    CreateOperationOccurrenceRequestDto request,
  ) async {
    final detail = _detailsByVersion[versionId]!;
    _operationSequence += 1;
    final updated = MachineVersionDetailDto(
      id: detail.id,
      machineId: detail.machineId,
      label: detail.label,
      createdAt: detail.createdAt,
      status: detail.status,
      isImmutable: detail.isImmutable,
      isActiveVersion: detail.isActiveVersion,
      structureOccurrences: detail.structureOccurrences,
      operationOccurrences: [
        ...detail.operationOccurrences,
        OperationOccurrenceDetailDto(
          id: 'op-$_operationSequence',
          versionId: versionId,
          structureOccurrenceId: request.structureOccurrenceId,
          name: request.name,
          quantityPerMachine: request.quantityPerMachine,
          workshop: request.workshop,
        ),
      ],
    );
    _detailsByVersion[versionId] = updated;
    return updated;
  }

  @override
  Future<MachineVersionDetailDto> updateOperationOccurrence(
    String machineId,
    String versionId,
    String operationId,
    UpdateOperationOccurrenceRequestDto request,
  ) async {
    final detail = _detailsByVersion[versionId]!;
    final updated = MachineVersionDetailDto(
      id: detail.id,
      machineId: detail.machineId,
      label: detail.label,
      createdAt: detail.createdAt,
      status: detail.status,
      isImmutable: detail.isImmutable,
      isActiveVersion: detail.isActiveVersion,
      structureOccurrences: detail.structureOccurrences,
      operationOccurrences: detail.operationOccurrences
          .map(
            (item) => item.id != operationId
                ? item
                : OperationOccurrenceDetailDto(
                    id: item.id,
                    versionId: item.versionId,
                    structureOccurrenceId: item.structureOccurrenceId,
                    name: request.name,
                    quantityPerMachine: request.quantityPerMachine,
                    workshop: request.workshop,
                  ),
          )
          .toList(growable: false),
    );
    _detailsByVersion[versionId] = updated;
    return updated;
  }

  @override
  Future<MachineVersionDetailDto> deleteOperationOccurrence(
    String machineId,
    String versionId,
    String operationId,
    DeleteOperationOccurrenceRequestDto request,
  ) async {
    final detail = _detailsByVersion[versionId]!;
    final updated = MachineVersionDetailDto(
      id: detail.id,
      machineId: detail.machineId,
      label: detail.label,
      createdAt: detail.createdAt,
      status: detail.status,
      isImmutable: detail.isImmutable,
      isActiveVersion: detail.isActiveVersion,
      structureOccurrences: detail.structureOccurrences,
      operationOccurrences: detail.operationOccurrences
          .where((item) => item.id != operationId)
          .toList(growable: false),
    );
    _detailsByVersion[versionId] = updated;
    return updated;
  }

  @override
  Future<MachineVersionDetailDto> publishMachineVersion(
    String machineId,
    String versionId,
    PublishMachineVersionRequestDto request,
  ) async {
    final detail = _detailsByVersion[versionId]!;
    final published = MachineVersionDetailDto(
      id: detail.id,
      machineId: detail.machineId,
      label: detail.label,
      createdAt: detail.createdAt,
      status: 'published',
      isImmutable: true,
      isActiveVersion: true,
      structureOccurrences: detail.structureOccurrences,
      operationOccurrences: detail.operationOccurrences,
    );
    _detailsByVersion[versionId] = published;
    _versionsByMachine[machineId] = _versionsByMachine[machineId]!
        .map(
          (item) => MachineVersionSummaryDto(
            id: item.id,
            machineId: item.machineId,
            label: item.label,
            createdAt: item.createdAt,
            status: item.id == versionId ? 'published' : item.status,
            isImmutable: item.id == versionId ? true : item.isImmutable,
          ),
        )
        .toList(growable: false);
    _machines[0] = MachineSummaryDto(
      id: _machines[0].id,
      code: _machines[0].code,
      name: _machines[0].name,
      activeVersionId: versionId,
    );
    return published;
  }

  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
