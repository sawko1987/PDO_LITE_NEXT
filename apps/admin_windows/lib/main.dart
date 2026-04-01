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
import 'src/problems/problems_board_controller.dart';
import 'src/problems/problems_workspace.dart';
import 'src/structure/structure_editor_controller.dart';
import 'src/structure/structure_workspace.dart';
import 'src/wip/wip_board_controller.dart';
import 'src/wip/wip_workspace.dart';

void main() {
  runApp(const AdminWindowsApp());
}

class AdminWindowsApp extends StatelessWidget {
  const AdminWindowsApp({
    super.key,
    this.controller,
    this.machinesController,
    this.structureController,
    this.planController,
    this.executionController,
    this.wipController,
    this.problemsController,
    this.client,
  });

  final ImportFlowController? controller;
  final MachinesRegistryController? machinesController;
  final StructureEditorController? structureController;
  final PlanBoardController? planController;
  final ExecutionBoardController? executionController;
  final WipBoardController? wipController;
  final ProblemsBoardController? problemsController;
  final AdminBackendClient? client;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDO Lite Next Admin',
      theme: buildPdoTheme(),
      home: AdminHomePage(
        controller: controller,
        machinesController: machinesController,
        structureController: structureController,
        planController: planController,
        executionController: executionController,
        wipController: wipController,
        problemsController: problemsController,
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
    this.structureController,
    this.planController,
    this.executionController,
    this.wipController,
    this.problemsController,
    this.client,
  });

  final ImportFlowController? controller;
  final MachinesRegistryController? machinesController;
  final StructureEditorController? structureController;
  final PlanBoardController? planController;
  final ExecutionBoardController? executionController;
  final WipBoardController? wipController;
  final ProblemsBoardController? problemsController;
  final AdminBackendClient? client;

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage>
    with SingleTickerProviderStateMixin {
  late final ImportFlowController _importController;
  late final MachinesRegistryController _machinesController;
  late final StructureEditorController _structureController;
  late final PlanBoardController _planController;
  late final ExecutionBoardController _executionController;
  late final WipBoardController _wipController;
  late final ProblemsBoardController _problemsController;
  late final bool _ownsImportController;
  late final bool _ownsMachinesController;
  late final bool _ownsStructureController;
  late final bool _ownsPlanController;
  late final bool _ownsExecutionController;
  late final bool _ownsWipController;
  late final bool _ownsProblemsController;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _ownsImportController = widget.controller == null;
    _ownsMachinesController = widget.machinesController == null;
    _ownsStructureController = widget.structureController == null;
    _ownsPlanController = widget.planController == null;
    _ownsExecutionController = widget.executionController == null;
    _ownsWipController = widget.wipController == null;
    _ownsProblemsController = widget.problemsController == null;
    _tabController = TabController(length: 7, vsync: this);
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
    _structureController =
        widget.structureController ??
        StructureEditorController(client: ensureBackendClient());
    _planController =
        widget.planController ??
        PlanBoardController(client: ensureBackendClient());
    _executionController =
        widget.executionController ??
        ExecutionBoardController(client: ensureBackendClient());
    _wipController =
        widget.wipController ??
        WipBoardController(client: ensureBackendClient());
    _problemsController =
        widget.problemsController ??
        ProblemsBoardController(client: ensureBackendClient());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _importController.bootstrap();
      _machinesController.bootstrap();
      _structureController.bootstrap();
      _planController.bootstrap();
      _executionController.bootstrap();
      _wipController.bootstrap();
      _problemsController.bootstrap();
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
    if (_ownsStructureController) {
      _structureController.dispose();
    }
    if (_ownsPlanController) {
      _planController.dispose();
    }
    if (_ownsExecutionController) {
      _executionController.dispose();
    }
    if (_ownsWipController) {
      _wipController.dispose();
    }
    if (_ownsProblemsController) {
      _problemsController.dispose();
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
        length: 7,
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: [
                const Tab(text: 'Machines'),
                const Tab(text: 'Import'),
                const Tab(text: 'Structure'),
                const Tab(text: 'Plans'),
                const Tab(text: 'Execution'),
                const Tab(text: 'WIP'),
                const Tab(text: 'Problems'),
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
                    onOpenInStructure: _openInStructure,
                    onCreateEditableDraftInStructure:
                        _createEditableDraftInStructure,
                    onCreateNewVersionInImport: _openCreateVersionInImport,
                  ),
                  ImportWorkspace(
                    controller: _importController,
                    onPickFile: _pickFile,
                  ),
                  StructureWorkspace(
                    controller: _structureController,
                    onPublished: _handleStructureVersionPublished,
                  ),
                  PlanWorkspace(controller: _planController),
                  ExecutionWorkspace(
                    controller: _executionController,
                    onOpenProblems: _openProblemsForTask,
                    onOpenWip: _openWipForTask,
                  ),
                  WipWorkspace(
                    controller: _wipController,
                    onOpenTask: _openTaskInExecution,
                    onOpenPlan: _openPlanById,
                    onOpenProblems: _openProblemsForTask,
                  ),
                  ProblemsWorkspace(
                    controller: _problemsController,
                    onOpenTask: _openTaskInExecution,
                    onOpenWip: _openWipForTask,
                  ),
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
    _tabController.animateTo(3);
  }

  Future<void> _openInStructure(String machineId, String versionId) async {
    await _structureController.openMachineVersion(
      machineId: machineId,
      versionId: versionId,
    );
    if (!mounted) {
      return;
    }
    _tabController.animateTo(2);
  }

  Future<void> _createEditableDraftInStructure(
    String machineId,
    String versionId,
  ) async {
    await _structureController.createDraftFromVersion(
      machineId: machineId,
      versionId: versionId,
    );
    await _machinesController.loadMachines();
    if (!mounted) {
      return;
    }
    _tabController.animateTo(2);
  }

  Future<void> _handleStructureVersionPublished(
    String machineId,
    String versionId,
  ) async {
    await _machinesController.loadMachines();
    await _planController.openMachineVersion(
      machineId: machineId,
      versionId: versionId,
    );
  }

  Future<void> _openTaskInExecution(String taskId) async {
    await _executionController.selectTask(taskId);
    if (!mounted) {
      return;
    }
    _tabController.animateTo(4);
  }

  Future<void> _openProblemsForTask(String taskId) async {
    await _problemsController.openTaskScope(taskId);
    if (!mounted) {
      return;
    }
    _tabController.animateTo(6);
  }

  Future<void> _openWipForTask(String taskId) async {
    _wipController.openTaskScope(taskId);
    if (!mounted) {
      return;
    }
    _tabController.animateTo(5);
  }

  Future<void> _openPlanById(String planId) async {
    await _planController.openPlan(planId);
    if (!mounted) {
      return;
    }
    _tabController.animateTo(3);
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
