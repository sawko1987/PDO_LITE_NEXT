import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import 'src/api/system_routes.dart';
import 'src/api/v1_routes.dart';
import 'src/import/import_session_service.dart';
import 'src/persistence/sqlite_contract_store_snapshot_repository.dart';
import 'src/store/demo_contract_store.dart';

Handler buildHandler({
  String databasePath = ':memory:',
  String? packageRoot,
}) {
  final router = Router();
  final store = DemoContractStore(
    snapshotRepository: SqliteContractStoreSnapshotRepository(
      databasePath: databasePath,
      packageRoot: packageRoot ?? Directory.current.path,
    ),
  );
  final importSessionService = ImportSessionService(store);

  router.mount('/', buildSystemRouter().call);
  router.mount('/v1/', buildV1Router(store, importSessionService).call);

  return const Pipeline().addMiddleware(logRequests()).addHandler(router.call);
}

Future<void> serve({int port = 8080}) async {
  final databasePath =
      Platform.environment['PDO_LITE_DB_PATH'] ??
      p.join(Directory.current.path, 'data', 'pdo_lite_next.sqlite3');
  final server = await shelf_io.serve(
    buildHandler(databasePath: databasePath, packageRoot: Directory.current.path),
    '127.0.0.1',
    port,
  );
  stdout.writeln(
    'PDO Lite Next backend listening on http://${server.address.host}:${server.port}',
  );
}
