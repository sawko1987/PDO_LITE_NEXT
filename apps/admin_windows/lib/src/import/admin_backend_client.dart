import 'package:data_models/data_models.dart';

abstract interface class AdminBackendClient {
  Future<LoginResponseDto> login(LoginRequestDto request);

  Future<void> logout();

  Future<ApiListResponseDto<MachineSummaryDto>> listMachines();

  Future<ApiListResponseDto<MachineVersionSummaryDto>> listMachineVersions(
    String machineId,
  );

  Future<MachineVersionDetailDto> getMachineVersionDetail(
    String machineId,
    String versionId,
  );

  Future<MachineVersionDetailDto> createDraftMachineVersion(
    String machineId,
    String versionId,
    CreateDraftMachineVersionRequestDto request,
  );

  Future<MachineVersionDetailDto> createStructureOccurrence(
    String machineId,
    String versionId,
    CreateStructureOccurrenceRequestDto request,
  );

  Future<MachineVersionDetailDto> updateStructureOccurrence(
    String machineId,
    String versionId,
    String occurrenceId,
    UpdateStructureOccurrenceRequestDto request,
  );

  Future<MachineVersionDetailDto> deleteStructureOccurrence(
    String machineId,
    String versionId,
    String occurrenceId,
    DeleteStructureOccurrenceRequestDto request,
  );

  Future<MachineVersionDetailDto> createOperationOccurrence(
    String machineId,
    String versionId,
    CreateOperationOccurrenceRequestDto request,
  );

  Future<MachineVersionDetailDto> updateOperationOccurrence(
    String machineId,
    String versionId,
    String operationId,
    UpdateOperationOccurrenceRequestDto request,
  );

  Future<MachineVersionDetailDto> deleteOperationOccurrence(
    String machineId,
    String versionId,
    String operationId,
    DeleteOperationOccurrenceRequestDto request,
  );

  Future<MachineVersionDetailDto> publishMachineVersion(
    String machineId,
    String versionId,
    PublishMachineVersionRequestDto request,
  );

  Future<ApiListResponseDto<PlanningSourceOccurrenceDto>> listPlanningSource(
    String machineId,
    String versionId,
  );

  Future<ApiListResponseDto<PlanSummaryDto>> listPlans();

  Future<ApiListResponseDto<PlanArchiveItemDto>> listArchivePlans({
    String? machineId,
    String? fromDate,
    String? toDate,
    String? status,
  });

  Future<PlanDetailDto> getArchivePlan(String planId);

  Future<PlanExecutionSummaryDto> getArchivePlanExecutionSummary(String planId);

  Future<PlanDetailDto> getPlan(String planId);

  Future<PlanCompletionDecisionDto> getPlanCompletionDecision(String planId);

  Future<PlanDetailDto> createPlan(CreatePlanRequestDto request);

  Future<PlanReleaseResultDto> releasePlan(
    String planId,
    ReleasePlanRequestDto request,
  );

  Future<PlanCompletionResultDto> completePlan(
    String planId,
    CompletePlanRequestDto request,
  );

  Future<ApiListResponseDto<TaskSummaryDto>> listTasks({String? status});

  Future<TaskDetailDto> getTask(String taskId);

  Future<ApiListResponseDto<ExecutionReportDto>> listTaskReports(String taskId);

  Future<CreateExecutionReportResultDto> createExecutionReport(
    String taskId,
    CreateExecutionReportRequestDto request,
  );

  Future<ApiListResponseDto<ProblemSummaryDto>> listProblems({
    String? taskId,
    String? status,
  });

  Future<ApiListResponseDto<UserSummaryDto>> listUsers();

  Future<UserSummaryDto> createUser(CreateUserRequestDto request);

  Future<UserSummaryDto> deactivateUser(String userId, RequestIdDto request);

  Future<UserSummaryDto> resetUserPassword(
    String userId,
    ResetPasswordRequestDto request,
  );

  Future<ApiListResponseDto<AuditEntryDto>> listAuditEntries({
    String? entityType,
    String? entityId,
    String? action,
    String? changedBy,
    String? fromDate,
    String? toDate,
    int? limit,
    int? offset,
  });

  Future<ApiListResponseDto<PlanFactReportItemDto>> getPlanFactReport({
    String? machineId,
    String? versionId,
    String? planId,
    String? fromDate,
    String? toDate,
  });

  Future<ApiListResponseDto<ShiftReportItemDto>> getShiftReport({
    required String date,
    String? machineId,
    String? assigneeId,
  });

  Future<ApiListResponseDto<ProblemReportItemDto>> getProblemReport({
    String? machineId,
    String? status,
    String? type,
    String? fromDate,
    String? toDate,
  });

  Future<ReportSummaryDto> getReportSummary({String? machineId});

  Future<HealthExtendedDto> getHealthExtended();

  Future<IdempotencyStatsDto> getIdempotencyStats();

  Future<ProblemDetailDto> getProblem(String problemId);

  Future<ProblemDetailDto> createProblem(
    String taskId,
    CreateProblemRequestDto request,
  );

  Future<ProblemDetailDto> addProblemMessage(
    String problemId,
    AddProblemMessageRequestDto request,
  );

  Future<ProblemDetailDto> transitionProblem(
    String problemId,
    TransitionProblemRequestDto request,
  );

  Future<ApiListResponseDto<WipEntryDto>> listWipEntries();

  Future<BackupInfoDto> createBackup(CreateBackupRequestDto request);

  Future<ApiListResponseDto<BackupInfoDto>> listBackups();

  Future<RestoreBackupResponseDto> restoreBackup(
    RestoreBackupRequestDto request,
  );

  Future<ImportSessionSummaryDto> createImportPreview(
    CreateImportPreviewRequestDto request,
  );

  Future<ImportSessionSummaryDto> getImportSession(String sessionId);

  Future<ConfirmImportResultDto> confirmImport(
    String sessionId,
    ConfirmImportRequestDto request,
  );

  void dispose();
}

class AdminBackendException implements Exception {
  const AdminBackendException({
    required this.message,
    this.code = 'transport_error',
    this.statusCode,
    this.details = const <String, Object?>{},
  });

  factory AdminBackendException.fromApiError(
    ApiErrorDto error, {
    int? statusCode,
  }) {
    return AdminBackendException(
      code: error.code,
      message: error.message,
      statusCode: statusCode,
      details: error.details,
    );
  }

  final String code;
  final String message;
  final int? statusCode;
  final Map<String, Object?> details;

  @override
  String toString() {
    return 'AdminBackendException(code: $code, statusCode: $statusCode, message: $message)';
  }
}
