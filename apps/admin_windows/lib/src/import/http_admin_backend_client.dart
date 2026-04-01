import 'dart:convert';
import 'dart:io';

import 'package:data_models/data_models.dart';
import 'package:http/http.dart' as http;

import 'admin_backend_client.dart';

class HttpAdminBackendClient implements AdminBackendClient {
  HttpAdminBackendClient({Uri? baseUri, http.Client? httpClient})
    : _baseUri = baseUri ?? Uri.parse('http://127.0.0.1:8080'),
      _httpClient = httpClient ?? http.Client();

  final Uri _baseUri;
  final http.Client _httpClient;

  @override
  Future<ApiListResponseDto<MachineSummaryDto>> listMachines() async {
    final json = await _getJsonObject('/v1/machines');
    return ApiListResponseDto<MachineSummaryDto>.fromJson(
      json,
      MachineSummaryDto.fromJson,
    );
  }

  @override
  Future<ApiListResponseDto<MachineVersionSummaryDto>> listMachineVersions(
    String machineId,
  ) async {
    final json = await _getJsonObject('/v1/machines/$machineId/versions');
    return ApiListResponseDto<MachineVersionSummaryDto>.fromJson(
      json,
      MachineVersionSummaryDto.fromJson,
    );
  }

  @override
  Future<MachineVersionDetailDto> getMachineVersionDetail(
    String machineId,
    String versionId,
  ) async {
    final json = await _getJsonObject(
      '/v1/machines/$machineId/versions/$versionId/detail',
    );
    return MachineVersionDetailDto.fromJson(json);
  }

  @override
  Future<MachineVersionDetailDto> createDraftMachineVersion(
    String machineId,
    String versionId,
    CreateDraftMachineVersionRequestDto request,
  ) async {
    final json = await _postJsonObject(
      '/v1/machines/$machineId/versions/$versionId/draft',
      request.toJson(),
    );
    return MachineVersionDetailDto.fromJson(json);
  }

  @override
  Future<MachineVersionDetailDto> createStructureOccurrence(
    String machineId,
    String versionId,
    CreateStructureOccurrenceRequestDto request,
  ) async {
    final json = await _postJsonObject(
      '/v1/machines/$machineId/versions/$versionId/structure-occurrences',
      request.toJson(),
    );
    return MachineVersionDetailDto.fromJson(json);
  }

  @override
  Future<MachineVersionDetailDto> updateStructureOccurrence(
    String machineId,
    String versionId,
    String occurrenceId,
    UpdateStructureOccurrenceRequestDto request,
  ) async {
    final json = await _postJsonObject(
      '/v1/machines/$machineId/versions/$versionId/structure-occurrences/$occurrenceId/update',
      request.toJson(),
    );
    return MachineVersionDetailDto.fromJson(json);
  }

  @override
  Future<MachineVersionDetailDto> deleteStructureOccurrence(
    String machineId,
    String versionId,
    String occurrenceId,
    DeleteStructureOccurrenceRequestDto request,
  ) async {
    final json = await _postJsonObject(
      '/v1/machines/$machineId/versions/$versionId/structure-occurrences/$occurrenceId/delete',
      request.toJson(),
    );
    return MachineVersionDetailDto.fromJson(json);
  }

  @override
  Future<MachineVersionDetailDto> createOperationOccurrence(
    String machineId,
    String versionId,
    CreateOperationOccurrenceRequestDto request,
  ) async {
    final json = await _postJsonObject(
      '/v1/machines/$machineId/versions/$versionId/operation-occurrences',
      request.toJson(),
    );
    return MachineVersionDetailDto.fromJson(json);
  }

  @override
  Future<MachineVersionDetailDto> updateOperationOccurrence(
    String machineId,
    String versionId,
    String operationId,
    UpdateOperationOccurrenceRequestDto request,
  ) async {
    final json = await _postJsonObject(
      '/v1/machines/$machineId/versions/$versionId/operation-occurrences/$operationId/update',
      request.toJson(),
    );
    return MachineVersionDetailDto.fromJson(json);
  }

  @override
  Future<MachineVersionDetailDto> deleteOperationOccurrence(
    String machineId,
    String versionId,
    String operationId,
    DeleteOperationOccurrenceRequestDto request,
  ) async {
    final json = await _postJsonObject(
      '/v1/machines/$machineId/versions/$versionId/operation-occurrences/$operationId/delete',
      request.toJson(),
    );
    return MachineVersionDetailDto.fromJson(json);
  }

  @override
  Future<MachineVersionDetailDto> publishMachineVersion(
    String machineId,
    String versionId,
    PublishMachineVersionRequestDto request,
  ) async {
    final json = await _postJsonObject(
      '/v1/machines/$machineId/versions/$versionId/publish',
      request.toJson(),
    );
    return MachineVersionDetailDto.fromJson(json);
  }

  @override
  Future<ApiListResponseDto<PlanningSourceOccurrenceDto>> listPlanningSource(
    String machineId,
    String versionId,
  ) async {
    final json = await _getJsonObject(
      '/v1/machines/$machineId/versions/$versionId/planning-source',
    );
    return ApiListResponseDto<PlanningSourceOccurrenceDto>.fromJson(
      json,
      PlanningSourceOccurrenceDto.fromJson,
    );
  }

  @override
  Future<ApiListResponseDto<PlanSummaryDto>> listPlans() async {
    final json = await _getJsonObject('/v1/plans');
    return ApiListResponseDto<PlanSummaryDto>.fromJson(
      json,
      PlanSummaryDto.fromJson,
    );
  }

  @override
  Future<PlanDetailDto> getPlan(String planId) async {
    final json = await _getJsonObject('/v1/plans/$planId');
    return PlanDetailDto.fromJson(json);
  }

  @override
  Future<PlanCompletionDecisionDto> getPlanCompletionDecision(
    String planId,
  ) async {
    final json = await _getJsonObject('/v1/plans/$planId/completion-check');
    return PlanCompletionDecisionDto.fromJson(json);
  }

  @override
  Future<PlanDetailDto> createPlan(CreatePlanRequestDto request) async {
    final json = await _postJsonObject('/v1/plans', request.toJson());
    return PlanDetailDto.fromJson(json);
  }

  @override
  Future<PlanReleaseResultDto> releasePlan(
    String planId,
    ReleasePlanRequestDto request,
  ) async {
    final json = await _postJsonObject(
      '/v1/plans/$planId/release',
      request.toJson(),
    );
    return PlanReleaseResultDto.fromJson(json);
  }

  @override
  Future<PlanCompletionResultDto> completePlan(
    String planId,
    CompletePlanRequestDto request,
  ) async {
    final json = await _postJsonObject(
      '/v1/plans/$planId/complete',
      request.toJson(),
    );
    return PlanCompletionResultDto.fromJson(json);
  }

  @override
  Future<ApiListResponseDto<TaskSummaryDto>> listTasks({String? status}) async {
    final query = status == null || status.isEmpty ? '' : '?status=$status';
    final json = await _getJsonObject('/v1/tasks$query');
    return ApiListResponseDto<TaskSummaryDto>.fromJson(
      json,
      TaskSummaryDto.fromJson,
    );
  }

  @override
  Future<TaskDetailDto> getTask(String taskId) async {
    final json = await _getJsonObject('/v1/tasks/$taskId');
    return TaskDetailDto.fromJson(json);
  }

  @override
  Future<ApiListResponseDto<ExecutionReportDto>> listTaskReports(
    String taskId,
  ) async {
    final json = await _getJsonObject('/v1/tasks/$taskId/reports');
    return ApiListResponseDto<ExecutionReportDto>.fromJson(
      json,
      ExecutionReportDto.fromJson,
    );
  }

  @override
  Future<CreateExecutionReportResultDto> createExecutionReport(
    String taskId,
    CreateExecutionReportRequestDto request,
  ) async {
    final json = await _postJsonObject(
      '/v1/tasks/$taskId/reports',
      request.toJson(),
    );
    return CreateExecutionReportResultDto.fromJson(json);
  }

  @override
  Future<ApiListResponseDto<ProblemSummaryDto>> listProblems({
    String? taskId,
    String? status,
  }) async {
    final queryParameters = <String, String>{
      if (taskId != null && taskId.isNotEmpty) 'taskId': taskId,
      if (status != null && status.isNotEmpty) 'status': status,
    };
    final uri = Uri(
      path: '/v1/problems',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
    final json = await _getJsonObject(uri.toString());
    return ApiListResponseDto<ProblemSummaryDto>.fromJson(
      json,
      ProblemSummaryDto.fromJson,
    );
  }

  @override
  Future<ProblemDetailDto> getProblem(String problemId) async {
    final json = await _getJsonObject('/v1/problems/$problemId');
    return ProblemDetailDto.fromJson(json);
  }

  @override
  Future<ProblemDetailDto> createProblem(
    String taskId,
    CreateProblemRequestDto request,
  ) async {
    final json = await _postJsonObject(
      '/v1/tasks/$taskId/problems',
      request.toJson(),
    );
    return ProblemDetailDto.fromJson(json);
  }

  @override
  Future<ProblemDetailDto> addProblemMessage(
    String problemId,
    AddProblemMessageRequestDto request,
  ) async {
    final json = await _postJsonObject(
      '/v1/problems/$problemId/messages',
      request.toJson(),
    );
    return ProblemDetailDto.fromJson(json);
  }

  @override
  Future<ProblemDetailDto> transitionProblem(
    String problemId,
    TransitionProblemRequestDto request,
  ) async {
    final json = await _postJsonObject(
      '/v1/problems/$problemId/transition',
      request.toJson(),
    );
    return ProblemDetailDto.fromJson(json);
  }

  @override
  Future<ApiListResponseDto<WipEntryDto>> listWipEntries() async {
    final json = await _getJsonObject('/v1/wip');
    return ApiListResponseDto<WipEntryDto>.fromJson(json, WipEntryDto.fromJson);
  }

  @override
  Future<ImportSessionSummaryDto> createImportPreview(
    CreateImportPreviewRequestDto request,
  ) async {
    final json = await _postJsonObject(
      '/v1/import-sessions/preview',
      request.toJson(),
    );
    return ImportSessionSummaryDto.fromJson(json);
  }

  @override
  Future<ImportSessionSummaryDto> getImportSession(String sessionId) async {
    final json = await _getJsonObject('/v1/import-sessions/$sessionId');
    return ImportSessionSummaryDto.fromJson(json);
  }

  @override
  Future<ConfirmImportResultDto> confirmImport(
    String sessionId,
    ConfirmImportRequestDto request,
  ) async {
    final json = await _postJsonObject(
      '/v1/import-sessions/$sessionId/confirm',
      request.toJson(),
    );
    return ConfirmImportResultDto.fromJson(json);
  }

  @override
  void dispose() {
    _httpClient.close();
  }

  Future<Map<String, Object?>> _getJsonObject(String path) async {
    try {
      final response = await _httpClient.get(_baseUri.resolve(path));
      return _decodeResponseObject(response);
    } on SocketException catch (error) {
      throw AdminBackendException(
        message: 'Backend is unavailable: ${error.message}.',
      );
    } on http.ClientException catch (error) {
      throw AdminBackendException(
        message: 'HTTP client failed: ${error.message}.',
      );
    }
  }

  Future<Map<String, Object?>> _postJsonObject(
    String path,
    Map<String, Object?> body,
  ) async {
    try {
      final response = await _httpClient.post(
        _baseUri.resolve(path),
        headers: const {'content-type': 'application/json'},
        body: jsonEncode(body),
      );
      return _decodeResponseObject(response);
    } on SocketException catch (error) {
      throw AdminBackendException(
        message: 'Backend is unavailable: ${error.message}.',
      );
    } on http.ClientException catch (error) {
      throw AdminBackendException(
        message: 'HTTP client failed: ${error.message}.',
      );
    }
  }

  Map<String, Object?> _decodeResponseObject(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const AdminBackendException(
        code: 'invalid_response',
        message: 'Backend returned a non-object JSON payload.',
      );
    }

    final body = decoded.cast<String, Object?>();
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw AdminBackendException.fromApiError(
      ApiErrorDto.fromJson(body),
      statusCode: response.statusCode,
    );
  }
}
