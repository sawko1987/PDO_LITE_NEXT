import 'package:data_models/data_models.dart';

abstract interface class AdminBackendClient {
  Future<ApiListResponseDto<MachineSummaryDto>> listMachines();

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
