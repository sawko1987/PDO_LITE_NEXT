import 'dart:convert';
import 'dart:io';

import 'package:backend/backend.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  test('health endpoint returns ok', () async {
    final handler = buildHandler();
    final response = await handler(
      Request('GET', Uri.parse('http://localhost/health')),
    );
    final body = jsonDecode(await response.readAsString()) as Map<String, dynamic>;

    expect(response.statusCode, 200);
    expect(body['status'], 'ok');
  });

  test('machines endpoint returns contract list response', () async {
    final handler = buildHandler();
    final response = await handler(
      Request('GET', Uri.parse('http://localhost/v1/machines')),
    );
    final body = jsonDecode(await response.readAsString()) as Map<String, dynamic>;

    expect(response.statusCode, 200);
    expect(body['count'], 1);
    expect((body['items'] as List).single['code'], 'PDO-100');
    expect((body['meta'] as Map<String, dynamic>)['resource'], 'machines');
  });

  test('machine versions endpoint returns immutable flag', () async {
    final handler = buildHandler();
    final response = await handler(
      Request(
        'GET',
        Uri.parse('http://localhost/v1/machines/machine-1/versions'),
      ),
    );
    final body = jsonDecode(await response.readAsString()) as Map<String, dynamic>;

    expect(response.statusCode, 200);
    expect(body['count'], 2);
    expect((body['items'] as List).first['isImmutable'], isTrue);
  });

  test('unknown machine returns error envelope', () async {
    final handler = buildHandler();
    final response = await handler(
      Request(
        'GET',
        Uri.parse('http://localhost/v1/machines/missing/versions'),
      ),
    );
    final body = jsonDecode(await response.readAsString()) as Map<String, dynamic>;

    expect(response.statusCode, 404);
    expect((body['error'] as Map<String, dynamic>)['code'], 'machine_not_found');
  });

  test('task reports endpoint returns execution history', () async {
    final handler = buildHandler();
    final response = await handler(
      Request(
        'GET',
        Uri.parse('http://localhost/v1/tasks/task-1/reports'),
      ),
    );
    final body = jsonDecode(await response.readAsString()) as Map<String, dynamic>;

    expect(response.statusCode, 200);
    expect(body['count'], 1);
    expect((body['items'] as List).single['isAccepted'], isTrue);
  });

  test('preview session endpoint creates import session from xlsx', () async {
    final handler = buildHandler();
    final response = await handler(
      _jsonRequest(
        'POST',
        'http://localhost/v1/import-sessions/preview',
        {
          'requestId': 'preview-1',
          'fileName': 'valid_import.xlsx',
          'fileContentBase64': _readFixture('valid_import.xlsx.b64')
              .replaceAll(RegExp(r'\s+'), ''),
        },
      ),
    );
    final body = jsonDecode(await response.readAsString()) as Map<String, dynamic>;

    expect(response.statusCode, 201);
    expect(body['status'], 'preview_ready');
    expect((body['preview'] as Map<String, dynamic>)['sourceFormat'], 'excel');
    expect((body['preview'] as Map<String, dynamic>)['canConfirm'], isTrue);
    expect(
      (body['preview'] as Map<String, dynamic>)['structureOccurrenceCount'],
      2,
    );
  });

  test('get import session returns previously created preview', () async {
    final handler = buildHandler();
    final previewResponse = await handler(
      _jsonRequest(
        'POST',
        'http://localhost/v1/import-sessions/preview',
        {
          'requestId': 'preview-2',
          'fileName': 'valid_import.mxl',
          'fileContentBase64': base64.encode(
            utf8.encode(_readFixture('valid_import.mxl')),
          ),
        },
      ),
    );
    final previewBody =
        jsonDecode(await previewResponse.readAsString()) as Map<String, dynamic>;
    final sessionId = previewBody['sessionId'] as String;

    final getResponse = await handler(
      Request('GET', Uri.parse('http://localhost/v1/import-sessions/$sessionId')),
    );
    final getBody = jsonDecode(await getResponse.readAsString()) as Map<String, dynamic>;

    expect(getResponse.statusCode, 200);
    expect(getBody['sessionId'], sessionId);
    expect((getBody['preview'] as Map<String, dynamic>)['sourceFormat'], 'mxl');
  });

  test('confirm create_machine adds machine visible in machines endpoint', () async {
    final handler = buildHandler();
    final previewResponse = await handler(
      _jsonRequest(
        'POST',
        'http://localhost/v1/import-sessions/preview',
        {
          'requestId': 'preview-create-machine',
          'fileName': 'valid_import.mxl',
          'fileContentBase64': base64.encode(
            utf8.encode(_readFixture('valid_import.mxl')),
          ),
        },
      ),
    );
    final previewBody =
        jsonDecode(await previewResponse.readAsString()) as Map<String, dynamic>;
    final sessionId = previewBody['sessionId'] as String;

    final confirmResponse = await handler(
      _jsonRequest(
        'POST',
        'http://localhost/v1/import-sessions/$sessionId/confirm',
        {
          'requestId': 'confirm-create-machine',
          'mode': 'create_machine',
        },
      ),
    );
    final confirmBody =
        jsonDecode(await confirmResponse.readAsString()) as Map<String, dynamic>;

    expect(confirmResponse.statusCode, 200);
    expect(confirmBody['mode'], 'create_machine');
    expect(confirmBody['machineId'], 'machine-2');

    final machinesResponse = await handler(
      Request('GET', Uri.parse('http://localhost/v1/machines')),
    );
    final machinesBody =
        jsonDecode(await machinesResponse.readAsString()) as Map<String, dynamic>;
    expect(machinesBody['count'], 2);
    expect(
      (machinesBody['items'] as List)
          .map((item) => (item as Map<String, dynamic>)['code'])
          .toList(),
      contains('PDO-200'),
    );
  });

  test('confirm create_version adds published version to existing machine', () async {
    final handler = buildHandler();
    final previewResponse = await handler(
      _jsonRequest(
        'POST',
        'http://localhost/v1/import-sessions/preview',
        {
          'requestId': 'preview-create-version',
          'fileName': 'valid_import.xlsx',
          'fileContentBase64': _readFixture('valid_import.xlsx.b64')
              .replaceAll(RegExp(r'\s+'), ''),
        },
      ),
    );
    final previewBody =
        jsonDecode(await previewResponse.readAsString()) as Map<String, dynamic>;
    final sessionId = previewBody['sessionId'] as String;

    final confirmResponse = await handler(
      _jsonRequest(
        'POST',
        'http://localhost/v1/import-sessions/$sessionId/confirm',
        {
          'requestId': 'confirm-create-version',
          'mode': 'create_version',
          'targetMachineId': 'machine-1',
        },
      ),
    );
    final confirmBody =
        jsonDecode(await confirmResponse.readAsString()) as Map<String, dynamic>;
    expect(confirmResponse.statusCode, 200);
    expect(confirmBody['mode'], 'create_version');
    expect(confirmBody['machineId'], 'machine-1');

    final versionsResponse = await handler(
      Request(
        'GET',
        Uri.parse('http://localhost/v1/machines/machine-1/versions'),
      ),
    );
    final versionsBody =
        jsonDecode(await versionsResponse.readAsString()) as Map<String, dynamic>;
    expect(versionsBody['count'], 3);
    expect((versionsBody['items'] as List).last['status'], 'published');
  });

  test('confirm blocked preview returns 422', () async {
    final handler = buildHandler();
    final previewResponse = await handler(
      _jsonRequest(
        'POST',
        'http://localhost/v1/import-sessions/preview',
        {
          'requestId': 'preview-conflict',
          'fileName': 'conflict_ambiguous_parent.mxl',
          'fileContentBase64': base64.encode(
            utf8.encode(_readFixture('conflict_ambiguous_parent.mxl')),
          ),
        },
      ),
    );
    final previewBody =
        jsonDecode(await previewResponse.readAsString()) as Map<String, dynamic>;
    final sessionId = previewBody['sessionId'] as String;

    final confirmResponse = await handler(
      _jsonRequest(
        'POST',
        'http://localhost/v1/import-sessions/$sessionId/confirm',
        {
          'requestId': 'confirm-conflict',
          'mode': 'create_machine',
        },
      ),
    );
    final confirmBody =
        jsonDecode(await confirmResponse.readAsString()) as Map<String, dynamic>;

    expect(confirmResponse.statusCode, 422);
    expect(
      (confirmBody['error'] as Map<String, dynamic>)['code'],
      'import_preview_has_conflicts',
    );
  });

  test('confirm is idempotent for repeated requestId and payload', () async {
    final handler = buildHandler();
    final previewResponse = await handler(
      _jsonRequest(
        'POST',
        'http://localhost/v1/import-sessions/preview',
        {
          'requestId': 'preview-idempotent',
          'fileName': 'valid_import.mxl',
          'fileContentBase64': base64.encode(
            utf8.encode(_readFixture('valid_import.mxl')),
          ),
        },
      ),
    );
    final previewBody =
        jsonDecode(await previewResponse.readAsString()) as Map<String, dynamic>;
    final sessionId = previewBody['sessionId'] as String;

    final firstConfirm = await handler(
      _jsonRequest(
        'POST',
        'http://localhost/v1/import-sessions/$sessionId/confirm',
        {
          'requestId': 'confirm-idempotent',
          'mode': 'create_machine',
        },
      ),
    );
    final secondConfirm = await handler(
      _jsonRequest(
        'POST',
        'http://localhost/v1/import-sessions/$sessionId/confirm',
        {
          'requestId': 'confirm-idempotent',
          'mode': 'create_machine',
        },
      ),
    );

    final firstBody =
        jsonDecode(await firstConfirm.readAsString()) as Map<String, dynamic>;
    final secondBody =
        jsonDecode(await secondConfirm.readAsString()) as Map<String, dynamic>;
    expect(firstConfirm.statusCode, 200);
    expect(secondConfirm.statusCode, 200);
    expect(secondBody['versionId'], firstBody['versionId']);
  });

  test('confirm rejects same requestId with different payload', () async {
    final handler = buildHandler();
    final previewResponse = await handler(
      _jsonRequest(
        'POST',
        'http://localhost/v1/import-sessions/preview',
        {
          'requestId': 'preview-replay',
          'fileName': 'valid_import.mxl',
          'fileContentBase64': base64.encode(
            utf8.encode(_readFixture('valid_import.mxl')),
          ),
        },
      ),
    );
    final previewBody =
        jsonDecode(await previewResponse.readAsString()) as Map<String, dynamic>;
    final sessionId = previewBody['sessionId'] as String;

    final firstConfirm = await handler(
      _jsonRequest(
        'POST',
        'http://localhost/v1/import-sessions/$sessionId/confirm',
        {
          'requestId': 'confirm-replay',
          'mode': 'create_version',
          'targetMachineId': 'machine-1',
        },
      ),
    );
    expect(firstConfirm.statusCode, 200);

    final replayedConfirm = await handler(
      _jsonRequest(
        'POST',
        'http://localhost/v1/import-sessions/$sessionId/confirm',
        {
          'requestId': 'confirm-replay',
          'mode': 'create_machine',
        },
      ),
    );
    final replayedBody =
        jsonDecode(await replayedConfirm.readAsString()) as Map<String, dynamic>;

    expect(replayedConfirm.statusCode, 409);
    expect(
      (replayedBody['error'] as Map<String, dynamic>)['code'],
      'import_request_replayed_with_different_payload',
    );
  });
}

Request _jsonRequest(String method, String url, Map<String, Object?> body) {
  return Request(
    method,
    Uri.parse(url),
    headers: const {'content-type': 'application/json'},
    body: jsonEncode(body),
  );
}

String _readFixture(String fileName) {
  return File('../packages/import_engine/test/fixtures/$fileName')
      .readAsStringSync();
}
