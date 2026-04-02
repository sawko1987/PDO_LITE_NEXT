import 'dart:convert';
import 'dart:io';

import 'package:data_models/data_models.dart';
import 'package:domain/domain.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../import/import_session.dart';
import '../import/import_session_service.dart';
import '../store/demo_contract_store.dart';
import 'auth_middleware.dart';
import 'json_response.dart';

Router buildV1Router(
  DemoContractStore store,
  ImportSessionService importSessionService,
  DateTime serviceStartedAt,
) {
  final router = Router()
    ..post('/auth/login', (Request request) async {
      try {
        final body = await _readJsonBody(request);
        final dto = LoginRequestDto.fromJson(body);
        final session = store.login(login: dto.login, password: dto.password);
        final user = store.getUser(session.userId);
        return jsonResponse(
          LoginResponseDto(
            token: session.token,
            userId: user.id,
            role: session.role.name,
            displayName: user.displayName,
            expiresAt: session.expiresAt,
          ).toJson(),
        );
      } on DemoStoreUnauthorized catch (error) {
        return _storeErrorResponse(
          error.code,
          error.message,
          error.details,
          401,
        );
      } on DemoStoreForbidden catch (error) {
        return _storeErrorResponse(
          error.code,
          error.message,
          error.details,
          403,
        );
      } on FormatException {
        return _invalidJsonResponse();
      }
    })
    ..post('/auth/logout', (Request request) {
      final token = _extractBearerToken(request);
      if (token == null) {
        return unauthorizedResponse();
      }
      store.logout(token);
      return jsonResponse({'ok': true});
    })
    ..get('/users', (Request request) {
      final session = _requireAuthSession(request);
      if (!session.role.canViewUsers) {
        return forbiddenResponse();
      }
      final items = store
          .listUsers()
          .map(UserSummaryDto.fromDomain)
          .toList(growable: false);
      final dto = ApiListResponseDto(
        items: items,
        meta: const {'resource': 'users'},
      );
      return jsonResponse(dto.toJson((item) => item.toJson()));
    })
    ..post('/users', (Request request) async {
      final session = _requireAuthSession(request);
      if (!session.role.canManageUsers) {
        return forbiddenResponse();
      }
      try {
        final body = await _readJsonBody(request);
        final dto = CreateUserRequestDto.fromJson(body);
        final role = _parseUserRole(dto.role);
        final user = store.createUser(
          CreateUserCommand(
            requestId: dto.requestId,
            login: dto.login,
            password: dto.password,
            role: role,
            displayName: dto.displayName,
            createdBy: session.userId,
          ),
        );
        return jsonResponse(
          UserSummaryDto.fromDomain(user).toJson(),
          statusCode: 201,
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
    ..post('/users/<userId>/deactivate', (
      Request request,
      String userId,
    ) async {
      final session = _requireAuthSession(request);
      if (!session.role.canManageUsers) {
        return forbiddenResponse();
      }
      try {
        final body = await _readJsonBody(request);
        final dto = RequestIdDto.fromJson(body);
        final user = store.deactivateUser(
          DeactivateUserCommand(
            requestId: dto.requestId,
            userId: userId,
            changedBy: session.userId,
          ),
        );
        return jsonResponse(UserSummaryDto.fromDomain(user).toJson());
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
    ..post('/users/<userId>/reset-password', (
      Request request,
      String userId,
    ) async {
      final session = _requireAuthSession(request);
      if (!session.role.canManageUsers) {
        return forbiddenResponse();
      }
      try {
        final body = await _readJsonBody(request);
        final dto = ResetPasswordRequestDto.fromJson(body);
        final user = store.resetPassword(
          ResetPasswordCommand(
            requestId: dto.requestId,
            userId: userId,
            newPassword: dto.newPassword,
            changedBy: session.userId,
          ),
        );
        return jsonResponse(UserSummaryDto.fromDomain(user).toJson());
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
    ..get('/machines/<machineId>/versions/<versionId>/detail', (
      Request request,
      String machineId,
      String versionId,
    ) {
      try {
        final detail = store.getMachineVersionDetail(machineId, versionId);
        return jsonResponse(_toMachineVersionDetailDto(detail).toJson());
      } on DemoStoreNotFound catch (error) {
        return _storeErrorResponse(
          error.code,
          error.message,
          error.details,
          404,
        );
      }
    })
    ..post('/machines/<machineId>/versions/<versionId>/draft', (
      Request request,
      String machineId,
      String versionId,
    ) async {
      final session = _requireAuthSession(request);
      if (!session.role.canEditPlan) {
        return forbiddenResponse();
      }
      try {
        final body = await _readJsonBody(request);
        final dto = CreateDraftMachineVersionRequestDto.fromJson(body);
        final version = store.createDraftMachineVersion(
          CreateDraftMachineVersionCommand(
            requestId: dto.requestId,
            machineId: machineId,
            sourceVersionId: versionId,
            createdBy: session.userId,
          ),
        );
        return jsonResponse(
          _toMachineVersionDetailDto(
            store.getMachineVersionDetail(machineId, version.id),
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
    ..post('/machines/<machineId>/versions/<versionId>/structure-occurrences', (
      Request request,
      String machineId,
      String versionId,
    ) async {
      final session = _requireAuthSession(request);
      if (!session.role.canEditPlan) {
        return forbiddenResponse();
      }
      try {
        final body = await _readJsonBody(request);
        final dto = CreateStructureOccurrenceRequestDto.fromJson(body);
        final version = store.createStructureOccurrence(
          CreateStructureOccurrenceCommand(
            requestId: dto.requestId,
            machineId: machineId,
            versionId: versionId,
            createdBy: session.userId,
            displayName: dto.displayName,
            quantityPerMachine: dto.quantityPerMachine,
            parentOccurrenceId: dto.parentOccurrenceId,
            workshop: dto.workshop,
          ),
        );
        return jsonResponse(
          _toMachineVersionDetailDto(
            store.getMachineVersionDetail(machineId, version.id),
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
    ..post(
      '/machines/<machineId>/versions/<versionId>/structure-occurrences/<occurrenceId>/update',
      (
        Request request,
        String machineId,
        String versionId,
        String occurrenceId,
      ) async {
        final session = _requireAuthSession(request);
        if (!session.role.canEditPlan) {
          return forbiddenResponse();
        }
        try {
          final body = await _readJsonBody(request);
          final dto = UpdateStructureOccurrenceRequestDto.fromJson(body);
          final version = store.updateStructureOccurrence(
            UpdateStructureOccurrenceCommand(
              requestId: dto.requestId,
              machineId: machineId,
              versionId: versionId,
              occurrenceId: occurrenceId,
              changedBy: session.userId,
              displayName: dto.displayName,
              quantityPerMachine: dto.quantityPerMachine,
              workshop: dto.workshop,
            ),
          );
          return jsonResponse(
            _toMachineVersionDetailDto(
              store.getMachineVersionDetail(machineId, version.id),
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
      },
    )
    ..post(
      '/machines/<machineId>/versions/<versionId>/structure-occurrences/<occurrenceId>/delete',
      (
        Request request,
        String machineId,
        String versionId,
        String occurrenceId,
      ) async {
        final session = _requireAuthSession(request);
        if (!session.role.canEditPlan) {
          return forbiddenResponse();
        }
        try {
          final body = await _readJsonBody(request);
          final dto = DeleteStructureOccurrenceRequestDto.fromJson(body);
          final version = store.deleteStructureOccurrence(
            DeleteStructureOccurrenceCommand(
              requestId: dto.requestId,
              machineId: machineId,
              versionId: versionId,
              occurrenceId: occurrenceId,
              deletedBy: session.userId,
            ),
          );
          return jsonResponse(
            _toMachineVersionDetailDto(
              store.getMachineVersionDetail(machineId, version.id),
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
      },
    )
    ..post('/machines/<machineId>/versions/<versionId>/operation-occurrences', (
      Request request,
      String machineId,
      String versionId,
    ) async {
      final session = _requireAuthSession(request);
      if (!session.role.canEditPlan) {
        return forbiddenResponse();
      }
      try {
        final body = await _readJsonBody(request);
        final dto = CreateOperationOccurrenceRequestDto.fromJson(body);
        final version = store.createOperationOccurrence(
          CreateOperationOccurrenceCommand(
            requestId: dto.requestId,
            machineId: machineId,
            versionId: versionId,
            structureOccurrenceId: dto.structureOccurrenceId,
            createdBy: session.userId,
            name: dto.name,
            quantityPerMachine: dto.quantityPerMachine,
            workshop: dto.workshop,
          ),
        );
        return jsonResponse(
          _toMachineVersionDetailDto(
            store.getMachineVersionDetail(machineId, version.id),
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
    ..post(
      '/machines/<machineId>/versions/<versionId>/operation-occurrences/<operationId>/update',
      (
        Request request,
        String machineId,
        String versionId,
        String operationId,
      ) async {
        final session = _requireAuthSession(request);
        if (!session.role.canEditPlan) {
          return forbiddenResponse();
        }
        try {
          final body = await _readJsonBody(request);
          final dto = UpdateOperationOccurrenceRequestDto.fromJson(body);
          final version = store.updateOperationOccurrence(
            UpdateOperationOccurrenceCommand(
              requestId: dto.requestId,
              machineId: machineId,
              versionId: versionId,
              operationId: operationId,
              changedBy: session.userId,
              name: dto.name,
              quantityPerMachine: dto.quantityPerMachine,
              workshop: dto.workshop,
            ),
          );
          return jsonResponse(
            _toMachineVersionDetailDto(
              store.getMachineVersionDetail(machineId, version.id),
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
      },
    )
    ..post(
      '/machines/<machineId>/versions/<versionId>/operation-occurrences/<operationId>/delete',
      (
        Request request,
        String machineId,
        String versionId,
        String operationId,
      ) async {
        final session = _requireAuthSession(request);
        if (!session.role.canEditPlan) {
          return forbiddenResponse();
        }
        try {
          final body = await _readJsonBody(request);
          final dto = DeleteOperationOccurrenceRequestDto.fromJson(body);
          final version = store.deleteOperationOccurrence(
            DeleteOperationOccurrenceCommand(
              requestId: dto.requestId,
              machineId: machineId,
              versionId: versionId,
              operationId: operationId,
              deletedBy: session.userId,
            ),
          );
          return jsonResponse(
            _toMachineVersionDetailDto(
              store.getMachineVersionDetail(machineId, version.id),
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
      },
    )
    ..post('/machines/<machineId>/versions/<versionId>/publish', (
      Request request,
      String machineId,
      String versionId,
    ) async {
      final session = _requireAuthSession(request);
      if (!session.role.canEditPlan) {
        return forbiddenResponse();
      }
      try {
        final body = await _readJsonBody(request);
        final dto = PublishMachineVersionRequestDto.fromJson(body);
        final version = store.publishMachineVersion(
          PublishMachineVersionCommand(
            requestId: dto.requestId,
            machineId: machineId,
            versionId: versionId,
            publishedBy: session.userId,
          ),
        );
        return jsonResponse(
          _toMachineVersionDetailDto(
            store.getMachineVersionDetail(machineId, version.id),
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
      final session = _requireAuthSession(request);
      if (!session.role.canEditPlan) {
        return forbiddenResponse();
      }
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
      final session = _requireAuthSession(request);
      if (!session.role.canEditPlan) {
        return forbiddenResponse();
      }
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
      final session = _requireAuthSession(request);
      if (!session.role.canEditPlan) {
        return forbiddenResponse();
      }
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
      final session = _requireAuthSession(request);
      if (!session.role.canEditPlan) {
        return forbiddenResponse();
      }
      try {
        final body = await _readJsonBody(request);
        final dto = ReleasePlanRequestDto.fromJson(body);
        final result = store.releasePlan(
          ReleasePlanCommand(
            requestId: dto.requestId,
            planId: planId,
            releasedBy: session.userId,
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
      final session = _requireAuthSession(request);
      if (!session.role.canClosePlan) {
        return forbiddenResponse(
          message: 'Supervisor role is required to complete a plan.',
        );
      }
      try {
        final body = await _readJsonBody(request);
        final dto = CompletePlanRequestDto.fromJson(body);
        final result = store.completePlan(
          CompletePlanCommand(
            requestId: dto.requestId,
            planId: planId,
            completedBy: session.userId,
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
    ..get('/reports/plan-fact', (Request request) {
      try {
        final machineId = request.url.queryParameters['machineId'];
        final versionId = request.url.queryParameters['versionId'];
        final planId = request.url.queryParameters['planId'];
        final fromDate = _parseOptionalIsoDateTime(
          request.url.queryParameters['fromDate'],
        );
        final toDate = _parseOptionalIsoDateTime(
          request.url.queryParameters['toDate'],
        );
        final items = store
            .listPlanFactReports(
              machineId: machineId,
              versionId: versionId,
              planId: planId,
              fromDate: fromDate,
              toDate: toDate,
            )
            .map(_toPlanFactReportItemDto)
            .toList(growable: false);
        final fromDateQuery = request.url.queryParameters['fromDate'];
        final toDateQuery = request.url.queryParameters['toDate'];
        final dto = ApiListResponseDto(
          items: items,
          meta: {
            'source': 'local_contract_seed',
            'resource': 'plan_fact_reports',
            ...?machineId == null ? null : {'machineId': machineId},
            ...?versionId == null ? null : {'versionId': versionId},
            ...?planId == null ? null : {'planId': planId},
            ...?fromDateQuery == null ? null : {'fromDate': fromDateQuery},
            ...?toDateQuery == null ? null : {'toDate': toDateQuery},
          },
        );
        return jsonResponse(dto.toJson((item) => item.toJson()));
      } on FormatException {
        return _invalidJsonResponse();
      }
    })
    ..get('/reports/shift', (Request request) {
      try {
        final dateRaw = request.url.queryParameters['date'];
        if (dateRaw == null || dateRaw.isEmpty) {
          return _invalidJsonResponse();
        }
        final date = _parseQueryDate(dateRaw);
        final machineId = request.url.queryParameters['machineId'];
        final assigneeId = request.url.queryParameters['assigneeId'];
        final items = store
            .listShiftReports(
              date: date,
              machineId: machineId,
              assigneeId: assigneeId,
            )
            .map(_toShiftReportItemDto)
            .toList(growable: false);
        final dto = ApiListResponseDto(
          items: items,
          meta: {
            'source': 'local_contract_seed',
            'resource': 'shift_reports',
            'date': dateRaw,
            ...?machineId == null ? null : {'machineId': machineId},
            ...?assigneeId == null ? null : {'assigneeId': assigneeId},
          },
        );
        return jsonResponse(dto.toJson((item) => item.toJson()));
      } on FormatException {
        return _invalidJsonResponse();
      }
    })
    ..get('/reports/problems', (Request request) {
      try {
        final machineId = request.url.queryParameters['machineId'];
        final status = request.url.queryParameters['status'];
        final type = request.url.queryParameters['type'];
        final fromDate = _parseOptionalIsoDateTime(
          request.url.queryParameters['fromDate'],
        );
        final toDate = _parseOptionalIsoDateTime(
          request.url.queryParameters['toDate'],
        );
        final items = store
            .listProblemReports(
              machineId: machineId,
              status: status,
              type: type,
              fromDate: fromDate,
              toDate: toDate,
            )
            .map(_toProblemReportItemDto)
            .toList(growable: false);
        final fromDateQuery = request.url.queryParameters['fromDate'];
        final toDateQuery = request.url.queryParameters['toDate'];
        final dto = ApiListResponseDto(
          items: items,
          meta: {
            'source': 'local_contract_seed',
            'resource': 'problem_reports',
            ...?machineId == null ? null : {'machineId': machineId},
            ...?status == null ? null : {'status': status},
            ...?type == null ? null : {'type': type},
            ...?fromDateQuery == null ? null : {'fromDate': fromDateQuery},
            ...?toDateQuery == null ? null : {'toDate': toDateQuery},
          },
        );
        return jsonResponse(dto.toJson((item) => item.toJson()));
      } on FormatException {
        return _invalidJsonResponse();
      }
    })
    ..get('/reports/summary', (Request request) {
      try {
        final machineId = request.url.queryParameters['machineId'];
        final summary = store.getReportSummary(machineId: machineId);
        final dto = ReportSummaryDto(
          totalPlans: summary.totalPlans,
          draftPlans: summary.draftPlans,
          releasedPlans: summary.releasedPlans,
          completedPlans: summary.completedPlans,
          totalTasks: summary.totalTasks,
          activeTasks: summary.activeTasks,
          completedTasks: summary.completedTasks,
          totalProblems: summary.totalProblems,
          openProblems: summary.openProblems,
          closedProblems: summary.closedProblems,
          totalWipEntries: summary.totalWipEntries,
          blockingWipEntries: summary.blockingWipEntries,
          totalExecutionReports: summary.totalExecutionReports,
        );
        return jsonResponse(dto.toJson());
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
          ...?assigneeId == null ? null : {'assigneeId': assigneeId},
          ...?status == null ? null : {'status': status},
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
          ...?taskId == null ? null : {'taskId': taskId},
          ...?status == null ? null : {'status': status},
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
          .map((entry) => _toWipEntryDto(entry, store))
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
      final session = _requireAuthSession(request);
      if (!session.role.canViewAudit) {
        return forbiddenResponse();
      }
      final entityType = request.url.queryParameters['entityType'];
      final entityId = request.url.queryParameters['entityId'];
      final action = request.url.queryParameters['action'];
      final changedBy = request.url.queryParameters['changedBy'];
      final fromDate = _parseOptionalIsoDateTime(
        request.url.queryParameters['fromDate'],
      );
      final toDate = _parseOptionalIsoDateTime(
        request.url.queryParameters['toDate'],
      );
      final limit =
          int.tryParse(request.url.queryParameters['limit'] ?? '100') ?? 100;
      final offset =
          int.tryParse(request.url.queryParameters['offset'] ?? '0') ?? 0;
      final items = store
          .listAuditEntries(
            entityType: entityType,
            entityId: entityId,
            action: action,
            changedBy: changedBy,
            fromDate: fromDate,
            toDate: toDate,
          )
          .skip(offset)
          .take(limit)
          .map(AuditEntryDto.fromDomain)
          .toList(growable: false);
      final total = store
          .listAuditEntries(
            entityType: entityType,
            entityId: entityId,
            action: action,
            changedBy: changedBy,
            fromDate: fromDate,
            toDate: toDate,
          )
          .length;
      final dto = ApiListResponseDto(
        items: items,
        total: total,
        meta: {
          'source': 'local_contract_seed',
          'resource': 'audit_entries',
          'limit': limit,
          'offset': offset,
        },
      );
      return jsonResponse(dto.toJson((item) => item.toJson()));
    })
    ..get('/archive/plans', (Request request) {
      final session = _requireAuthSession(request);
      if (!session.role.canViewAudit) {
        return forbiddenResponse();
      }
      try {
        final machineId = request.url.queryParameters['machineId'];
        final fromDate = request.url.queryParameters['fromDate'];
        final toDate = request.url.queryParameters['toDate'];
        final status = request.url.queryParameters['status'];
        final items = store
            .listArchivePlans(
              machineId: machineId,
              fromDate: fromDate == null ? null : _parseQueryDate(fromDate),
              toDate: toDate == null ? null : _parseQueryDate(toDate),
              status: status,
            )
            .map((plan) => _toPlanArchiveItemDto(plan, store))
            .toList(growable: false);
        final dto = ApiListResponseDto(
          items: items,
          meta: const {'resource': 'archive_plans'},
        );
        return jsonResponse(dto.toJson((item) => item.toJson()));
      } on FormatException {
        return _invalidJsonResponse();
      }
    })
    ..get('/archive/plans/<planId>', (Request request, String planId) {
      final session = _requireAuthSession(request);
      if (!session.role.canViewAudit) {
        return forbiddenResponse();
      }
      try {
        return jsonResponse(
          _toPlanDetailDto(store.getPlan(planId), store).toJson(),
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
    ..get('/archive/plans/<planId>/execution-summary', (
      Request request,
      String planId,
    ) {
      final session = _requireAuthSession(request);
      if (!session.role.canViewAudit) {
        return forbiddenResponse();
      }
      try {
        return jsonResponse(
          _toPlanExecutionSummaryDto(
            store.getPlanExecutionSummary(planId),
          ).toJson(),
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
    ..get('/diagnostics/health-extended', (Request request) {
      final session = _requireAuthSession(request);
      if (!session.role.canViewAudit) {
        return forbiddenResponse();
      }
      final dto = HealthExtendedDto(
        status: 'ok',
        service: 'pdo_lite_next_backend',
        timestamp: DateTime.now().toUtc(),
        databasePath: store.databasePath,
        databaseSizeBytes: store.getDatabaseSizeBytes(),
        totalMachines: store.totalMachines,
        totalPlans: store.totalPlans,
        totalTasks: store.totalTasks,
        totalAuditEntries: store.totalAuditEntries,
        lastAuditAt: store.lastAuditAt,
        uptime: DateTime.now().toUtc().difference(serviceStartedAt).toString(),
      );
      return jsonResponse(dto.toJson());
    })
    ..get('/diagnostics/idempotency-stats', (Request request) {
      final session = _requireAuthSession(request);
      if (!session.role.canViewAudit) {
        return forbiddenResponse();
      }
      final stats = store.getIdempotencyCategoryStats();
      final dto = IdempotencyStatsDto(
        totalRecords: stats.values.fold(0, (sum, count) => sum + count),
        byCategory: stats.entries
            .map(
              (entry) => IdempotencyCategoryStatDto(
                category: entry.key,
                count: entry.value,
              ),
            )
            .toList(growable: false),
      );
      return jsonResponse(dto.toJson());
    })
    ..post('/backup/create', (Request request) async {
      final session = _requireAuthSession(request);
      if (!session.role.canViewAudit) {
        return forbiddenResponse();
      }
      try {
        final body = await _readJsonBody(request);
        final dto = CreateBackupRequestDto.fromJson(body);
        final backup = store.createBackup(
          CreateBackupCommand(
            requestId: dto.requestId,
            createdBy: session.userId,
          ),
        );
        return jsonResponse(_toBackupInfoDto(backup).toJson(), statusCode: 201);
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
      } on FileSystemException catch (error) {
        return _storeErrorResponse('backup_failed', error.message, {
          'path': error.path,
        }, 422);
      }
    })
    ..get('/backup/list', (Request request) {
      final session = _requireAuthSession(request);
      if (!session.role.canViewAudit) {
        return forbiddenResponse();
      }
      final items = store
          .listBackups()
          .map(_toBackupInfoDto)
          .toList(growable: false);
      final dto = ApiListResponseDto(
        items: items,
        meta: const {'resource': 'backups'},
      );
      return jsonResponse(dto.toJson((item) => item.toJson()));
    })
    ..post('/backup/restore', (Request request) async {
      final session = _requireAuthSession(request);
      if (!session.role.canViewAudit) {
        return forbiddenResponse();
      }
      try {
        final body = await _readJsonBody(request);
        final dto = RestoreBackupRequestDto.fromJson(body);
        final result = store.restoreBackup(
          RestoreBackupCommand(
            requestId: dto.requestId,
            backupFileName: dto.backupFileName,
            changedBy: session.userId,
          ),
        );
        return jsonResponse({
          'status': result.status,
          'restoredAt': result.restoredAt.toIso8601String(),
        });
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
      } on FileSystemException catch (error) {
        return _storeErrorResponse('restore_failed', error.message, {
          'path': error.path,
        }, 422);
      }
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

DateTime? _parseOptionalIsoDateTime(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    throw const FormatException('Invalid ISO 8601 date.');
  }
  return parsed.toUtc();
}

DateTime _parseQueryDate(String value) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    throw const FormatException('Invalid YYYY-MM-DD date.');
  }
  return DateTime.utc(
    int.parse(value.substring(0, 4)),
    int.parse(value.substring(5, 7)),
    int.parse(value.substring(8, 10)),
  );
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

AuthSession _requireAuthSession(Request request) {
  final session = authSessionFromRequest(request);
  if (session == null) {
    throw StateError('Authenticated request is missing auth session context.');
  }
  return session;
}

String? _extractBearerToken(Request request) {
  final authorization = request.headers['authorization'];
  if (authorization == null || !authorization.startsWith('Bearer ')) {
    return null;
  }
  return authorization.substring('Bearer '.length).trim();
}

UserRole _parseUserRole(String value) {
  return switch (value) {
    'planner' => UserRole.planner,
    'supervisor' => UserRole.supervisor,
    'master' => UserRole.master,
    _ => throw const DemoStoreValidation(
      'invalid_role',
      'User role is not supported.',
    ),
  };
}

PlanArchiveItemDto _toPlanArchiveItemDto(Plan plan, DemoContractStore store) {
  final machine = store.getMachine(plan.machineId);
  final summary = store.getPlanExecutionSummary(plan.id);
  return PlanArchiveItemDto(
    id: plan.id,
    machineId: plan.machineId,
    machineCode: machine.code,
    versionId: plan.versionId,
    title: plan.title,
    status: plan.status.name,
    createdAt: plan.createdAt,
    completedAt: plan.closedAt ?? plan.createdAt,
    itemCount: plan.items.length,
    totalReported: summary.totalReported,
    completionPercent: summary.completionPercent,
  );
}

PlanExecutionSummaryDto _toPlanExecutionSummaryDto(
  PlanExecutionSummary summary,
) {
  return PlanExecutionSummaryDto(
    planId: summary.planId,
    totalRequested: summary.totalRequested,
    totalReported: summary.totalReported,
    completionPercent: summary.completionPercent,
    taskCount: summary.taskCount,
    closedTaskCount: summary.closedTaskCount,
    problemCount: summary.problemCount,
    wipConsumedCount: summary.wipConsumedCount,
  );
}

BackupInfoDto _toBackupInfoDto(BackupInfo backup) {
  return BackupInfoDto(
    backupId: backup.backupId,
    fileName: backup.fileName,
    createdAt: backup.createdAt,
    sizeBytes: backup.sizeBytes,
    status: backup.status,
  );
}

PlanFactReportItemDto _toPlanFactReportItemDto(PlanFactReportItem item) {
  return PlanFactReportItemDto(
    structureOccurrenceId: item.structureOccurrenceId,
    displayName: item.displayName,
    pathKey: item.pathKey,
    workshop: item.workshop,
    planId: item.planId,
    planTitle: item.planTitle,
    requestedQuantity: item.requestedQuantity,
    reportedQuantity: item.reportedQuantity,
    remainingQuantity: item.remainingQuantity,
    completionPercent: item.completionPercent,
    taskCount: item.taskCount,
    closedTaskCount: item.closedTaskCount,
    operationName: item.operationName,
  );
}

ShiftReportItemDto _toShiftReportItemDto(ShiftReportItem item) {
  return ShiftReportItemDto(
    taskId: item.taskId,
    assigneeId: item.assigneeId,
    structureDisplayName: item.structureDisplayName,
    operationName: item.operationName,
    workshop: item.workshop,
    requiredQuantity: item.requiredQuantity,
    reportedQuantity: item.reportedQuantity,
    remainingQuantity: item.remainingQuantity,
    status: item.status,
    isClosed: item.isClosed,
    reports: item.reports
        .map(
          (report) => ExecutionReportDto(
            id: '',
            taskId: item.taskId,
            reportedBy: report.reportedBy,
            reportedAt: report.reportedAt,
            reportedQuantity: report.reportedQuantity,
            outcome: report.outcome,
            reason: report.reason,
            isAccepted: true,
          ),
        )
        .toList(growable: false),
  );
}

ProblemReportItemDto _toProblemReportItemDto(ProblemReportItem item) {
  return ProblemReportItemDto(
    problemId: item.problemId,
    title: item.title,
    type: item.type,
    status: item.status,
    isOpen: item.isOpen,
    machineId: item.machineId,
    taskId: item.taskId,
    createdAt: item.createdAt,
    closedAt: item.closedAt,
    messageCount: item.messageCount,
    structureDisplayName: item.structureDisplayName,
    operationName: item.operationName,
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
  return PlanDetailDto(
    id: plan.id,
    machineId: plan.machineId,
    versionId: plan.versionId,
    title: plan.title,
    createdAt: plan.createdAt,
    status: plan.status.name,
    canRelease: plan.canRelease,
    itemCount: plan.items.length,
    revisionCount: plan.revisions.length,
    items: items,
    revisions: plan.revisions
        .map(PlanRevisionDto.fromDomain)
        .toList(growable: false),
    executionSummary: _toPlanExecutionSummaryDto(
      store.getPlanExecutionSummary(plan.id),
    ),
  );
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

MachineVersionDetailDto _toMachineVersionDetailDto(
  MachineVersionDetail detail,
) {
  return MachineVersionDetailDto(
    id: detail.version.id,
    machineId: detail.version.machineId,
    label: detail.version.label,
    createdAt: detail.version.createdAt,
    status: detail.version.status.name,
    isImmutable: detail.version.isImmutable,
    isActiveVersion: detail.isActiveVersion,
    structureOccurrences: detail.structureOccurrences
        .map(StructureOccurrenceDetailDto.fromDomain)
        .toList(growable: false),
    operationOccurrences: detail.operationOccurrences
        .map(OperationOccurrenceDetailDto.fromDomain)
        .toList(growable: false),
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

WipEntryDto _toWipEntryDto(WipEntry entry, DemoContractStore store) {
  final operation = store.getOperationOccurrence(entry.operationOccurrenceId);
  final occurrence = store.getStructureOccurrence(entry.structureOccurrenceId);
  return WipEntryDto(
    id: entry.id,
    machineId: entry.machineId,
    versionId: entry.versionId,
    structureOccurrenceId: entry.structureOccurrenceId,
    operationOccurrenceId: entry.operationOccurrenceId,
    balanceQuantity: entry.balanceQuantity,
    status: entry.status.name,
    blocksCompletion: entry.blocksCompletion,
    taskId: entry.taskId,
    planId: store.planIdForTask(entry.taskId),
    structureDisplayName: occurrence.displayName,
    operationName: operation.name,
    workshop: operation.workshop ?? occurrence.workshop,
    sourceReportId: entry.sourceReportId,
    sourceOutcome: switch (entry.sourceOutcome) {
      ExecutionReportOutcome.completed => 'completed',
      ExecutionReportOutcome.partial => 'partial',
      ExecutionReportOutcome.notCompleted => 'not_completed',
      ExecutionReportOutcome.overrun => 'overrun',
      null => null,
    },
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
