import 'package:data_models/data_models.dart';

abstract interface class MasterBackendClient {
  Future<ApiListResponseDto<TaskSummaryDto>> listTasks({
    String? assigneeId,
    String? status,
  });

  Future<TaskDetailDto> getTask(String taskId);

  Future<ApiListResponseDto<ExecutionReportDto>> listReports(String taskId);

  Future<ApiListResponseDto<ProblemSummaryDto>> listProblems({
    String? taskId,
    String? status,
  });

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

  Future<CreateExecutionReportResultDto> createExecutionReport(
    String taskId,
    CreateExecutionReportRequestDto request,
  );

  void dispose();
}

class MasterBackendException implements Exception {
  const MasterBackendException({
    required this.message,
    this.code = 'transport_error',
    this.statusCode,
    this.details = const <String, Object?>{},
  });

  factory MasterBackendException.fromApiError(
    ApiErrorDto error, {
    int? statusCode,
  }) {
    return MasterBackendException(
      code: error.code,
      message: error.message,
      statusCode: statusCode,
      details: error.details,
    );
  }

  final String code;
  final Map<String, Object?> details;
  final String message;
  final int? statusCode;

  @override
  String toString() {
    return 'MasterBackendException(code: $code, statusCode: $statusCode, message: $message)';
  }
}
