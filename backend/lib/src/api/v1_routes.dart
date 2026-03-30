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
        meta: const {
          'source': 'local_contract_seed',
          'resource': 'machines',
        },
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
                operationCount: store.operationCountForOccurrence(occurrence.id),
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
        return _storeErrorResponse(error.code, error.message, error.details, 404);
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
        meta: const {
          'source': 'local_contract_seed',
          'resource': 'plans',
        },
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
            items: dto
                .items
                .map(
                  (item) => CreatePlanItemCommand(
                    structureOccurrenceId: item.structureOccurrenceId,
                    requestedQuantity: item.requestedQuantity,
                  ),
                )
                .toList(growable: false),
          ),
        );
        return jsonResponse(_toPlanDetailDto(plan, store).toJson(), statusCode: 201);
      } on DemoStoreNotFound catch (error) {
        return _storeErrorResponse(error.code, error.message, error.details, 404);
      } on DemoStoreValidation catch (error) {
        return _storeErrorResponse(error.code, error.message, error.details, 422);
      } on DemoStoreConflict catch (error) {
        return _storeErrorResponse(error.code, error.message, error.details, 409);
      } on FormatException {
        return _invalidJsonResponse();
      }
    })
    ..get('/plans/<planId>', (Request request, String planId) {
      try {
        final plan = store.getPlan(planId);
        return jsonResponse(_toPlanDetailDto(plan, store).toJson());
      } on DemoStoreNotFound catch (error) {
        return _storeErrorResponse(error.code, error.message, error.details, 404);
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
        return _storeErrorResponse(error.code, error.message, error.details, 404);
      } on DemoStoreValidation catch (error) {
        return _storeErrorResponse(error.code, error.message, error.details, 422);
      } on DemoStoreConflict catch (error) {
        return _storeErrorResponse(error.code, error.message, error.details, 409);
      } on FormatException {
        return _invalidJsonResponse();
      }
    })
    ..get('/tasks', (Request request) {
      final items = store
          .listTasks()
          .map(TaskSummaryDto.fromDomain)
          .toList(growable: false);
      final dto = ApiListResponseDto(
        items: items,
        meta: const {
          'source': 'local_contract_seed',
          'resource': 'tasks',
        },
      );
      return jsonResponse(dto.toJson((item) => item.toJson()));
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
    ..get('/problems', (Request request) {
      final items = store
          .listProblems()
          .map(ProblemSummaryDto.fromDomain)
          .toList(growable: false);
      final dto = ApiListResponseDto(
        items: items,
        meta: const {
          'source': 'local_contract_seed',
          'resource': 'problems',
        },
      );
      return jsonResponse(dto.toJson((item) => item.toJson()));
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

PlanDetailDto _toPlanDetailDto(Plan plan, DemoContractStore store) {
  final items = plan.items
      .map((item) {
        final occurrence = store.getStructureOccurrence(item.structureOccurrenceId);
        return PlanDetailItemDto.fromDomain(
          item,
          occurrence: occurrence,
          canEdit: plan.canEditItem(item),
        );
      })
      .toList(growable: false);
  return PlanDetailDto.fromDomain(plan, items: items);
}
