import 'dart:convert';
import 'dart:io';

import 'package:backend/backend.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  test('health endpoint returns ok', () async {
    final handler = buildHandler();
    final response = await handler(
      Request('GET', Uri.parse('http://localhost/health')),
    );
    final body =
        jsonDecode(await response.readAsString()) as Map<String, dynamic>;

    expect(response.statusCode, 200);
    expect(body['status'], 'ok');
  });

  test('machines endpoint returns contract list response', () async {
    final handler = buildHandler();
    final response = await handler(
      Request('GET', Uri.parse('http://localhost/v1/machines')),
    );
    final body =
        jsonDecode(await response.readAsString()) as Map<String, dynamic>;

    expect(response.statusCode, 200);
    expect(body['count'], 1);
    expect((body['items'] as List).single['code'], 'PDO-100');
    expect((body['meta'] as Map<String, dynamic>)['resource'], 'machines');
  });

  test('machine versions endpoint returns immutable flag', () async {
    final handler = buildHandler();
    final response = await handler(
      Request(
        'GET',
        Uri.parse('http://localhost/v1/machines/machine-1/versions'),
      ),
    );
    final body =
        jsonDecode(await response.readAsString()) as Map<String, dynamic>;

    expect(response.statusCode, 200);
    expect(body['count'], 2);
    expect((body['items'] as List).first['isImmutable'], isTrue);
  });

  test(
    'planning source endpoint returns occurrences for selected version',
    () async {
      final handler = buildHandler();
      final response = await handler(
        Request(
          'GET',
          Uri.parse(
            'http://localhost/v1/machines/machine-1/versions/ver-2026-03/planning-source',
          ),
        ),
      );
      final body =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;

      expect(response.statusCode, 200);
      expect(body['count'], 2);
      expect((body['items'] as List).first['displayName'], 'Frame');
      expect((body['items'] as List).last['operationCount'], 2);
    },
  );

  test(
    'machine version detail endpoint returns nested editable payload',
    () async {
      final handler = buildHandler();
      final response = await handler(
        Request(
          'GET',
          Uri.parse(
            'http://localhost/v1/machines/machine-1/versions/ver-2026-04-draft/detail',
          ),
        ),
      );
      final body =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;

      expect(response.statusCode, 200);
      expect(body['status'], 'draft');
      expect(body['isImmutable'], isFalse);
      expect(
        (body['structureOccurrences'] as List).single['displayName'],
        'Draft Kit',
      );
      expect((body['operationOccurrences'] as List).single['name'], 'Draft Op');
    },
  );

  test('draft structure endpoints create update delete and publish version', () async {
    final handler = buildHandler();

    final draftResponse = await handler(
      _jsonRequest(
        'POST',
        'http://localhost/v1/machines/machine-1/versions/ver-2026-03/draft',
        {'requestId': 'structure-draft-1', 'createdBy': 'planner-1'},
      ),
    );
    final draftBody =
        jsonDecode(await draftResponse.readAsString()) as Map<String, dynamic>;
    final draftVersionId = draftBody['id'] as String;
    final draftOccurrences = draftBody['structureOccurrences'] as List<dynamic>;
    final rootOccurrenceId =
        (draftOccurrences.first as Map<String, dynamic>)['id'] as String;

    expect(draftResponse.statusCode, 201);
    expect(draftBody['status'], 'draft');
    expect(draftBody['isImmutable'], isFalse);

    final createStructureResponse = await handler(
      _jsonRequest(
        'POST',
        'http://localhost/v1/machines/machine-1/versions/$draftVersionId/structure-occurrences',
        {
          'requestId': 'structure-create-1',
          'parentOccurrenceId': rootOccurrenceId,
          'displayName': 'Clamp',
          'quantityPerMachine': 2,
          'workshop': 'WS-4',
        },
      ),
    );
    final createdStructureBody =
        jsonDecode(await createStructureResponse.readAsString())
            as Map<String, dynamic>;
    final createdOccurrence =
        (createdStructureBody['structureOccurrences'] as List)
            .map((item) => item as Map<String, dynamic>)
            .firstWhere((item) => item['displayName'] == 'Clamp');
    final createdOccurrenceId = createdOccurrence['id'] as String;

    expect(createStructureResponse.statusCode, 201);
    expect(createdOccurrence['workshop'], 'WS-4');

    final updateStructureResponse = await handler(
      _jsonRequest(
        'POST',
        'http://localhost/v1/machines/machine-1/versions/$draftVersionId/structure-occurrences/$createdOccurrenceId/update',
        {
          'requestId': 'structure-update-1',
          'displayName': 'Clamp Updated',
          'quantityPerMachine': 3,
          'workshop': 'WS-5',
        },
      ),
    );
    final updatedStructureBody =
        jsonDecode(await updateStructureResponse.readAsString())
            as Map<String, dynamic>;
    final updatedOccurrence =
        (updatedStructureBody['structureOccurrences'] as List)
            .map((item) => item as Map<String, dynamic>)
            .firstWhere((item) => item['id'] == createdOccurrenceId);

    expect(updateStructureResponse.statusCode, 200);
    expect(updatedOccurrence['displayName'], 'Clamp Updated');
    expect(updatedOccurrence['quantityPerMachine'], 3);

    final createOperationResponse = await handler(
      _jsonRequest(
        'POST',
        'http://localhost/v1/machines/machine-1/versions/$draftVersionId/operation-occurrences',
        {
          'requestId': 'operation-create-1',
          'structureOccurrenceId': createdOccurrenceId,
          'name': 'Assemble',
          'quantityPerMachine': 1,
          'workshop': 'WS-5',
        },
      ),
    );
    final createdOperationBody =
        jsonDecode(await createOperationResponse.readAsString())
            as Map<String, dynamic>;
    final createdOperation =
        (createdOperationBody['operationOccurrences'] as List)
            .map((item) => item as Map<String, dynamic>)
            .firstWhere((item) => item['name'] == 'Assemble');
    final createdOperationId = createdOperation['id'] as String;

    expect(createOperationResponse.statusCode, 201);
    expect(createdOperation['structureOccurrenceId'], createdOccurrenceId);

    final deleteOperationResponse = await handler(
      _jsonRequest(
        'POST',
        'http://localhost/v1/machines/machine-1/versions/$draftVersionId/operation-occurrences/$createdOperationId/delete',
        {'requestId': 'operation-delete-1'},
      ),
    );
    final deleteOperationBody =
        jsonDecode(await deleteOperationResponse.readAsString())
            as Map<String, dynamic>;
    expect(deleteOperationResponse.statusCode, 200);
    expect(
      (deleteOperationBody['operationOccurrences'] as List).where(
        (item) => (item as Map<String, dynamic>)['id'] == createdOperationId,
      ),
      isEmpty,
    );

    final deleteStructureResponse = await handler(
      _jsonRequest(
        'POST',
        'http://localhost/v1/machines/machine-1/versions/$draftVersionId/structure-occurrences/$createdOccurrenceId/delete',
        {'requestId': 'structure-delete-1'},
      ),
    );
    final deleteStructureBody =
        jsonDecode(await deleteStructureResponse.readAsString())
            as Map<String, dynamic>;
    expect(deleteStructureResponse.statusCode, 200);
    expect(
      (deleteStructureBody['structureOccurrences'] as List).where(
        (item) => (item as Map<String, dynamic>)['id'] == createdOccurrenceId,
      ),
      isEmpty,
    );

    final publishResponse = await handler(
      _jsonRequest(
        'POST',
        'http://localhost/v1/machines/machine-1/versions/$draftVersionId/publish',
        {'requestId': 'publish-1', 'publishedBy': 'planner-1'},
      ),
    );
    final publishBody =
        jsonDecode(await publishResponse.readAsString())
            as Map<String, dynamic>;

    expect(publishResponse.statusCode, 200);
    expect(publishBody['status'], 'published');
    expect(publishBody['isImmutable'], isTrue);

    final machinesResponse = await handler(
      Request('GET', Uri.parse('http://localhost/v1/machines')),
    );
    final machinesBody =
        jsonDecode(await machinesResponse.readAsString())
            as Map<String, dynamic>;
    final machine =
        (machinesBody['items'] as List).single as Map<String, dynamic>;
    expect(machine['activeVersionId'], draftVersionId);
  });

  test('unknown machine returns error envelope', () async {
    final handler = buildHandler();
    final response = await handler(
      Request(
        'GET',
        Uri.parse('http://localhost/v1/machines/missing/versions'),
      ),
    );
    final body =
        jsonDecode(await response.readAsString()) as Map<String, dynamic>;

    expect(response.statusCode, 404);
    expect(
      (body['error'] as Map<String, dynamic>)['code'],
      'machine_not_found',
    );
  });

  test('task reports endpoint returns execution history', () async {
    final handler = buildHandler();
    final response = await handler(
      Request('GET', Uri.parse('http://localhost/v1/tasks/task-1/reports')),
    );
    final body =
        jsonDecode(await response.readAsString()) as Map<String, dynamic>;

    expect(response.statusCode, 200);
    expect(body['count'], 1);
    expect((body['items'] as List).single['isAccepted'], isTrue);
    expect((body['items'] as List).single['outcome'], 'partial');
  });

  test(
    'tasks endpoint supports assignee filter and returns execution context',
    () async {
      final handler = buildHandler();
      final response = await handler(
        Request(
          'GET',
          Uri.parse('http://localhost/v1/tasks?assigneeId=master-1'),
        ),
      );
      final body =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;

      expect(response.statusCode, 200);
      expect(body['count'], 1);
      final item = (body['items'] as List).single as Map<String, dynamic>;
      expect(item['assigneeId'], 'master-1');
      expect(item['machineId'], 'machine-1');
      expect(item['versionId'], 'ver-2026-03');
      expect(item['structureDisplayName'], 'Frame');
      expect(item['operationName'], 'Cut');
      expect(item['reportedQuantity'], 6);
      expect(item['remainingQuantity'], 6);
    },
  );

  test(
    'tasks endpoint status filter still works for enriched task summaries',
    () async {
      final handler = buildHandler();
      final response = await handler(
        Request('GET', Uri.parse('http://localhost/v1/tasks?status=pending')),
      );
      final body =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;

      expect(response.statusCode, 200);
      expect(body['count'], 1);
      expect((body['items'] as List).single['id'], 'task-2');
    },
  );

  test('task detail endpoint returns planning context and progress', () async {
    final handler = buildHandler();
    final response = await handler(
      Request('GET', Uri.parse('http://localhost/v1/tasks/task-1')),
    );
    final body =
        jsonDecode(await response.readAsString()) as Map<String, dynamic>;

    expect(response.statusCode, 200);
    expect(body['structureDisplayName'], 'Frame');
    expect(body['operationName'], 'Cut');
    expect(body['reportedQuantity'], 6);
    expect(body['remainingQuantity'], 6);
  });

  test('create execution report updates task progress', () async {
    final handler = buildHandler();
    final response = await handler(
      _jsonRequest('POST', 'http://localhost/v1/tasks/task-1/reports', {
        'requestId': 'report-task-1',
        'reportedBy': 'master-1',
        'reportedQuantity': 3,
        'outcome': 'partial',
        'reason': 'Need rework on the remaining pieces.',
      }),
    );
    final body =
        jsonDecode(await response.readAsString()) as Map<String, dynamic>;

    final detailResponse = await handler(
      Request('GET', Uri.parse('http://localhost/v1/tasks/task-1')),
    );
    final detailBody =
        jsonDecode(await detailResponse.readAsString()) as Map<String, dynamic>;

    expect(response.statusCode, 201);
    expect(body['taskStatus'], 'inProgress');
    expect(body['reportedQuantityTotal'], 9);
    expect((body['wipEffect'] as Map<String, dynamic>)['type'], 'updated');
    expect(detailBody['remainingQuantity'], 3);
  });

  test(
    'create execution report completes task when required quantity is met',
    () async {
      final handler = buildHandler();
      final response = await handler(
        _jsonRequest('POST', 'http://localhost/v1/tasks/task-1/reports', {
          'requestId': 'report-task-complete',
          'reportedBy': 'master-1',
          'reportedQuantity': 6,
          'outcome': 'completed',
        }),
      );
      final body =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;

      expect(response.statusCode, 201);
      expect(body['taskStatus'], 'completed');
      expect(body['remainingQuantity'], 0);
      expect((body['wipEffect'] as Map<String, dynamic>)['type'], 'consumed');
    },
  );

  test(
    'create execution report is idempotent for repeated requestId and payload',
    () async {
      final handler = buildHandler();
      final first = await handler(
        _jsonRequest('POST', 'http://localhost/v1/tasks/task-1/reports', {
          'requestId': 'report-task-idempotent',
          'reportedBy': 'master-1',
          'reportedQuantity': 2,
          'outcome': 'partial',
          'reason': 'Paused for inspection.',
        }),
      );
      final second = await handler(
        _jsonRequest('POST', 'http://localhost/v1/tasks/task-1/reports', {
          'requestId': 'report-task-idempotent',
          'reportedBy': 'master-1',
          'reportedQuantity': 2,
          'outcome': 'partial',
          'reason': 'Paused for inspection.',
        }),
      );

      final firstBody =
          jsonDecode(await first.readAsString()) as Map<String, dynamic>;
      final secondBody =
          jsonDecode(await second.readAsString()) as Map<String, dynamic>;

      expect(first.statusCode, 201);
      expect(second.statusCode, 201);
      expect(
        (firstBody['report'] as Map<String, dynamic>)['id'],
        (secondBody['report'] as Map<String, dynamic>)['id'],
      );
    },
  );

  test(
    'create execution report rejects same requestId with different payload',
    () async {
      final handler = buildHandler();
      final first = await handler(
        _jsonRequest('POST', 'http://localhost/v1/tasks/task-1/reports', {
          'requestId': 'report-task-replay',
          'reportedBy': 'master-1',
          'reportedQuantity': 2,
          'outcome': 'partial',
          'reason': 'First payload.',
        }),
      );
      expect(first.statusCode, 201);

      final replay = await handler(
        _jsonRequest('POST', 'http://localhost/v1/tasks/task-1/reports', {
          'requestId': 'report-task-replay',
          'reportedBy': 'master-1',
          'reportedQuantity': 4,
          'outcome': 'partial',
          'reason': 'Different payload.',
        }),
      );
      final body =
          jsonDecode(await replay.readAsString()) as Map<String, dynamic>;

      expect(replay.statusCode, 409);
      expect(
        (body['error'] as Map<String, dynamic>)['code'],
        'execution_report_replayed_with_different_payload',
      );
    },
  );

  test(
    'create execution report accepts overrun and creates WIP entry',
    () async {
      final handler = buildHandler();
      final response = await handler(
        _jsonRequest('POST', 'http://localhost/v1/tasks/task-1/reports', {
          'requestId': 'report-task-overflow',
          'reportedBy': 'master-1',
          'reportedQuantity': 7,
          'outcome': 'overrun',
          'reason': 'Finished extra unit from same setup.',
        }),
      );
      final body =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;

      final wipResponse = await handler(
        Request('GET', Uri.parse('http://localhost/v1/wip')),
      );
      final wipBody =
          jsonDecode(await wipResponse.readAsString()) as Map<String, dynamic>;

      expect(response.statusCode, 201);
      expect(body['taskStatus'], 'completed');
      expect(body['remainingQuantity'], 0);
      expect((body['wipEffect'] as Map<String, dynamic>)['type'], 'updated');
      expect((body['wipEffect'] as Map<String, dynamic>)['balanceQuantity'], 1);
      expect(
        (wipBody['items'] as List)
            .where(
              (item) => (item as Map<String, dynamic>)['taskId'] == 'task-1',
            )
            .single['sourceOutcome'],
        'overrun',
      );
      final linkedEntry = (wipBody['items'] as List)
          .map((item) => item as Map<String, dynamic>)
          .firstWhere((item) => item['taskId'] == 'task-1');
      expect(linkedEntry['planId'], 'plan-1');
      expect(linkedEntry['structureDisplayName'], 'Frame');
      expect(linkedEntry['operationName'], 'Cut');
    },
  );

  test(
    'create execution report accepts not completed with zero quantity',
    () async {
      final handler = buildHandler();
      final response = await handler(
        _jsonRequest('POST', 'http://localhost/v1/tasks/task-1/reports', {
          'requestId': 'report-task-not-completed',
          'reportedBy': 'master-1',
          'reportedQuantity': 0,
          'outcome': 'not_completed',
          'reason': 'Machine was blocked for the whole shift.',
        }),
      );
      final body =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;

      expect(response.statusCode, 201);
      expect(body['taskStatus'], 'inProgress');
      expect(body['reportedQuantityTotal'], 6);
      expect((body['wipEffect'] as Map<String, dynamic>)['type'], 'updated');
      expect((body['wipEffect'] as Map<String, dynamic>)['balanceQuantity'], 6);
    },
  );

  test(
    'create execution report rejects outcome and quantity mismatch',
    () async {
      final handler = buildHandler();
      final response = await handler(
        _jsonRequest('POST', 'http://localhost/v1/tasks/task-1/reports', {
          'requestId': 'report-task-invalid-outcome',
          'reportedBy': 'master-1',
          'reportedQuantity': 3,
          'outcome': 'completed',
        }),
      );
      final body =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;

      expect(response.statusCode, 422);
      expect(
        (body['error'] as Map<String, dynamic>)['code'],
        'invalid_report_outcome',
      );
    },
  );

  test('create execution report rejects closed task', () async {
    final handler = buildHandler();
    await handler(
      _jsonRequest('POST', 'http://localhost/v1/tasks/task-1/reports', {
        'requestId': 'report-task-close',
        'reportedBy': 'master-1',
        'reportedQuantity': 6,
        'outcome': 'completed',
      }),
    );

    final response = await handler(
      _jsonRequest('POST', 'http://localhost/v1/tasks/task-1/reports', {
        'requestId': 'report-task-after-close',
        'reportedBy': 'master-1',
        'reportedQuantity': 1,
        'outcome': 'partial',
        'reason': 'Late replay after close.',
      }),
    );
    final body =
        jsonDecode(await response.readAsString()) as Map<String, dynamic>;

    expect(response.statusCode, 409);
    expect(
      (body['error'] as Map<String, dynamic>)['code'],
      'task_report_not_allowed',
    );
  });

  test('problems endpoint supports taskId filter', () async {
    final handler = buildHandler();
    final response = await handler(
      Request('GET', Uri.parse('http://localhost/v1/problems?taskId=task-1')),
    );
    final body =
        jsonDecode(await response.readAsString()) as Map<String, dynamic>;

    expect(response.statusCode, 200);
    expect(body['count'], 1);
    expect((body['items'] as List).single['taskId'], 'task-1');
  });

  test('problem detail endpoint returns thread messages', () async {
    final handler = buildHandler();
    final response = await handler(
      Request('GET', Uri.parse('http://localhost/v1/problems/problem-1')),
    );
    final body =
        jsonDecode(await response.readAsString()) as Map<String, dynamic>;

    expect(response.statusCode, 200);
    expect(body['type'], 'equipment');
    expect(body['status'], 'inProgress');
    expect((body['messages'] as List).length, 1);
  });

  test('create problem creates open thread with first message', () async {
    final handler = buildHandler();
    final response = await handler(
      _jsonRequest('POST', 'http://localhost/v1/tasks/task-1/problems', {
        'requestId': 'problem-create-1',
        'createdBy': 'master-1',
        'type': 'materials',
        'title': 'Need blanks',
        'description': 'Material kit was not delivered.',
      }),
    );
    final body =
        jsonDecode(await response.readAsString()) as Map<String, dynamic>;

    expect(response.statusCode, 201);
    expect(body['taskId'], 'task-1');
    expect(body['type'], 'materials');
    expect(body['status'], 'open');
    expect(
      (body['messages'] as List).single['message'],
      'Material kit was not delivered.',
    );
  });

  test(
    'create problem is idempotent for repeated requestId and payload',
    () async {
      final handler = buildHandler();
      final first = await handler(
        _jsonRequest('POST', 'http://localhost/v1/tasks/task-1/problems', {
          'requestId': 'problem-create-idempotent',
          'createdBy': 'master-1',
          'type': 'documentation',
          'title': 'Missing drawing',
          'description': 'Drawing pack is incomplete.',
        }),
      );
      final second = await handler(
        _jsonRequest('POST', 'http://localhost/v1/tasks/task-1/problems', {
          'requestId': 'problem-create-idempotent',
          'createdBy': 'master-1',
          'type': 'documentation',
          'title': 'Missing drawing',
          'description': 'Drawing pack is incomplete.',
        }),
      );

      final firstBody =
          jsonDecode(await first.readAsString()) as Map<String, dynamic>;
      final secondBody =
          jsonDecode(await second.readAsString()) as Map<String, dynamic>;

      expect(first.statusCode, 201);
      expect(second.statusCode, 201);
      expect(secondBody['id'], firstBody['id']);
    },
  );

  test('create problem rejects unsupported type', () async {
    final handler = buildHandler();
    final response = await handler(
      _jsonRequest('POST', 'http://localhost/v1/tasks/task-1/problems', {
        'requestId': 'problem-create-invalid-type',
        'createdBy': 'master-1',
        'type': 'unknown_type',
        'title': 'Bad type',
        'description': 'Should fail.',
      }),
    );
    final body =
        jsonDecode(await response.readAsString()) as Map<String, dynamic>;

    expect(response.statusCode, 422);
    expect(
      (body['error'] as Map<String, dynamic>)['code'],
      'invalid_problem_type',
    );
  });

  test(
    'problem message and transition update lifecycle and block new messages after close',
    () async {
      final handler = buildHandler();
      final createResponse = await handler(
        _jsonRequest('POST', 'http://localhost/v1/tasks/task-1/problems', {
          'requestId': 'problem-create-thread',
          'createdBy': 'master-1',
          'type': 'equipment',
          'title': 'Hydraulics issue',
          'description': 'Pressure is unstable.',
        }),
      );
      final createBody =
          jsonDecode(await createResponse.readAsString())
              as Map<String, dynamic>;
      final problemId = createBody['id'] as String;

      final messageResponse = await handler(
        _jsonRequest(
          'POST',
          'http://localhost/v1/problems/$problemId/messages',
          {
            'requestId': 'problem-message-1',
            'authorId': 'master-1',
            'message': 'Maintenance called.',
          },
        ),
      );
      final messageBody =
          jsonDecode(await messageResponse.readAsString())
              as Map<String, dynamic>;

      final transitionResponse = await handler(
        _jsonRequest(
          'POST',
          'http://localhost/v1/problems/$problemId/transition',
          {
            'requestId': 'problem-transition-1',
            'changedBy': 'master-1',
            'toStatus': 'closed',
          },
        ),
      );
      final transitionBody =
          jsonDecode(await transitionResponse.readAsString())
              as Map<String, dynamic>;

      final blockedMessageResponse = await handler(
        _jsonRequest(
          'POST',
          'http://localhost/v1/problems/$problemId/messages',
          {
            'requestId': 'problem-message-after-close',
            'authorId': 'master-1',
            'message': 'Should be blocked.',
          },
        ),
      );
      final blockedMessageBody =
          jsonDecode(await blockedMessageResponse.readAsString())
              as Map<String, dynamic>;

      expect(messageResponse.statusCode, 200);
      expect((messageBody['messages'] as List).length, 2);
      expect(
        (messageBody['messages'] as List).last['message'],
        'Maintenance called.',
      );
      expect(transitionResponse.statusCode, 200);
      expect(transitionBody['status'], 'closed');
      expect(transitionBody['isOpen'], isFalse);
      expect(blockedMessageResponse.statusCode, 422);
      expect(
        (blockedMessageBody['error'] as Map<String, dynamic>)['code'],
        'problem_message_not_allowed',
      );
    },
  );

  test(
    'problem transition is idempotent and rejects replay with different payload',
    () async {
      final handler = buildHandler();
      final createResponse = await handler(
        _jsonRequest('POST', 'http://localhost/v1/tasks/task-1/problems', {
          'requestId': 'problem-create-transition-idempotent',
          'createdBy': 'master-1',
          'type': 'other',
          'title': 'Waiting for answer',
          'description': 'Initial thread.',
        }),
      );
      final createBody =
          jsonDecode(await createResponse.readAsString())
              as Map<String, dynamic>;
      final problemId = createBody['id'] as String;

      final first = await handler(
        _jsonRequest(
          'POST',
          'http://localhost/v1/problems/$problemId/transition',
          {
            'requestId': 'problem-transition-idempotent',
            'changedBy': 'master-1',
            'toStatus': 'inProgress',
          },
        ),
      );
      final second = await handler(
        _jsonRequest(
          'POST',
          'http://localhost/v1/problems/$problemId/transition',
          {
            'requestId': 'problem-transition-idempotent',
            'changedBy': 'master-1',
            'toStatus': 'inProgress',
          },
        ),
      );
      final replay = await handler(
        _jsonRequest(
          'POST',
          'http://localhost/v1/problems/$problemId/transition',
          {
            'requestId': 'problem-transition-idempotent',
            'changedBy': 'master-1',
            'toStatus': 'closed',
          },
        ),
      );

      final firstBody =
          jsonDecode(await first.readAsString()) as Map<String, dynamic>;
      final secondBody =
          jsonDecode(await second.readAsString()) as Map<String, dynamic>;
      final replayBody =
          jsonDecode(await replay.readAsString()) as Map<String, dynamic>;

      expect(first.statusCode, 200);
      expect(second.statusCode, 200);
      expect(secondBody['status'], firstBody['status']);
      expect(replay.statusCode, 409);
      expect(
        (replayBody['error'] as Map<String, dynamic>)['code'],
        'problem_request_replayed_with_different_payload',
      );
    },
  );

  test('create plan returns draft plan detail', () async {
    final handler = buildHandler();
    final response = await handler(
      _jsonRequest('POST', 'http://localhost/v1/plans', {
        'requestId': 'create-plan-1',
        'machineId': 'machine-1',
        'versionId': 'ver-2026-03',
        'title': 'New draft plan',
        'items': [
          {'structureOccurrenceId': 'occ-1', 'requestedQuantity': 3},
          {'structureOccurrenceId': 'occ-2', 'requestedQuantity': 2},
        ],
      }),
    );
    final body =
        jsonDecode(await response.readAsString()) as Map<String, dynamic>;

    expect(response.statusCode, 201);
    expect(body['status'], 'draft');
    expect(body['canRelease'], isTrue);
    expect(body['itemCount'], 2);
    expect((body['items'] as List).last['displayName'], 'Body Panel');
  });

  test('get plan detail returns nested items', () async {
    final handler = buildHandler();
    final createResponse = await handler(
      _jsonRequest('POST', 'http://localhost/v1/plans', {
        'requestId': 'create-plan-detail',
        'machineId': 'machine-1',
        'versionId': 'ver-2026-03',
        'title': 'Detail check',
        'items': [
          {'structureOccurrenceId': 'occ-1', 'requestedQuantity': 5},
        ],
      }),
    );
    final createBody =
        jsonDecode(await createResponse.readAsString()) as Map<String, dynamic>;
    final planId = createBody['id'] as String;

    final response = await handler(
      Request('GET', Uri.parse('http://localhost/v1/plans/$planId')),
    );
    final body =
        jsonDecode(await response.readAsString()) as Map<String, dynamic>;

    expect(response.statusCode, 200);
    expect(body['id'], planId);
    expect((body['items'] as List).single['structureOccurrenceId'], 'occ-1');
  });

  test(
    'create plan is idempotent for repeated requestId and payload',
    () async {
      final handler = buildHandler();
      final first = await handler(
        _jsonRequest('POST', 'http://localhost/v1/plans', {
          'requestId': 'create-plan-idempotent',
          'machineId': 'machine-1',
          'versionId': 'ver-2026-03',
          'title': 'Idempotent plan',
          'items': [
            {'structureOccurrenceId': 'occ-1', 'requestedQuantity': 4},
          ],
        }),
      );
      final second = await handler(
        _jsonRequest('POST', 'http://localhost/v1/plans', {
          'requestId': 'create-plan-idempotent',
          'machineId': 'machine-1',
          'versionId': 'ver-2026-03',
          'title': 'Idempotent plan',
          'items': [
            {'structureOccurrenceId': 'occ-1', 'requestedQuantity': 4},
          ],
        }),
      );

      final firstBody =
          jsonDecode(await first.readAsString()) as Map<String, dynamic>;
      final secondBody =
          jsonDecode(await second.readAsString()) as Map<String, dynamic>;
      expect(first.statusCode, 201);
      expect(second.statusCode, 201);
      expect(secondBody['id'], firstBody['id']);
    },
  );

  test('create plan rejects duplicate structure occurrences', () async {
    final handler = buildHandler();
    final response = await handler(
      _jsonRequest('POST', 'http://localhost/v1/plans', {
        'requestId': 'create-plan-duplicate',
        'machineId': 'machine-1',
        'versionId': 'ver-2026-03',
        'title': 'Duplicate occurrence',
        'items': [
          {'structureOccurrenceId': 'occ-1', 'requestedQuantity': 4},
          {'structureOccurrenceId': 'occ-1', 'requestedQuantity': 2},
        ],
      }),
    );
    final body =
        jsonDecode(await response.readAsString()) as Map<String, dynamic>;

    expect(response.statusCode, 422);
    expect(
      (body['error'] as Map<String, dynamic>)['code'],
      'duplicate_structure_occurrence',
    );
  });

  test('create plan rejects same requestId with different payload', () async {
    final handler = buildHandler();
    final first = await handler(
      _jsonRequest('POST', 'http://localhost/v1/plans', {
        'requestId': 'create-plan-replay',
        'machineId': 'machine-1',
        'versionId': 'ver-2026-03',
        'title': 'Replay plan',
        'items': [
          {'structureOccurrenceId': 'occ-1', 'requestedQuantity': 4},
        ],
      }),
    );
    expect(first.statusCode, 201);

    final replay = await handler(
      _jsonRequest('POST', 'http://localhost/v1/plans', {
        'requestId': 'create-plan-replay',
        'machineId': 'machine-1',
        'versionId': 'ver-2026-03',
        'title': 'Replay plan changed',
        'items': [
          {'structureOccurrenceId': 'occ-2', 'requestedQuantity': 1},
        ],
      }),
    );
    final body =
        jsonDecode(await replay.readAsString()) as Map<String, dynamic>;

    expect(replay.statusCode, 409);
    expect(
      (body['error'] as Map<String, dynamic>)['code'],
      'plan_request_replayed_with_different_payload',
    );
  });

  test('release plan creates tasks from operation occurrences', () async {
    final handler = buildHandler();
    final createResponse = await handler(
      _jsonRequest('POST', 'http://localhost/v1/plans', {
        'requestId': 'create-plan-release',
        'machineId': 'machine-1',
        'versionId': 'ver-2026-03',
        'title': 'Release me',
        'items': [
          {'structureOccurrenceId': 'occ-2', 'requestedQuantity': 3},
        ],
      }),
    );
    final createBody =
        jsonDecode(await createResponse.readAsString()) as Map<String, dynamic>;
    final planId = createBody['id'] as String;

    final releaseResponse = await handler(
      _jsonRequest('POST', 'http://localhost/v1/plans/$planId/release', {
        'requestId': 'release-plan-1',
        'releasedBy': 'planner-1',
      }),
    );
    final releaseBody =
        jsonDecode(await releaseResponse.readAsString())
            as Map<String, dynamic>;

    final detailResponse = await handler(
      Request('GET', Uri.parse('http://localhost/v1/plans/$planId')),
    );
    final detailBody =
        jsonDecode(await detailResponse.readAsString()) as Map<String, dynamic>;

    final tasksResponse = await handler(
      Request('GET', Uri.parse('http://localhost/v1/tasks')),
    );
    final tasksBody =
        jsonDecode(await tasksResponse.readAsString()) as Map<String, dynamic>;

    expect(releaseResponse.statusCode, 200);
    expect(releaseBody['status'], 'released');
    expect(releaseBody['generatedTaskCount'], 2);
    expect(detailBody['status'], 'released');
    expect(tasksBody['count'], 4);
  });

  test(
    'release plan is idempotent for repeated requestId and payload',
    () async {
      final handler = buildHandler();
      final createResponse = await handler(
        _jsonRequest('POST', 'http://localhost/v1/plans', {
          'requestId': 'create-plan-release-idempotent',
          'machineId': 'machine-1',
          'versionId': 'ver-2026-03',
          'title': 'Release once',
          'items': [
            {'structureOccurrenceId': 'occ-1', 'requestedQuantity': 1},
          ],
        }),
      );
      final createBody =
          jsonDecode(await createResponse.readAsString())
              as Map<String, dynamic>;
      final planId = createBody['id'] as String;

      final first = await handler(
        _jsonRequest('POST', 'http://localhost/v1/plans/$planId/release', {
          'requestId': 'release-plan-idempotent',
          'releasedBy': 'planner-1',
        }),
      );
      final second = await handler(
        _jsonRequest('POST', 'http://localhost/v1/plans/$planId/release', {
          'requestId': 'release-plan-idempotent',
          'releasedBy': 'planner-1',
        }),
      );

      final firstBody =
          jsonDecode(await first.readAsString()) as Map<String, dynamic>;
      final secondBody =
          jsonDecode(await second.readAsString()) as Map<String, dynamic>;
      expect(first.statusCode, 200);
      expect(second.statusCode, 200);
      expect(secondBody['generatedTaskCount'], firstBody['generatedTaskCount']);
    },
  );

  test('release plan rejects lifecycle conflicts', () async {
    final handler = buildHandler();
    final response = await handler(
      _jsonRequest('POST', 'http://localhost/v1/plans/plan-1/release', {
        'requestId': 'release-existing-plan',
        'releasedBy': 'planner-1',
      }),
    );
    final body =
        jsonDecode(await response.readAsString()) as Map<String, dynamic>;

    expect(response.statusCode, 409);
    expect(
      (body['error'] as Map<String, dynamic>)['code'],
      'plan_release_not_allowed',
    );
  });

  test('completion-check returns blockers for released plan', () async {
    final handler = buildHandler();
    final response = await handler(
      Request(
        'GET',
        Uri.parse('http://localhost/v1/plans/plan-1/completion-check'),
      ),
    );
    final body =
        jsonDecode(await response.readAsString()) as Map<String, dynamic>;

    expect(response.statusCode, 200);
    expect(body['planId'], 'plan-1');
    expect(body['canComplete'], isFalse);
    expect(
      (body['blockers'] as List)
          .map((item) => (item as Map<String, dynamic>)['type'])
          .toList(),
      containsAll(['openTasks', 'openProblems', 'openWip']),
    );
  });

  test('complete rejects plan when blockers exist', () async {
    final handler = buildHandler();
    final response = await handler(
      _jsonRequest('POST', 'http://localhost/v1/plans/plan-1/complete', {
        'requestId': 'complete-plan-blocked',
        'completedBy': 'supervisor-1',
      }),
    );
    final body =
        jsonDecode(await response.readAsString()) as Map<String, dynamic>;

    expect(response.statusCode, 409);
    expect(
      (body['error'] as Map<String, dynamic>)['code'],
      'plan_completion_blocked',
    );
    expect(
      ((body['error'] as Map<String, dynamic>)['details']
          as Map<String, dynamic>)['blockers'],
      isNotEmpty,
    );
  });

  test(
    'complete transitions released plan to completed when blockers clear',
    () async {
      final handler = buildHandler();
      final createResponse = await handler(
        _jsonRequest('POST', 'http://localhost/v1/plans', {
          'requestId': 'create-plan-complete',
          'machineId': 'machine-1',
          'versionId': 'ver-2026-03',
          'title': 'Completable plan',
          'items': [
            {'structureOccurrenceId': 'occ-1', 'requestedQuantity': 1},
          ],
        }),
      );
      final createBody =
          jsonDecode(await createResponse.readAsString())
              as Map<String, dynamic>;
      final planId = createBody['id'] as String;

      final releaseResponse = await handler(
        _jsonRequest('POST', 'http://localhost/v1/plans/$planId/release', {
          'requestId': 'release-plan-complete',
          'releasedBy': 'planner-1',
        }),
      );
      expect(releaseResponse.statusCode, 200);

      final tasksResponse = await handler(
        Request('GET', Uri.parse('http://localhost/v1/tasks?status=pending')),
      );
      final tasksBody =
          jsonDecode(await tasksResponse.readAsString())
              as Map<String, dynamic>;
      final newTask = (tasksBody['items'] as List)
          .map((item) => item as Map<String, dynamic>)
          .firstWhere((item) => item['planItemId'] != 'plan-item-2');
      final taskId = newTask['id'] as String;

      final reportResponse = await handler(
        _jsonRequest('POST', 'http://localhost/v1/tasks/$taskId/reports', {
          'requestId': 'report-plan-complete',
          'reportedBy': 'master-1',
          'reportedQuantity': 1,
          'outcome': 'completed',
        }),
      );
      expect(reportResponse.statusCode, 201);

      final checkResponse = await handler(
        Request(
          'GET',
          Uri.parse('http://localhost/v1/plans/$planId/completion-check'),
        ),
      );
      final checkBody =
          jsonDecode(await checkResponse.readAsString())
              as Map<String, dynamic>;
      expect(checkResponse.statusCode, 200);
      expect(checkBody['canComplete'], isTrue);
      expect(checkBody['blockers'], isEmpty);

      final completeResponse = await handler(
        _jsonRequest('POST', 'http://localhost/v1/plans/$planId/complete', {
          'requestId': 'complete-plan-success',
          'completedBy': 'supervisor-1',
        }),
      );
      final completeBody =
          jsonDecode(await completeResponse.readAsString())
              as Map<String, dynamic>;
      expect(completeResponse.statusCode, 200);
      expect(completeBody['status'], 'completed');

      final detailResponse = await handler(
        Request('GET', Uri.parse('http://localhost/v1/plans/$planId')),
      );
      final detailBody =
          jsonDecode(await detailResponse.readAsString())
              as Map<String, dynamic>;
      expect(detailBody['status'], 'completed');
      expect(detailBody['canRelease'], isFalse);
    },
  );

  test(
    'complete is idempotent and rejects replay with different payload',
    () async {
      final handler = buildHandler();
      final createResponse = await handler(
        _jsonRequest('POST', 'http://localhost/v1/plans', {
          'requestId': 'create-plan-complete-idempotent',
          'machineId': 'machine-1',
          'versionId': 'ver-2026-03',
          'title': 'Idempotent complete',
          'items': [
            {'structureOccurrenceId': 'occ-1', 'requestedQuantity': 1},
          ],
        }),
      );
      final createBody =
          jsonDecode(await createResponse.readAsString())
              as Map<String, dynamic>;
      final planId = createBody['id'] as String;

      final releaseResponse = await handler(
        _jsonRequest('POST', 'http://localhost/v1/plans/$planId/release', {
          'requestId': 'release-plan-complete-idempotent',
          'releasedBy': 'planner-1',
        }),
      );
      expect(releaseResponse.statusCode, 200);

      final tasksResponse = await handler(
        Request('GET', Uri.parse('http://localhost/v1/tasks?status=pending')),
      );
      final tasksBody =
          jsonDecode(await tasksResponse.readAsString())
              as Map<String, dynamic>;
      final newTask = (tasksBody['items'] as List)
          .map((item) => item as Map<String, dynamic>)
          .firstWhere((item) => item['planItemId'] != 'plan-item-2');
      final taskId = newTask['id'] as String;

      final reportResponse = await handler(
        _jsonRequest('POST', 'http://localhost/v1/tasks/$taskId/reports', {
          'requestId': 'report-plan-complete-idempotent',
          'reportedBy': 'master-1',
          'reportedQuantity': 1,
          'outcome': 'completed',
        }),
      );
      expect(reportResponse.statusCode, 201);

      final first = await handler(
        _jsonRequest('POST', 'http://localhost/v1/plans/$planId/complete', {
          'requestId': 'complete-plan-idempotent',
          'completedBy': 'supervisor-1',
        }),
      );
      final second = await handler(
        _jsonRequest('POST', 'http://localhost/v1/plans/$planId/complete', {
          'requestId': 'complete-plan-idempotent',
          'completedBy': 'supervisor-1',
        }),
      );
      final replay = await handler(
        _jsonRequest('POST', 'http://localhost/v1/plans/$planId/complete', {
          'requestId': 'complete-plan-idempotent',
          'completedBy': 'supervisor-2',
        }),
      );

      final firstBody =
          jsonDecode(await first.readAsString()) as Map<String, dynamic>;
      final secondBody =
          jsonDecode(await second.readAsString()) as Map<String, dynamic>;
      final replayBody =
          jsonDecode(await replay.readAsString()) as Map<String, dynamic>;

      expect(first.statusCode, 200);
      expect(second.statusCode, 200);
      expect(secondBody['status'], firstBody['status']);
      expect(replay.statusCode, 409);
      expect(
        (replayBody['error'] as Map<String, dynamic>)['code'],
        'plan_request_replayed_with_different_payload',
      );
    },
  );

  test('preview session endpoint creates import session from xlsx', () async {
    final handler = buildHandler();
    final response = await handler(
      _jsonRequest('POST', 'http://localhost/v1/import-sessions/preview', {
        'requestId': 'preview-1',
        'fileName': 'valid_import.xlsx',
        'fileContentBase64': _readFixture(
          'valid_import.xlsx.b64',
        ).replaceAll(RegExp(r'\s+'), ''),
      }),
    );
    final body =
        jsonDecode(await response.readAsString()) as Map<String, dynamic>;

    expect(response.statusCode, 201);
    expect(body['status'], 'preview_ready');
    expect((body['preview'] as Map<String, dynamic>)['sourceFormat'], 'excel');
    expect((body['preview'] as Map<String, dynamic>)['canConfirm'], isTrue);
    expect(
      (body['preview'] as Map<String, dynamic>)['structureOccurrenceCount'],
      2,
    );
  });

  test('get import session returns previously created preview', () async {
    final handler = buildHandler();
    final previewResponse = await handler(
      _jsonRequest('POST', 'http://localhost/v1/import-sessions/preview', {
        'requestId': 'preview-2',
        'fileName': 'valid_import.mxl',
        'fileContentBase64': base64.encode(
          utf8.encode(_readFixture('valid_import.mxl')),
        ),
      }),
    );
    final previewBody =
        jsonDecode(await previewResponse.readAsString())
            as Map<String, dynamic>;
    final sessionId = previewBody['sessionId'] as String;

    final getResponse = await handler(
      Request(
        'GET',
        Uri.parse('http://localhost/v1/import-sessions/$sessionId'),
      ),
    );
    final getBody =
        jsonDecode(await getResponse.readAsString()) as Map<String, dynamic>;

    expect(getResponse.statusCode, 200);
    expect(getBody['sessionId'], sessionId);
    expect((getBody['preview'] as Map<String, dynamic>)['sourceFormat'], 'mxl');
  });

  test(
    'confirm create_machine adds machine visible in machines endpoint',
    () async {
      final handler = buildHandler();
      final previewResponse = await handler(
        _jsonRequest('POST', 'http://localhost/v1/import-sessions/preview', {
          'requestId': 'preview-create-machine',
          'fileName': 'valid_import.mxl',
          'fileContentBase64': base64.encode(
            utf8.encode(_readFixture('valid_import.mxl')),
          ),
        }),
      );
      final previewBody =
          jsonDecode(await previewResponse.readAsString())
              as Map<String, dynamic>;
      final sessionId = previewBody['sessionId'] as String;

      final confirmResponse = await handler(
        _jsonRequest(
          'POST',
          'http://localhost/v1/import-sessions/$sessionId/confirm',
          {'requestId': 'confirm-create-machine', 'mode': 'create_machine'},
        ),
      );
      final confirmBody =
          jsonDecode(await confirmResponse.readAsString())
              as Map<String, dynamic>;

      expect(confirmResponse.statusCode, 200);
      expect(confirmBody['mode'], 'create_machine');
      expect(confirmBody['machineId'], 'machine-2');

      final machinesResponse = await handler(
        Request('GET', Uri.parse('http://localhost/v1/machines')),
      );
      final machinesBody =
          jsonDecode(await machinesResponse.readAsString())
              as Map<String, dynamic>;
      expect(machinesBody['count'], 2);
      expect(
        (machinesBody['items'] as List)
            .map((item) => (item as Map<String, dynamic>)['code'])
            .toList(),
        contains('PDO-200'),
      );
    },
  );

  test(
    'confirm create_version adds published version to existing machine',
    () async {
      final handler = buildHandler();
      final previewResponse = await handler(
        _jsonRequest('POST', 'http://localhost/v1/import-sessions/preview', {
          'requestId': 'preview-create-version',
          'fileName': 'valid_import.xlsx',
          'fileContentBase64': _readFixture(
            'valid_import.xlsx.b64',
          ).replaceAll(RegExp(r'\s+'), ''),
        }),
      );
      final previewBody =
          jsonDecode(await previewResponse.readAsString())
              as Map<String, dynamic>;
      final sessionId = previewBody['sessionId'] as String;

      final confirmResponse = await handler(
        _jsonRequest(
          'POST',
          'http://localhost/v1/import-sessions/$sessionId/confirm',
          {
            'requestId': 'confirm-create-version',
            'mode': 'create_version',
            'targetMachineId': 'machine-1',
          },
        ),
      );
      final confirmBody =
          jsonDecode(await confirmResponse.readAsString())
              as Map<String, dynamic>;
      expect(confirmResponse.statusCode, 200);
      expect(confirmBody['mode'], 'create_version');
      expect(confirmBody['machineId'], 'machine-1');

      final versionsResponse = await handler(
        Request(
          'GET',
          Uri.parse('http://localhost/v1/machines/machine-1/versions'),
        ),
      );
      final versionsBody =
          jsonDecode(await versionsResponse.readAsString())
              as Map<String, dynamic>;
      expect(versionsBody['count'], 3);
      expect((versionsBody['items'] as List).last['status'], 'published');
    },
  );

  test('confirm blocked preview returns 422', () async {
    final handler = buildHandler();
    final previewResponse = await handler(
      _jsonRequest('POST', 'http://localhost/v1/import-sessions/preview', {
        'requestId': 'preview-conflict',
        'fileName': 'conflict_ambiguous_parent.mxl',
        'fileContentBase64': base64.encode(
          utf8.encode(_readFixture('conflict_ambiguous_parent.mxl')),
        ),
      }),
    );
    final previewBody =
        jsonDecode(await previewResponse.readAsString())
            as Map<String, dynamic>;
    final sessionId = previewBody['sessionId'] as String;

    final confirmResponse = await handler(
      _jsonRequest(
        'POST',
        'http://localhost/v1/import-sessions/$sessionId/confirm',
        {'requestId': 'confirm-conflict', 'mode': 'create_machine'},
      ),
    );
    final confirmBody =
        jsonDecode(await confirmResponse.readAsString())
            as Map<String, dynamic>;

    expect(confirmResponse.statusCode, 422);
    expect(
      (confirmBody['error'] as Map<String, dynamic>)['code'],
      'import_preview_has_conflicts',
    );
  });

  test('confirm is idempotent for repeated requestId and payload', () async {
    final handler = buildHandler();
    final previewResponse = await handler(
      _jsonRequest('POST', 'http://localhost/v1/import-sessions/preview', {
        'requestId': 'preview-idempotent',
        'fileName': 'valid_import.mxl',
        'fileContentBase64': base64.encode(
          utf8.encode(_readFixture('valid_import.mxl')),
        ),
      }),
    );
    final previewBody =
        jsonDecode(await previewResponse.readAsString())
            as Map<String, dynamic>;
    final sessionId = previewBody['sessionId'] as String;

    final firstConfirm = await handler(
      _jsonRequest(
        'POST',
        'http://localhost/v1/import-sessions/$sessionId/confirm',
        {'requestId': 'confirm-idempotent', 'mode': 'create_machine'},
      ),
    );
    final secondConfirm = await handler(
      _jsonRequest(
        'POST',
        'http://localhost/v1/import-sessions/$sessionId/confirm',
        {'requestId': 'confirm-idempotent', 'mode': 'create_machine'},
      ),
    );

    final firstBody =
        jsonDecode(await firstConfirm.readAsString()) as Map<String, dynamic>;
    final secondBody =
        jsonDecode(await secondConfirm.readAsString()) as Map<String, dynamic>;
    expect(firstConfirm.statusCode, 200);
    expect(secondConfirm.statusCode, 200);
    expect(secondBody['versionId'], firstBody['versionId']);
  });

  test('confirm rejects same requestId with different payload', () async {
    final handler = buildHandler();
    final previewResponse = await handler(
      _jsonRequest('POST', 'http://localhost/v1/import-sessions/preview', {
        'requestId': 'preview-replay',
        'fileName': 'valid_import.mxl',
        'fileContentBase64': base64.encode(
          utf8.encode(_readFixture('valid_import.mxl')),
        ),
      }),
    );
    final previewBody =
        jsonDecode(await previewResponse.readAsString())
            as Map<String, dynamic>;
    final sessionId = previewBody['sessionId'] as String;

    final firstConfirm = await handler(
      _jsonRequest(
        'POST',
        'http://localhost/v1/import-sessions/$sessionId/confirm',
        {
          'requestId': 'confirm-replay',
          'mode': 'create_version',
          'targetMachineId': 'machine-1',
        },
      ),
    );
    expect(firstConfirm.statusCode, 200);

    final replayedConfirm = await handler(
      _jsonRequest(
        'POST',
        'http://localhost/v1/import-sessions/$sessionId/confirm',
        {'requestId': 'confirm-replay', 'mode': 'create_machine'},
      ),
    );
    final replayedBody =
        jsonDecode(await replayedConfirm.readAsString())
            as Map<String, dynamic>;

    expect(replayedConfirm.statusCode, 409);
    expect(
      (replayedBody['error'] as Map<String, dynamic>)['code'],
      'import_request_replayed_with_different_payload',
    );
  });
}

Request _jsonRequest(String method, String url, Map<String, Object?> body) {
  return Request(
    method,
    Uri.parse(url),
    headers: const {'content-type': 'application/json'},
    body: jsonEncode(body),
  );
}

String _readFixture(String fileName) {
  return File(
    '../packages/import_engine/test/fixtures/$fileName',
  ).readAsStringSync();
}
