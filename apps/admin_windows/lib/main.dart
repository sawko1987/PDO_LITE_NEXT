import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

import 'src/import/admin_backend_client.dart';
import 'src/import/http_admin_backend_client.dart';
import 'src/import/import_flow_controller.dart';
import 'src/import/import_workspace.dart';
import 'src/plans/plan_board_controller.dart';
import 'src/plans/plan_workspace.dart';

void main() {
  runApp(const AdminWindowsApp());
}

class AdminWindowsApp extends StatelessWidget {
  const AdminWindowsApp({
    super.key,
    this.controller,
    this.planController,
    this.client,
  });

  final ImportFlowController? controller;
  final PlanBoardController? planController;
  final AdminBackendClient? client;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDO Lite Next Admin',
      theme: buildPdoTheme(),
      home: AdminHomePage(controller: controller, client: client),
    );
  }
}

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({
    super.key,
    this.controller,
    this.planController,
    this.client,
  });

  final ImportFlowController? controller;
  final PlanBoardController? planController;
  final AdminBackendClient? client;

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  late final ImportFlowController _importController;
  late final PlanBoardController _planController;
  late final bool _ownsImportController;
  late final bool _ownsPlanController;

  @override
  void initState() {
    super.initState();
    _ownsImportController = widget.controller == null;
    _ownsPlanController = widget.planController == null;
    final backendClient = widget.client ?? HttpAdminBackendClient();
    _importController =
        widget.controller ??
        ImportFlowController(client: backendClient);
    _planController =
        widget.planController ?? PlanBoardController(client: backendClient);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _importController.bootstrap();
      _planController.bootstrap();
    });
  }

  @override
  void dispose() {
    if (_ownsImportController) {
      _importController.dispose();
    }
    if (_ownsPlanController) {
      _planController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'PDO Lite Next',
      subtitle:
          'Windows panel for import sessions, machine versions, planning, and release control.',
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Import'),
                Tab(text: 'Plans'),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: TabBarView(
                children: [
                  ImportWorkspace(
                    controller: _importController,
                    onPickFile: _pickFile,
                  ),
                  PlanWorkspace(controller: _planController),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'Machine import files', extensions: ['xlsx', 'mxl']),
      ],
    );
    if (file == null) {
      return;
    }

    final bytes = await file.readAsBytes();
    _importController.setSelectedFile(fileName: file.name, bytes: bytes);
  }
}
