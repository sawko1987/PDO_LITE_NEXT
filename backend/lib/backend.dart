import 'dart:convert';
import 'dart:io';

import 'package:data_models/data_models.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

Handler buildHandler() {
  final router = Router()
    ..get('/health', (Request request) {
      final dto = ServiceHealthDto(
        status: 'ok',
        service: 'pdo_lite_next_backend',
        timestamp: DateTime.now().toUtc(),
      );
      return Response.ok(jsonEncode(dto.toJson()), headers: {'content-type': 'application/json'});
    })
    ..get('/bootstrap', (Request request) {
      const dto = BootstrapSummaryDto(
        sourceOfTruth: 'local_database',
        importMode: 'preview_first_excel_import',
        planSource: 'structure_occurrences',
        taskGenerationMode: 'on_plan_release',
      );
      return Response.ok(jsonEncode(dto.toJson()), headers: {'content-type': 'application/json'});
    });

  return const Pipeline().addMiddleware(logRequests()).addHandler(router.call);
}

Future<void> serve({int port = 8080}) async {
  final server = await shelf_io.serve(buildHandler(), '127.0.0.1', port);
  stdout.writeln(
    'PDO Lite Next backend listening on http://${server.address.host}:${server.port}',
  );
}
