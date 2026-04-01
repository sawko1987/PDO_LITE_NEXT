import 'package:data_models/data_models.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  test('health dto serializes to json', () {
    final dto = ServiceHealthDto(
      status: 'ok',
      service: 'backend',
      timestamp: DateTime.utc(2026, 3, 28, 10),
    );

    expect(dto.toJson()['status'], 'ok');
    expect(dto.toJson()['service'], 'backend');
  });

  test('list response wraps items and count', () {
    const dto = ApiListResponseDto(
      items: [
        MachineSummaryDto(
          id: 'machine-1',
          code: 'PDO-100',
          name: 'ПДО-100',
          activeVersionId: 'ver-1',
        ),
      ],
      meta: {'resource': 'machines'},
    );

    final json = dto.toJson((item) => item.toJson());

    expect(json['count'], 1);
    expect((json['items'] as List).single['code'], 'PDO-100');
    expect((json['meta'] as Map)['resource'], 'machines');
  });

  test('list response parses typed items from json', () {
    final dto = ApiListResponseDto<MachineSummaryDto>.fromJson({
      'items': [
        {
          'id': 'machine-1',
          'code': 'PDO-100',
          'name': 'Machine 100',
          'activeVersionId': 'ver-1',
        },
      ],
      'meta': {'resource': 'machines'},
    }, MachineSummaryDto.fromJson);

    expect(dto.items.single.code, 'PDO-100');
    expect(dto.meta['resource'], 'machines');
  });

  test('task dto exposes derived closed flag', () {
    final dto = TaskSummaryDto.fromDomain(
      const ProductionTask(
        id: 'task-1',
        planItemId: 'plan-item-1',
        operationOccurrenceId: 'op-1',
        requiredQuantity: 5,
        status: TaskStatus.completed,
      ),
    );

    expect(dto.isClosed, isTrue);
    expect(dto.toJson()['status'], 'completed');
  });

  test('task detail dto parses progress context', () {
    final dto = TaskDetailDto.fromJson({
      'id': 'task-1',
      'planItemId': 'plan-item-1',
      'operationOccurrenceId': 'op-1',
      'machineId': 'machine-1',
      'versionId': 'ver-2026-03',
      'structureOccurrenceId': 'occ-1',
      'structureDisplayName': 'Frame',
      'operationName': 'Cut',
      'workshop': 'WS-1',
      'requiredQuantity': 12,
      'reportedQuantity': 6,
      'remainingQuantity': 6,
      'assigneeId': 'master-1',
      'status': 'inProgress',
      'isClosed': false,
    });

    expect(dto.operationName, 'Cut');
    expect(dto.remainingQuantity, 6);
    expect(dto.isClosed, isFalse);
  });

  test('create execution report request serializes stable contract', () {
    const dto = CreateExecutionReportRequestDto(
      requestId: 'report-req-1',
      reportedBy: 'master-1',
      reportedQuantity: 2,
      outcome: 'partial',
      reason: 'Half shift completed',
    );

    final json = dto.toJson();

    expect(json['requestId'], 'report-req-1');
    expect(json['reportedBy'], 'master-1');
    expect(json['reportedQuantity'], 2);
    expect(json['outcome'], 'partial');
  });

  test('create execution report result parses nested report', () {
    final dto = CreateExecutionReportResultDto.fromJson({
      'report': {
        'id': 'report-1',
        'taskId': 'task-1',
        'reportedBy': 'master-1',
        'reportedAt': '2026-03-31T10:00:00.000Z',
        'reportedQuantity': 3,
        'outcome': 'partial',
        'reason': null,
        'acceptedAt': '2026-03-31T10:01:00.000Z',
        'isAccepted': true,
      },
      'taskStatus': 'inProgress',
      'reportedQuantityTotal': 3,
      'remainingQuantity': 9,
      'outboxStatus': 'sent',
      'wipEffect': {
        'type': 'created',
        'wipEntryId': 'wip-2',
        'balanceQuantity': 9,
        'status': 'open',
      },
    });

    expect(dto.report.id, 'report-1');
    expect(dto.report.outcome, 'partial');
    expect(dto.taskStatus, 'inProgress');
    expect(dto.remainingQuantity, 9);
    expect(dto.wipEffect?.type, 'created');
    expect(dto.wipEffect?.wipEntryId, 'wip-2');
  });

  test('problem summary dto parses type and message count', () {
    final dto = ProblemSummaryDto.fromJson({
      'id': 'problem-1',
      'machineId': 'machine-1',
      'taskId': 'task-1',
      'title': 'Missing fixture',
      'type': 'equipment',
      'status': 'open',
      'isOpen': true,
      'createdAt': '2026-04-01T08:00:00.000Z',
      'messageCount': 2,
    });

    expect(dto.type, 'equipment');
    expect(dto.messageCount, 2);
  });

  test('problem detail dto parses nested messages', () {
    final dto = ProblemDetailDto.fromJson({
      'id': 'problem-1',
      'machineId': 'machine-1',
      'taskId': 'task-1',
      'title': 'Fixture issue',
      'type': 'equipment',
      'status': 'inProgress',
      'isOpen': true,
      'createdAt': '2026-04-01T08:00:00.000Z',
      'messages': [
        {
          'id': 'message-1',
          'problemId': 'problem-1',
          'authorId': 'master-1',
          'message': 'Need replacement fixture',
          'createdAt': '2026-04-01T08:05:00.000Z',
        },
      ],
    });

    expect(dto.messages.single.authorId, 'master-1');
    expect(dto.messages.single.message, contains('fixture'));
  });

  test('problem request dto serializes stable contracts', () {
    const createDto = CreateProblemRequestDto(
      requestId: 'problem-create-1',
      createdBy: 'master-1',
      type: 'equipment',
      title: 'Fixture issue',
      description: 'Machine cannot proceed.',
    );
    const messageDto = AddProblemMessageRequestDto(
      requestId: 'problem-message-1',
      authorId: 'master-1',
      message: 'Still waiting for support.',
    );
    const transitionDto = TransitionProblemRequestDto(
      requestId: 'problem-transition-1',
      changedBy: 'master-1',
      toStatus: 'closed',
    );

    expect(createDto.toJson()['type'], 'equipment');
    expect(messageDto.toJson()['message'], contains('waiting'));
    expect(transitionDto.toJson()['toStatus'], 'closed');
  });

  test('completion dto contracts serialize and parse block blockers', () {
    const requestDto = CompletePlanRequestDto(
      requestId: 'complete-plan-1',
      completedBy: 'supervisor-1',
    );
    const blockerDto = CompletionBlockerDto(
      type: 'openTasks',
      entityIds: ['task-1', 'task-2'],
    );
    const resultDto = PlanCompletionResultDto(
      planId: 'plan-1',
      status: 'completed',
    );

    final decisionDto = PlanCompletionDecisionDto.fromJson({
      'planId': 'plan-1',
      'canComplete': false,
      'blockers': [
        blockerDto.toJson(),
        {
          'type': 'openProblems',
          'entityIds': ['problem-1'],
        },
      ],
    });

    expect(requestDto.toJson()['completedBy'], 'supervisor-1');
    expect(decisionDto.planId, 'plan-1');
    expect(decisionDto.canComplete, isFalse);
    expect(decisionDto.blockers.first.entityIds, ['task-1', 'task-2']);
    expect(resultDto.toJson()['status'], 'completed');
  });

  test('api error dto nests error payload', () {
    const dto = ApiErrorDto(
      code: 'machine_not_found',
      message: 'Machine was not found.',
      details: {'machineId': 'missing'},
    );

    final json = dto.toJson();

    expect((json['error'] as Map)['code'], 'machine_not_found');
    expect(((json['error'] as Map)['details'] as Map)['machineId'], 'missing');
  });

  test('api error dto parses nested error payload', () {
    final dto = ApiErrorDto.fromJson({
      'error': {
        'code': 'machine_not_found',
        'message': 'Machine was not found.',
        'details': {'machineId': 'missing'},
      },
    });

    expect(dto.code, 'machine_not_found');
    expect(dto.details['machineId'], 'missing');
  });

  test('create import preview request parses json contract', () {
    final dto = CreateImportPreviewRequestDto.fromJson({
      'requestId': 'preview-1',
      'fileName': 'machine.xlsx',
      'fileContentBase64': 'ZmFrZQ==',
    });

    expect(dto.requestId, 'preview-1');
    expect(dto.fileName, 'machine.xlsx');
    expect(dto.toJson()['fileContentBase64'], 'ZmFrZQ==');
  });

  test('confirm import result serializes stable contract', () {
    const dto = ConfirmImportResultDto(
      sessionId: 'import-session-1',
      status: 'confirmed',
      mode: 'create_machine',
      machineId: 'machine-2',
      versionId: 'ver-import-3',
      versionLabel: 'import-import-session-1',
    );

    final json = dto.toJson();

    expect(json['sessionId'], 'import-session-1');
    expect(json['mode'], 'create_machine');
    expect(json['versionId'], 'ver-import-3');
  });

  test('confirm import result parses json contract', () {
    final dto = ConfirmImportResultDto.fromJson({
      'sessionId': 'import-session-1',
      'status': 'confirmed',
      'mode': 'create_version',
      'machineId': 'machine-2',
      'versionId': 'ver-import-3',
      'versionLabel': 'import-import-session-1',
    });

    expect(dto.mode, 'create_version');
    expect(dto.machineId, 'machine-2');
  });

  test('import session preview serializes nested conflicts and warnings', () {
    final dto = ImportSessionSummaryDto(
      sessionId: 'import-session-1',
      status: 'preview_ready',
      createdAt: DateTime.utc(2026, 3, 30, 9),
      preview: ImportPreviewDto(
        fileName: 'machine.mxl',
        sourceFormat: 'mxl',
        detectionReason: 'xml_workbook_signature',
        rowCount: 3,
        canConfirm: false,
        catalogItemCount: 2,
        structureOccurrenceCount: 2,
        operationOccurrenceCount: 0,
        conflictCount: 1,
        warningCount: 1,
        machineName: 'Machine 200',
        machineCode: 'PDO-200',
        conflicts: [
          ImportConflictDto(rowNumber: 3, reason: 'parent_ambiguous'),
        ],
        warnings: [
          ImportWarningDto(
            code: 'duplicate_position_number',
            message: 'Duplicate position number.',
            rowNumber: 2,
          ),
        ],
        structureOccurrences: [
          StructureOccurrencePreviewDto(
            id: 'occ-1',
            catalogItemId: 'catalog-1',
            pathKey: 'root/10:PLACE-1',
            displayName: 'Place 1',
            quantityPerMachine: 1,
            inheritedWorkshop: false,
          ),
        ],
        operationOccurrences: [],
      ),
    );

    final json = dto.toJson();

    expect(json['sessionId'], 'import-session-1');
    expect((json['preview'] as Map<String, Object?>)['rowCount'], 3);
    expect(
      ((json['preview'] as Map<String, Object?>)['conflicts'] as List).length,
      1,
    );
  });

  test('import session preview parses nested conflicts and warnings', () {
    final dto = ImportSessionSummaryDto.fromJson({
      'sessionId': 'import-session-1',
      'status': 'preview_ready',
      'createdAt': '2026-03-30T09:00:00.000Z',
      'confirmedAt': null,
      'preview': {
        'fileName': 'machine.mxl',
        'sourceFormat': 'mxl',
        'detectionReason': 'xml_workbook_signature',
        'rowCount': 3,
        'canConfirm': false,
        'catalogItemCount': 2,
        'structureOccurrenceCount': 2,
        'operationOccurrenceCount': 1,
        'conflictCount': 1,
        'warningCount': 1,
        'machineName': 'Machine 200',
        'machineCode': 'PDO-200',
        'conflicts': [
          {
            'rowNumber': 3,
            'reason': 'parent_ambiguous',
            'candidates': ['A', 'B'],
          },
        ],
        'warnings': [
          {
            'code': 'duplicate_position_number',
            'message': 'Duplicate position number.',
            'rowNumber': 2,
          },
        ],
        'structureOccurrences': [
          {
            'id': 'occ-1',
            'catalogItemId': 'catalog-1',
            'pathKey': 'root/10:PLACE-1',
            'displayName': 'Place 1',
            'quantityPerMachine': 1,
            'parentOccurrenceId': null,
            'workshop': null,
            'inheritedWorkshop': false,
            'sourcePositionNumber': null,
            'sourceOwnerName': null,
          },
        ],
        'operationOccurrences': [
          {
            'id': 'op-1',
            'structureOccurrenceId': 'occ-1',
            'name': 'Cut',
            'quantityPerMachine': 2,
            'workshop': 'WS-1',
            'inheritedWorkshop': false,
            'sourcePositionNumber': '10',
            'sourceQuantity': 2,
          },
        ],
      },
    });

    expect(dto.preview.conflicts.single.candidates, ['A', 'B']);
    expect(dto.preview.operationOccurrences.single.name, 'Cut');
    expect(dto.preview.canConfirm, isFalse);
  });
}
