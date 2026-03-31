import 'dart:convert';

import 'package:data_models/data_models.dart';
import 'package:import_engine/import_engine.dart';

import '../store/demo_contract_store.dart';
import 'import_session.dart';

class ImportSessionService {
  ImportSessionService(
    this._store, {
    ImportPreviewService previewService = const ImportPreviewService(),
  }) : _previewService = previewService;

  final DemoContractStore _store;
  final ImportPreviewService _previewService;
  final Map<String, ImportSessionRecord> _sessionsById = {};
  final Map<String, String> _sessionIdByPreviewRequestId = {};
  final Map<String, String> _sessionIdByConfirmRequestId = {};
  int _sessionSequence = 0;

  ImportSessionSummaryDto createPreviewSession(
    CreateImportPreviewRequestDto request,
  ) {
    _validatePreviewRequest(request);
    final requestSignature =
        '${request.fileName}::${request.fileContentBase64}';
    final existingSessionId = _sessionIdByPreviewRequestId[request.requestId];
    if (existingSessionId != null) {
      final existingSession = _sessionsById[existingSessionId]!;
      if (existingSession.previewRequestSignature != requestSignature) {
        throw const ImportSessionException(
          statusCode: 409,
          code: 'import_request_replayed_with_different_payload',
          message: 'Preview requestId was already used with different payload.',
        );
      }

      return _toSessionDto(existingSession);
    }

    final bytes = _decodeBase64(request.fileContentBase64);
    final sessionId = 'import-session-${++_sessionSequence}';
    final previewResult = _previewService.buildPreview(
      machineVersionId: 'preview-$sessionId',
      source: ImportSourceFile(fileName: request.fileName, bytes: bytes),
    );
    final session = ImportSessionRecord(
      sessionId: sessionId,
      previewRequestId: request.requestId,
      previewRequestSignature: requestSignature,
      previewResult: previewResult,
      createdAt: DateTime.now().toUtc(),
    );
    _sessionsById[sessionId] = session;
    _sessionIdByPreviewRequestId[request.requestId] = sessionId;
    return _toSessionDto(session);
  }

  ImportSessionSummaryDto getSession(String sessionId) {
    final session = _sessionsById[sessionId];
    if (session == null) {
      throw ImportSessionException(
        statusCode: 404,
        code: 'import_session_not_found',
        message: 'Import session was not found.',
        details: {'sessionId': sessionId},
      );
    }

    return _toSessionDto(session);
  }

  ConfirmImportResultDto confirmImport(
    String sessionId,
    ConfirmImportRequestDto request,
  ) {
    final session = _sessionsById[sessionId];
    if (session == null) {
      throw ImportSessionException(
        statusCode: 404,
        code: 'import_session_not_found',
        message: 'Import session was not found.',
        details: {'sessionId': sessionId},
      );
    }
    _validateConfirmRequest(request);
    final requestSignature =
        '${request.mode}::${request.targetMachineId ?? ''}';
    final existingConfirmSessionId =
        _sessionIdByConfirmRequestId[request.requestId];
    if (existingConfirmSessionId != null &&
        existingConfirmSessionId != sessionId) {
      throw const ImportSessionException(
        statusCode: 409,
        code: 'import_request_replayed_with_different_payload',
        message:
            'Confirm requestId was already used for another import session.',
      );
    }

    if (session.confirmResult != null) {
      final isSameRequest =
          session.confirmRequestId == request.requestId &&
          session.confirmRequestSignature == requestSignature;
      if (isSameRequest) {
        return session.confirmResult!;
      }

      if (session.confirmRequestId == request.requestId &&
          session.confirmRequestSignature != requestSignature) {
        throw const ImportSessionException(
          statusCode: 409,
          code: 'import_request_replayed_with_different_payload',
          message: 'Confirm requestId was already used with different payload.',
        );
      }

      throw ImportSessionException(
        statusCode: 409,
        code: 'import_session_already_confirmed',
        message: 'Import session was already confirmed.',
        details: {'sessionId': sessionId},
      );
    }

    if (!session.previewResult.canConfirm) {
      throw ImportSessionException(
        statusCode: 422,
        code: 'import_preview_has_conflicts',
        message: 'Import preview has conflicts and cannot be confirmed.',
        details: {'sessionId': sessionId},
      );
    }

    final result = switch (request.mode) {
      'create_machine' => _confirmCreateMachine(session),
      'create_version' => _confirmCreateVersion(
        session,
        request.targetMachineId,
      ),
      _ => throw ImportSessionException(
        statusCode: 400,
        code: 'invalid_request',
        message: 'Unsupported confirm mode.',
        details: {'mode': request.mode},
      ),
    };

    session.confirmedAt = DateTime.now().toUtc();
    session.confirmRequestId = request.requestId;
    session.confirmRequestSignature = requestSignature;
    session.confirmResult = result;
    _sessionIdByConfirmRequestId[request.requestId] = sessionId;
    return result;
  }

  ConfirmImportResultDto _confirmCreateMachine(ImportSessionRecord session) {
    final preview = session.previewResult;
    final machineCode = preview.machineCode?.trim().isNotEmpty == true
        ? preview.machineCode!.trim()
        : 'IMPORTED-${session.sessionId.toUpperCase()}';
    if (_store.hasMachineCode(machineCode)) {
      throw ImportSessionException(
        statusCode: 422,
        code: 'machine_code_already_exists',
        message: 'Machine code already exists. Use create_version instead.',
        details: {'machineCode': machineCode},
      );
    }

    final machineName = preview.machineName?.trim().isNotEmpty == true
        ? preview.machineName!.trim()
        : 'Imported Machine ${session.sessionId}';
    final versionLabel = 'import-${session.sessionId}';
    final createdAt = DateTime.now().toUtc();
    final version = _store.addImportedMachine(
      machineCode: machineCode,
      machineName: machineName,
      versionLabel: versionLabel,
      createdAt: createdAt,
    );

    return ConfirmImportResultDto(
      sessionId: session.sessionId,
      status: 'confirmed',
      mode: 'create_machine',
      machineId: version.machineId,
      versionId: version.id,
      versionLabel: version.label,
    );
  }

  ConfirmImportResultDto _confirmCreateVersion(
    ImportSessionRecord session,
    String? targetMachineId,
  ) {
    if (targetMachineId == null || targetMachineId.trim().isEmpty) {
      throw const ImportSessionException(
        statusCode: 422,
        code: 'target_machine_required_for_create_version',
        message: 'targetMachineId is required for create_version mode.',
      );
    }

    try {
      _store.getMachine(targetMachineId);
    } on DemoStoreNotFound {
      throw ImportSessionException(
        statusCode: 422,
        code: 'target_machine_not_found',
        message: 'Target machine was not found.',
        details: {'targetMachineId': targetMachineId},
      );
    }

    final versionLabel = 'import-${session.sessionId}';
    final version = _store.addImportedVersion(
      targetMachineId: targetMachineId,
      versionLabel: versionLabel,
      createdAt: DateTime.now().toUtc(),
    );
    return ConfirmImportResultDto(
      sessionId: session.sessionId,
      status: 'confirmed',
      mode: 'create_version',
      machineId: version.machineId,
      versionId: version.id,
      versionLabel: version.label,
    );
  }

  ImportSessionSummaryDto _toSessionDto(ImportSessionRecord session) {
    final preview = session.previewResult;
    final previewDto = ImportPreviewDto(
      fileName: preview.sourceInfo.fileName,
      sourceFormat: preview.sourceInfo.format.name,
      detectionReason: preview.sourceInfo.detectionReason,
      rowCount: preview.sourceInfo.rowCount,
      canConfirm: preview.canConfirm,
      catalogItemCount: preview.preview.catalogItems.length,
      structureOccurrenceCount: preview.preview.structureOccurrences.length,
      operationOccurrenceCount: preview.preview.operationOccurrences.length,
      conflictCount: preview.preview.conflicts.length,
      warningCount: preview.warnings.length,
      machineName: preview.machineName,
      machineCode: preview.machineCode,
      conflicts: preview.preview.conflicts
          .map(
            (conflict) => ImportConflictDto(
              rowNumber: conflict.rowNumber,
              reason: conflict.reason,
              candidates: conflict.candidates,
            ),
          )
          .toList(growable: false),
      warnings: preview.warnings
          .map(
            (warning) => ImportWarningDto(
              code: warning.code,
              message: warning.message,
              rowNumber: warning.rowNumber,
            ),
          )
          .toList(growable: false),
      structureOccurrences: preview.preview.structureOccurrences
          .map(StructureOccurrencePreviewDto.fromDomain)
          .toList(growable: false),
      operationOccurrences: preview.preview.operationOccurrences
          .map(OperationOccurrencePreviewDto.fromDomain)
          .toList(growable: false),
    );

    return ImportSessionSummaryDto(
      sessionId: session.sessionId,
      status: session.status,
      createdAt: session.createdAt,
      confirmedAt: session.confirmedAt,
      preview: previewDto,
    );
  }

  List<int> _decodeBase64(String encoded) {
    try {
      return base64.decode(encoded);
    } on FormatException {
      throw const ImportSessionException(
        statusCode: 400,
        code: 'invalid_request',
        message: 'fileContentBase64 is not valid base64.',
      );
    }
  }

  void _validatePreviewRequest(CreateImportPreviewRequestDto request) {
    if (request.requestId.trim().isEmpty ||
        request.fileName.trim().isEmpty ||
        request.fileContentBase64.trim().isEmpty) {
      throw const ImportSessionException(
        statusCode: 400,
        code: 'invalid_request',
        message: 'requestId, fileName, and fileContentBase64 are required.',
      );
    }
  }

  void _validateConfirmRequest(ConfirmImportRequestDto request) {
    if (request.requestId.trim().isEmpty || request.mode.trim().isEmpty) {
      throw const ImportSessionException(
        statusCode: 400,
        code: 'invalid_request',
        message: 'requestId and mode are required.',
      );
    }
  }
}
