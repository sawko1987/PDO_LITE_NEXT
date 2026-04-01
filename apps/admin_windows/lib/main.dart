import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

import 'src/execution/execution_board_controller.dart';
import 'src/execution/execution_workspace.dart';
import 'src/import/admin_backend_client.dart';
import 'src/import/http_admin_backend_client.dart';
import 'src/import/import_flow_controller.dart';
import 'src/import/import_workspace.dart';
import 'src/machines/machines_registry_controller.dart';
import 'src/machines/machines_workspace.dart';
import 'src/plans/plan_board_controller.dart';
import 'src/plans/plan_workspace.dart';

void main() {
  runApp(const AdminWindowsApp());
}

class AdminWindowsApp extends StatelessWidget {
  const AdminWindowsApp({
    super.key,
    this.controller,
    this.machinesController,
    this.planController,
    this.executionController,
    this.client,
  });

  final ImportFlowController? controller;
  final MachinesRegistryController? machinesController;
  final PlanBoardController? planController;
  final ExecutionBoardController? executionController;
  final AdminBackendClient? client;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDO Lite Next Admin',
      theme: buildPdoTheme(),
      home: AdminHomePage(
        controller: controller,
        planController: planController,
        executionController: executionController,
        client: client,
      ),
    );
  }
}

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({
    super.key,
    this.controller,
    this.machinesController,
    this.planController,
    this.executionController,
    this.client,
  });

  final ImportFlowController? controller;
  final MachinesRegistryController? machinesController;
  final PlanBoardController? planController;
  final ExecutionBoardController? executionController;
  final AdminBackendClient? client;

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage>
    with SingleTickerProviderStateMixin {
  late final ImportFlowController _importController;
  late final MachinesRegistryController _machinesController;
  late final PlanBoardController _planController;
  late final ExecutionBoardController _executionController;
  late final bool _ownsImportController;
  late final bool _ownsMachinesController;
  late final bool _ownsPlanController;
  late final bool _ownsExecutionController;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _ownsImportController = widget.controller == null;
    _ownsMachinesController = widget.machinesController == null;
    _ownsPlanController = widget.planController == null;
    _ownsExecutionController = widget.executionController == null;
    _tabController = TabController(length: 4, vsync: this);
    AdminBackendClient? backendClient;
    AdminBackendClient ensureBackendClient() {
      return backendClient ??= widget.client ?? HttpAdminBackendClient();
    }

    _importController =
        widget.controller ??
        ImportFlowController(client: ensureBackendClient());
    _machinesController =
        widget.machinesController ??
        MachinesRegistryController(client: ensureBackendClient());
    _planController =
        widget.planController ??
        PlanBoardController(client: ensureBackendClient());
    _executionController =
        widget.executionController ??
        ExecutionBoardController(client: ensureBackendClient());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _importController.bootstrap();
      _machinesController.bootstrap();
      _planController.bootstrap();
      _executionController.bootstrap();
    });
  }

  @override
  void dispose() {
    if (_ownsImportController) {
      _importController.dispose();
    }
    if (_ownsMachinesController) {
      _machinesController.dispose();
    }
    if (_ownsPlanController) {
      _planController.dispose();
    }
    if (_ownsExecutionController) {
      _executionController.dispose();
    }
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'PDO Lite Next',
      subtitle:
          'Windows panel for import sessions, machine versions, planning, and release control.',
      child: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: [
                const Tab(text: 'Machines'),
                Tab(text: 'Import'),
                Tab(text: 'Plans'),
                Tab(text: 'Execution'),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  MachinesWorkspace(
                    controller: _machinesController,
                    onOpenInPlans: _openInPlans,
                    onCreateNewVersionInImport: _openCreateVersionInImport,
                  ),
                  ImportWorkspace(
                    controller: _importController,
                    onPickFile: _pickFile,
                  ),
                  PlanWorkspace(controller: _planController),
                  ExecutionWorkspace(controller: _executionController),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCreateVersionInImport(String machineId) async {
    _importController.prepareCreateVersion(machineId);
    _tabController.animateTo(1);
  }

  Future<void> _openInPlans(String machineId, String versionId) async {
    await _planController.openMachineVersion(
      machineId: machineId,
      versionId: versionId,
    );
    if (!mounted) {
      return;
    }
    _tabController.animateTo(2);
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
