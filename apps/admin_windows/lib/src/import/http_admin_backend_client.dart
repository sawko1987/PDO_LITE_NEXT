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
