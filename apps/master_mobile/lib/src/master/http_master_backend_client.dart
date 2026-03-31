import 'dart:convert';
import 'dart:io';

import 'package:data_models/data_models.dart';
import 'package:http/http.dart' as http;

import 'master_backend_client.dart';

class HttpMasterBackendClient implements MasterBackendClient {
  HttpMasterBackendClient({Uri? baseUri, http.Client? httpClient})
    : _baseUri = baseUri ?? Uri.parse('http://127.0.0.1:8080'),
      _httpClient = httpClient ?? http.Client();

  final Uri _baseUri;
  final http.Client _httpClient;

  @override
  Future<ApiListResponseDto<TaskSummaryDto>> listTasks({
    String? assigneeId,
    String? status,
  }) async {
    final queryParameters = <String, String>{
      if (assigneeId != null && assigneeId.isNotEmpty) 'assigneeId': assigneeId,
      if (status != null && status.isNotEmpty) 'status': status,
    };
    final json = await _getJsonObject(
      '/v1/tasks',
      queryParameters: queryParameters,
    );
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
  Future<ApiListResponseDto<ExecutionReportDto>> listReports(
    String taskId,
  ) async {
    final json = await _getJsonObject('/v1/tasks/$taskId/reports');
    return ApiListResponseDto<ExecutionReportDto>.fromJson(
      json,
      ExecutionReportDto.fromJson,
    );
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
    final json = await _getJsonObject(
      '/v1/problems',
      queryParameters: queryParameters,
    );
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
  void dispose() {
    _httpClient.close();
  }

  Future<Map<String, Object?>> _getJsonObject(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    try {
      final uri = _baseUri
          .resolve(path)
          .replace(queryParameters: queryParameters);
      final response = await _httpClient.get(uri);
      return _decodeResponseObject(response);
    } on SocketException catch (error) {
      throw MasterBackendException(
        message: 'Backend is unavailable: ${error.message}.',
      );
    } on http.ClientException catch (error) {
      throw MasterBackendException(
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
      throw MasterBackendException(
        message: 'Backend is unavailable: ${error.message}.',
      );
    } on http.ClientException catch (error) {
      throw MasterBackendException(
        message: 'HTTP client failed: ${error.message}.',
      );
    }
  }

  Map<String, Object?> _decodeResponseObject(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const MasterBackendException(
        code: 'invalid_response',
        message: 'Backend returned a non-object JSON payload.',
      );
    }

    final body = decoded.cast<String, Object?>();
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw MasterBackendException.fromApiError(
      ApiErrorDto.fromJson(body),
      statusCode: response.statusCode,
    );
  }
}
