import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_ui/shared_ui.dart';

import 'src/master/http_master_backend_client.dart';
import 'src/master/master_workspace.dart';
import 'src/master/master_workspace_controller.dart';
import 'src/master/shared_preferences_master_outbox_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final controller = MasterWorkspaceController(
    client: HttpMasterBackendClient(),
    outboxRepository: SharedPreferencesMasterOutboxRepository(preferences),
  );
  runApp(MasterMobileApp(controller: controller));
}

class MasterMobileApp extends StatefulWidget {
  const MasterMobileApp({super.key, required this.controller});

  final MasterWorkspaceController controller;

  @override
  State<MasterMobileApp> createState() => _MasterMobileAppState();
}

class _MasterMobileAppState extends State<MasterMobileApp> {
  late final MasterWorkspaceController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDO Lite Next Master',
      theme: buildPdoTheme(),
      home: MasterHomePage(controller: _controller),
    );
  }
}

class MasterHomePage extends StatelessWidget {
  const MasterHomePage({super.key, required this.controller});

  final MasterWorkspaceController controller;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Master Flow',
      subtitle:
          'Mobile workspace for assigned operations, execution reports, and a local outbox queue.',
      child: MasterWorkspace(controller: controller),
    );
  }
}
