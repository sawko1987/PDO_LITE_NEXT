import 'package:data_models/data_models.dart';
import 'package:import_engine/import_engine.dart';

class ImportSessionRecord {
  ImportSessionRecord({
    required this.sessionId,
    required this.previewRequestId,
    required this.previewRequestSignature,
    required this.previewResult,
    required this.createdAt,
  });

  final String sessionId;
  final String previewRequestId;
  final String previewRequestSignature;
  final ImportPreviewResult previewResult;
  final DateTime createdAt;
  DateTime? confirmedAt;
  String? confirmRequestId;
  String? confirmRequestSignature;
  ConfirmImportResultDto? confirmResult;

  String get status => confirmResult == null ? 'preview_ready' : 'confirmed';
}

class ImportSessionException implements Exception {
  const ImportSessionException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.details = const <String, Object?>{},
  });

  final int statusCode;
  final String code;
  final String message;
  final Map<String, Object?> details;
}
