import 'dart:convert';

import 'package:data_models/data_models.dart';
import 'package:domain/domain.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../import/import_session.dart';
import '../import/import_session_service.dart';
import '../store/demo_contract_store.dart';
import 'json_response.dart';

Router buildV1Router(
  DemoContractStore store,
  ImportSessionService importSessionService,
) {
  final router = Router()
    ..get('/machines', (Request request) {
      final items = store
          .listMachines()
          .map(MachineSummaryDto.fromDomain)
          .toList(growable: false);
      final dto = ApiListResponseDto(
        items: items,
        meta: const {'source': 'local_contract_seed', 'resource': 'machines'},
      );
      return jsonResponse(dto.toJson((item) => item.toJson()));
    })
    ..get('/machines/<machineId>/versions', (
      Request request,
      String machineId,
    ) {
      try {
        final items = store
            .listVersions(machineId)
            .map(MachineVersionSummaryDto.fromDomain)
            .toList(growable: false);
        final dto = ApiListResponseDto(
          items: items,
          meta: {
            'source': 'local_contract_seed',
            'resource': 'machine_versions',
            'machineId': machineId,
          },
        );
        return jsonResponse(dto.toJson((item) => item.toJson()));
      } on DemoStoreNotFound catch (error) {
        return jsonResponse(
          ApiErrorDto(
            code: error.code,
            message: error.message,
            details: {'machineId': machineId},
          ).toJson(),
          statusCode: 404,
        );
      }
    })
    ..get('/machines/<machineId>/versions/<versionId>/planning-source', (
      Request request,
      String machineId,
      String versionId,
    ) {
      try {
        final items = store
            .listPlanningSource(machineId, versionId)
            .map(
              (occurrence) => PlanningSourceOccurrenceDto.fromDomain(
                occurrence,
                operationCount: store.operationCountForOccurrence(
                  occurrence.id,
                ),
              ),
            )
            .toList(growable: false);
        final dto = ApiListResponseDto(
          items: items,
          meta: {
            'source': 'local_contract_seed',
            'resource': 'planning_source',
            'machineId': machineId,
            'versionId': versionId,
          },
        );
        return jsonResponse(dto.toJson((item) => item.toJson()));
      } on DemoStoreNotFound catch (error) {
        return _storeErrorResponse(
          error.code,
          error.message,
          error.details,
          404,
        );
      }
    })
    ..post('/import-sessions/preview', (Request request) async {
      try {
        final body = await _readJsonBody(request);
        final dto = importSessionService.createPreviewSession(
          CreateImportPreviewRequestDto.fromJson(body),
        );
        return jsonResponse(dto.toJson(), statusCode: 201);
      } on ImportSessionException catch (error) {
        return _importErrorResponse(error);
      } on FormatException {
        return _invalidJsonResponse();
      }
    })
    ..get('/import-sessions/<sessionId>', (Request request, String sessionId) {
      try {
        final dto = importSessionService.getSession(sessionId);
        return jsonResponse(dto.toJson());
      } on ImportSessionException catch (error) {
        return _importErrorResponse(error);
      }
    })
    ..post('/import-sessions/<sessionId>/confirm', (
      Request request,
      String sessionId,
    ) async {
      try {
        final body = await _readJsonBody(request);
        final dto = importSessionService.confirmImport(
          sessionId,
          ConfirmImportRequestDto.fromJson(body),
        );
        return jsonResponse(dto.toJson());
      } on ImportSessionException catch (error) {
        return _importErrorResponse(error);
      } on FormatException {
        return _invalidJsonResponse();
      }
    })
    ..get('/plans', (Request request) {
      final items = store
          .listPlans()
          .map(PlanSummaryDto.fromDomain)
          .toList(growable: false);
      final dto = ApiListResponseDto(
        items: items,
        meta: const {'source': 'local_contract_seed', 'resource': 'plans'},
      );
      return jsonResponse(dto.toJson((item) => item.toJson()));
    })
    ..post('/plans', (Request request) async {
      try {
        final body = await _readJsonBody(request);
        final dto = CreatePlanRequestDto.fromJson(body);
        final plan = store.createPlan(
          CreatePlanCommand(
            requestId: dto.requestId,
            machineId: dto.machineId,
            versionId: dto.versionId,
            title: dto.title,
            items: dto.items
                .map(
                  (item) => CreatePlanItemCommand(
                    structureOccurrenceId: item.structureOccurrenceId,
                    requestedQuantity: item.requestedQuantity,
                  ),
                )
                .toList(growable: false),
          ),
        );
        return jsonResponse(
          _toPlanDetailDto(plan, store).toJson(),
          statusCode: 201,
        );
      } on DemoStoreNotFound catch (error) {
        return _storeErrorResponse(
          error.code,
          error.message,
          error.details,
          404,
        );
      } on DemoStoreValidation catch (error) {
        return _storeErrorResponse(
          error.code,
          error.message,
          error.details,
          422,
        );
      } on DemoStoreConflict catch (error) {
        return _storeErrorResponse(
          error.code,
          error.message,
          error.details,
          409,
        );
      } on FormatException {
        return _invalidJsonResponse();
      }
    })
    ..get('/plans/<planId>', (Request request, String planId) {
      try {
        final plan = store.getPlan(planId);
        return jsonResponse(_toPlanDetailDto(plan, store).toJson());
      } on DemoStoreNotFound catch (error) {
        return _storeErrorResponse(
          error.code,
          error.message,
          error.details,
          404,
        );
      }
    })
    ..get('/plans/<planId>/completion-check', (Request request, String planId) {
      try {
        final decision = store.getPlanCompletionDecision(planId);
        return jsonResponse(
          PlanCompletionDecisionDto.fromDomain(planId, decision).toJson(),
        );
      } on DemoStoreNotFound catch (error) {
        return _storeErrorResponse(
          error.code,
          error.message,
          error.details,
          404,
        );
      }
    })
    ..post('/plans/<planId>/release', (Request request, String planId) async {
      try {
        final body = await _readJsonBody(request);
        final dto = ReleasePlanRequestDto.fromJson(body);
        final result = store.releasePlan(
          ReleasePlanCommand(
            requestId: dto.requestId,
            planId: planId,
            releasedBy: dto.releasedBy,
          ),
        );
        return jsonResponse(
          PlanReleaseResultDto(
            planId: result.planId,
            status: result.status.name,
            generatedTaskCount: result.generatedTaskCount,
          ).toJson(),
        );
      } on DemoStoreNotFound catch (error) {
        return _storeErrorResponse(
          error.code,
          error.message,
          error.details,
          404,
        );
      } on DemoStoreValidation catch (error) {
        return _storeErrorResponse(
          error.code,
          error.message,
          error.details,
          422,
        );
      } on DemoStoreConflict catch (error) {
        return _storeErrorResponse(
          error.code,
          error.message,
          error.details,
          409,
        );
      } on FormatException {
        return _invalidJsonResponse();
      }
    })
    ..post('/plans/<planId>/complete', (Request request, String planId) async {
      try {
        final body = await _readJsonBody(request);
        final dto = CompletePlanRequestDto.fromJson(body);
        final result = store.completePlan(
          CompletePlanCommand(
            requestId: dto.requestId,
            planId: planId,
            completedBy: dto.completedBy,
          ),
        );
        return jsonResponse(
          PlanCompletionResultDto(
            planId: result.planId,
            status: result.status.name,
          ).toJson(),
        );
      } on DemoStoreNotFound catch (error) {
        return _storeErrorResponse(
          error.code,
          error.message,
          error.details,
          404,
        );
      } on DemoStoreValidation catch (error) {
        return _storeErrorResponse(
          error.code,
          error.message,
          error.details,
          422,
        );
      } on DemoStoreConflict catch (error) {
        return _storeErrorResponse(
          error.code,
          error.message,
          error.details,
          409,
        );
      } on FormatException {
        return _invalidJsonResponse();
      }
    })
    ..get('/tasks', (Request request) {
      final assigneeId = request.url.queryParameters['assigneeId'];
      final status = request.url.queryParameters['status'];
      final items = store
          .listTasks(assigneeId: assigneeId, status: status)
          .map((task) => _toTaskSummaryDto(task, store))
          .toList(growable: false);
      final dto = ApiListResponseDto(
        items: items,
        meta: {
          'source': 'local_contract_seed',
          'resource': 'tasks',
          if (assigneeId != null) 'assigneeId': assigneeId,
          if (status != null) 'status': status,
        },
      );
      return jsonResponse(dto.toJson((item) => item.toJson()));
    })
    ..get('/tasks/<taskId>', (Request request, String taskId) {
      try {
        final task = store.getTask(taskId);
        return jsonResponse(_toTaskDetailDto(task, store).toJson());
      } on DemoStoreNotFound catch (error) {
        return _storeErrorResponse(
          error.code,
          error.message,
          error.details,
          404,
        );
      }
    })
    ..get('/tasks/<taskId>/reports', (Request request, String taskId) {
      try {
        final items = store
            .listReports(taskId)
            .map(ExecutionReportDto.fromDomain)
            .toList(growable: false);
        final dto = ApiListResponseDto(
          items: items,
          meta: {
            'source': 'local_contract_seed',
            'resource': 'execution_reports',
            'taskId': taskId,
          },
        );
        return jsonResponse(dto.toJson((item) => item.toJson()));
      } on DemoStoreNotFound catch (error) {
        return jsonResponse(
          ApiErrorDto(
            code: error.code,
            message: error.message,
            details: {'taskId': taskId},
          ).toJson(),
          statusCode: 404,
        );
      }
    })
    ..post('/tasks/<taskId>/reports', (Request request, String taskId) async {
      try {
        final body = await _readJsonBody(request);
        final dto = CreateExecutionReportRequestDto.fromJson(body);
        final result = store.createExecutionReport(
          CreateExecutionReportCommand(
            requestId: dto.requestId,
            taskId: taskId,
            reportedBy: dto.reportedBy,
            reportedQuantity: dto.reportedQuantity,
            outcome: _parseExecutionReportOutcome(dto.outcome),
            reason: dto.reason,
          ),
        );
        return jsonResponse(
          CreateExecutionReportResultDto(
            report: ExecutionReportDto.fromDomain(result.report),
            taskStatus: result.taskStatus.name,
            reportedQuantityTotal: result.reportedQuantityTotal,
            remainingQuantity: result.remainingQuantity,
            outboxStatus: 'sent',
            wipEffect: ExecutionReportWipEffectDto(
              type: result.wipEffect.type,
              wipEntryId: result.wipEffect.entry?.id,
              balanceQuantity: result.wipEffect.entry?.balanceQuantity,
              status: result.wipEffect.entry?.status.name,
            ),
          ).toJson(),
          statusCode: 201,
        );
      } on DemoStoreNotFound catch (error) {
        return _storeErrorResponse(
          error.code,
          error.message,
          error.details,
          404,
        );
      } on DemoStoreValidation catch (error) {
        return _storeErrorResponse(
          error.code,
          error.message,
          error.details,
          422,
        );
      } on DemoStoreConflict catch (error) {
        return _storeErrorResponse(
          error.code,
          error.message,
          error.details,
          409,
        );
      } on FormatException {
        return _invalidJsonResponse();
      }
    })
    ..get('/problems', (Request request) {
      final taskId = request.url.queryParameters['taskId'];
      final status = request.url.queryParameters['status'];
      final items = store
          .listProblems(taskId: taskId, status: status)
          .map((problem) => _toProblemSummaryDto(problem, store))
          .toList(growable: false);
      final dto = ApiListResponseDto(
        items: items,
        meta: {
          'source': 'local_contract_seed',
          'resource': 'problems',
          if (taskId != null) 'taskId': taskId,
          if (status != null) 'status': status,
        },
      );
      return jsonResponse(dto.toJson((item) => item.toJson()));
    })
    ..get('/problems/<problemId>', (Request request, String problemId) {
      try {
        final problem = store.getProblem(problemId);
        return jsonResponse(_toProblemDetailDto(problem, store).toJson());
      } on DemoStoreNotFound catch (error) {
        return _storeErrorResponse(
          error.code,
          error.message,
          error.details,
          404,
        );
      }
    })
    ..post('/tasks/<taskId>/problems', (Request request, String taskId) async {
      try {
        final body = await _readJsonBody(request);
        final dto = CreateProblemRequestDto.fromJson(body);
        final problem = store.createProblem(
          CreateProblemCommand(
            requestId: dto.requestId,
            taskId: taskId,
            createdBy: dto.createdBy,
            type: _parseProblemType(dto.type),
            title: dto.title,
            description: dto.description,
          ),
        );
        return jsonResponse(
          _toProblemDetailDto(problem, store).toJson(),
          statusCode: 201,
        );
      } on DemoStoreNotFound catch (error) {
        return _storeErrorResponse(
          error.code,
          error.message,
          error.details,
          404,
        );
      } on DemoStoreValidation catch (error) {
        return _storeErrorResponse(
          error.code,
          error.message,
          error.details,
          422,
        );
      } on DemoStoreConflict catch (error) {
        return _storeErrorResponse(
          error.code,
          error.message,
          error.details,
          409,
        );
      } on FormatException {
        return _invalidJsonResponse();
      }
    })
    ..post('/problems/<problemId>/messages', (
      Request request,
      String problemId,
    ) async {
      try {
        final body = await _readJsonBody(request);
        final dto = AddProblemMessageRequestDto.fromJson(body);
        store.addProblemMessage(
          AddProblemMessageCommand(
            requestId: dto.requestId,
            problemId: problemId,
            authorId: dto.authorId,
            message: dto.message,
          ),
        );
        return jsonResponse(
          _toProblemDetailDto(store.getProblem(problemId), store).toJson(),
        );
      } on DemoStoreNotFound catch (error) {
        return _storeErrorResponse(
          error.code,
          error.message,
          error.details,
          404,
        );
      } on DemoStoreValidation catch (error) {
        return _storeErrorResponse(
          error.code,
          error.message,
          error.details,
          422,
        );
      } on DemoStoreConflict catch (error) {
        return _storeErrorResponse(
          error.code,
          error.message,
          error.details,
          409,
        );
      } on FormatException {
        return _invalidJsonResponse();
      }
    })
    ..post('/problems/<problemId>/transition', (
      Request request,
      String problemId,
    ) async {
      try {
        final body = await _readJsonBody(request);
        final dto = TransitionProblemRequestDto.fromJson(body);
        final problem = store.transitionProblem(
          TransitionProblemCommand(
            requestId: dto.requestId,
            problemId: problemId,
            changedBy: dto.changedBy,
            toStatus: _parseProblemStatus(dto.toStatus),
          ),
        );
        return jsonResponse(_toProblemDetailDto(problem, store).toJson());
      } on DemoStoreNotFound catch (error) {
        return _storeErrorResponse(
          error.code,
          error.message,
          error.details,
          404,
        );
      } on DemoStoreValidation catch (error) {
        return _storeErrorResponse(
          error.code,
          error.message,
          error.details,
          422,
        );
      } on DemoStoreConflict catch (error) {
        return _storeErrorResponse(
          error.code,
          error.message,
          error.details,
          409,
        );
      } on FormatException {
        return _invalidJsonResponse();
      }
    })
    ..get('/wip', (Request request) {
      final items = store
          .listWipEntries()
          .map(WipEntryDto.fromDomain)
          .toList(growable: false);
      final dto = ApiListResponseDto(
        items: items,
        meta: const {
          'source': 'local_contract_seed',
          'resource': 'wip_entries',
        },
      );
      return jsonResponse(dto.toJson((item) => item.toJson()));
    })
    ..get('/audit', (Request request) {
      final items = store
          .listAuditEntries()
          .map(AuditEntryDto.fromDomain)
          .toList(growable: false);
      final dto = ApiListResponseDto(
        items: items,
        meta: const {
          'source': 'local_contract_seed',
          'resource': 'audit_entries',
        },
      );
      return jsonResponse(dto.toJson((item) => item.toJson()));
    });

  return router;
}

Future<Map<String, Object?>> _readJsonBody(Request request) async {
  final body = await request.readAsString();
  final decoded = jsonDecode(body);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Request body must be a JSON object.');
  }

  return decoded;
}

Response _invalidJsonResponse() {
  return jsonResponse(
    const ApiErrorDto(
      code: 'invalid_request',
      message: 'Request body must be a valid JSON object.',
    ).toJson(),
    statusCode: 400,
  );
}

Response _importErrorResponse(ImportSessionException error) {
  return jsonResponse(
    ApiErrorDto(
      code: error.code,
      message: error.message,
      details: error.details,
    ).toJson(),
    statusCode: error.statusCode,
  );
}

Response _storeErrorResponse(
  String code,
  String message,
  Map<String, Object?> details,
  int statusCode,
) {
  return jsonResponse(
    ApiErrorDto(code: code, message: message, details: details).toJson(),
    statusCode: statusCode,
  );
}

TaskSummaryDto _toTaskSummaryDto(ProductionTask task, DemoContractStore store) {
  final projection = _buildTaskProjection(task, store);
  return TaskSummaryDto(
    id: task.id,
    planItemId: task.planItemId,
    operationOccurrenceId: task.operationOccurrenceId,
    requiredQuantity: task.requiredQuantity,
    assigneeId: task.assigneeId,
    status: task.status.name,
    isClosed: task.isClosed,
    machineId: projection.machineId,
    versionId: projection.versionId,
    structureOccurrenceId: projection.structureOccurrenceId,
    structureDisplayName: projection.structureDisplayName,
    operationName: projection.operationName,
    workshop: projection.workshop,
    reportedQuantity: projection.reportedQuantity,
    remainingQuantity: projection.remainingQuantity,
  );
}

PlanDetailDto _toPlanDetailDto(Plan plan, DemoContractStore store) {
  final items = plan.items
      .map((item) {
        final occurrence = store.getStructureOccurrence(
          item.structureOccurrenceId,
        );
        return PlanDetailItemDto.fromDomain(
          item,
          occurrence: occurrence,
          canEdit: plan.canEditItem(item),
        );
      })
      .toList(growable: false);
  return PlanDetailDto.fromDomain(plan, items: items);
}

TaskDetailDto _toTaskDetailDto(ProductionTask task, DemoContractStore store) {
  final projection = _buildTaskProjection(task, store);
  return TaskDetailDto(
    id: task.id,
    planItemId: task.planItemId,
    operationOccurrenceId: task.operationOccurrenceId,
    machineId: projection.machineId,
    versionId: projection.versionId,
    structureOccurrenceId: projection.structureOccurrenceId,
    structureDisplayName: projection.structureDisplayName,
    operationName: projection.operationName,
    workshop: projection.workshop,
    requiredQuantity: task.requiredQuantity,
    reportedQuantity: projection.reportedQuantity,
    remainingQuantity: projection.remainingQuantity,
    assigneeId: task.assigneeId,
    status: task.status.name,
    isClosed: task.isClosed,
  );
}

_TaskProjection _buildTaskProjection(
  ProductionTask task,
  DemoContractStore store,
) {
  final operation = store.getOperationOccurrence(task.operationOccurrenceId);
  final occurrence = store.getStructureOccurrence(
    operation.structureOccurrenceId,
  );
  final plan = store.getPlanByItemId(task.planItemId);
  final reportedQuantity = store.reportedQuantityForTask(task.id);
  final remainingQuantity = reportedQuantity >= task.requiredQuantity
      ? 0.0
      : task.requiredQuantity - reportedQuantity;
  return _TaskProjection(
    machineId: plan.machineId,
    versionId: plan.versionId,
    structureOccurrenceId: occurrence.id,
    structureDisplayName: occurrence.displayName,
    operationName: operation.name,
    workshop: operation.workshop ?? occurrence.workshop ?? '',
    reportedQuantity: reportedQuantity,
    remainingQuantity: remainingQuantity,
  );
}

ExecutionReportOutcome _parseExecutionReportOutcome(String value) {
  return switch (value) {
    'completed' => ExecutionReportOutcome.completed,
    'partial' => ExecutionReportOutcome.partial,
    'not_completed' => ExecutionReportOutcome.notCompleted,
    'overrun' => ExecutionReportOutcome.overrun,
    _ => throw const DemoStoreValidation(
      'invalid_report_outcome',
      'Execution report outcome is not supported.',
    ),
  };
}

ProblemSummaryDto _toProblemSummaryDto(
  Problem problem,
  DemoContractStore store,
) {
  return ProblemSummaryDto(
    id: problem.id,
    machineId: problem.machineId,
    type: _problemTypeToApi(problem.type),
    taskId: problem.taskId,
    title: problem.title,
    status: problem.status.name,
    isOpen: problem.isOpen,
    createdAt: problem.createdAt,
    messageCount: store.problemMessageCount(problem.id),
  );
}

ProblemDetailDto _toProblemDetailDto(Problem problem, DemoContractStore store) {
  final messages = store
      .listProblemMessages(problem.id)
      .map(ProblemMessageDto.fromDomain)
      .toList(growable: false);
  return ProblemDetailDto(
    id: problem.id,
    machineId: problem.machineId,
    type: _problemTypeToApi(problem.type),
    taskId: problem.taskId,
    title: problem.title,
    status: problem.status.name,
    isOpen: problem.isOpen,
    createdAt: problem.createdAt,
    messages: messages,
  );
}

ProblemType _parseProblemType(String value) {
  return switch (value) {
    'equipment' => ProblemType.equipment,
    'materials' => ProblemType.materials,
    'documentation' => ProblemType.documentation,
    'planning_error' => ProblemType.planningError,
    'technology_error' => ProblemType.technologyError,
    'blocked_by_other_workshop' => ProblemType.blockedByOtherWorkshop,
    'other' => ProblemType.other,
    _ => throw const DemoStoreValidation(
      'invalid_problem_type',
      'Problem type is not supported.',
    ),
  };
}

ProblemStatus _parseProblemStatus(String value) {
  return switch (value) {
    'inProgress' => ProblemStatus.inProgress,
    'closed' => ProblemStatus.closed,
    _ => throw const DemoStoreValidation(
      'problem_transition_not_allowed',
      'Problem transition target status is not supported.',
    ),
  };
}

String _problemTypeToApi(ProblemType type) {
  return switch (type) {
    ProblemType.equipment => 'equipment',
    ProblemType.materials => 'materials',
    ProblemType.documentation => 'documentation',
    ProblemType.planningError => 'planning_error',
    ProblemType.technologyError => 'technology_error',
    ProblemType.blockedByOtherWorkshop => 'blocked_by_other_workshop',
    ProblemType.other => 'other',
  };
}

class _TaskProjection {
  const _TaskProjection({
    required this.machineId,
    required this.versionId,
    required this.structureOccurrenceId,
    required this.structureDisplayName,
    required this.operationName,
    required this.workshop,
    required this.reportedQuantity,
    required this.remainingQuantity,
  });

  final String machineId;
  final String versionId;
  final String structureOccurrenceId;
  final String structureDisplayName;
  final String operationName;
  final String workshop;
  final double reportedQuantity;
  final double remainingQuantity;
}
