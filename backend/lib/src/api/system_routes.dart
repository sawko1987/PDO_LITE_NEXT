import 'package:data_models/data_models.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'json_response.dart';

Router buildSystemRouter() {
  final router = Router()
    ..get('/health', (Request request) {
      final dto = ServiceHealthDto(
        status: 'ok',
        service: 'pdo_lite_next_backend',
        timestamp: DateTime.now().toUtc(),
      );
      return jsonResponse(dto.toJson());
    })
    ..get('/bootstrap', (Request request) {
      const dto = BootstrapSummaryDto(
        sourceOfTruth: 'local_database',
        importMode: 'preview_first_excel_import',
        planSource: 'structure_occurrences',
        taskGenerationMode: 'on_plan_release',
      );
      return jsonResponse(dto.toJson());
    });

  return router;
}
