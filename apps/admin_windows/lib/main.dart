import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

import 'src/archive/archive_board_controller.dart';
import 'src/archive/archive_workspace.dart';
import 'src/audit/audit_board_controller.dart';
import 'src/audit/audit_workspace.dart';
import 'src/auth/auth_controller.dart';
import 'src/auth/login_screen.dart';
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
import 'src/reports/reports_board_controller.dart';
import 'src/reports/reports_workspace.dart';
import 'src/settings/backup_controller.dart';
import 'src/settings/settings_workspace.dart';
import 'src/structure/structure_editor_controller.dart';
import 'src/structure/structure_workspace.dart';
import 'src/users/users_board_controller.dart';
import 'src/users/users_workspace.dart';
import 'src/wip/wip_board_controller.dart';
import 'src/wip/wip_workspace.dart';

void main() {
  runApp(const AdminWindowsApp());
}

class AdminWindowsApp extends StatelessWidget {
  const AdminWindowsApp({
    super.key,
    this.authController,
    this.controller,
    this.machinesController,
    this.structureController,
    this.planController,
    this.executionController,
    this.wipController,
    this.problemsController,
    this.reportsController,
    this.archiveController,
    this.auditController,
    this.usersController,
    this.backupController,
    this.client,
  });

  final AuthController? authController;
  final ImportFlowController? controller;
  final MachinesRegistryController? machinesController;
  final StructureEditorController? structureController;
  final PlanBoardController? planController;
  final ExecutionBoardController? executionController;
  final WipBoardController? wipController;
  final ProblemsBoardController? problemsController;
  final ReportsBoardController? reportsController;
  final ArchiveBoardController? archiveController;
  final AuditBoardController? auditController;
  final UsersBoardController? usersController;
  final BackupController? backupController;
  final AdminBackendClient? client;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDO Lite Next — Администрирование',
      theme: buildPdoTheme(),
      home: _AdminRoot(
        authController: authController,
        controller: controller,
        machinesController: machinesController,
        structureController: structureController,
        planController: planController,
        executionController: executionController,
        wipController: wipController,
        problemsController: problemsController,
        reportsController: reportsController,
        archiveController: archiveController,
        auditController: auditController,
        usersController: usersController,
        backupController: backupController,
        client: client,
      ),
    );
  }
}

class _AdminRoot extends StatefulWidget {
  const _AdminRoot({
    required this.authController,
    required this.controller,
    required this.machinesController,
    required this.structureController,
    required this.planController,
    required this.executionController,
    required this.wipController,
    required this.problemsController,
    required this.reportsController,
    required this.archiveController,
    required this.auditController,
    required this.usersController,
    required this.backupController,
    required this.client,
  });

  final AuthController? authController;
  final ImportFlowController? controller;
  final MachinesRegistryController? machinesController;
  final StructureEditorController? structureController;
  final PlanBoardController? planController;
  final ExecutionBoardController? executionController;
  final WipBoardController? wipController;
  final ProblemsBoardController? problemsController;
  final ReportsBoardController? reportsController;
  final ArchiveBoardController? archiveController;
  final AuditBoardController? auditController;
  final UsersBoardController? usersController;
  final BackupController? backupController;
  final AdminBackendClient? client;

  @override
  State<_AdminRoot> createState() => _AdminRootState();
}

class _AdminRootState extends State<_AdminRoot> {
  AdminBackendClient? _client;
  AuthController? _authController;
  late final bool _ownsClient;
  late final bool _ownsAuthController;

  bool get _hasInjectedControllers =>
      widget.controller != null ||
      widget.machinesController != null ||
      widget.structureController != null ||
      widget.planController != null ||
      widget.executionController != null ||
      widget.wipController != null ||
      widget.problemsController != null ||
      widget.reportsController != null ||
      widget.archiveController != null ||
      widget.auditController != null ||
      widget.usersController != null ||
      widget.backupController != null;

  @override
  void initState() {
    super.initState();
    _ownsClient = widget.client == null;
    _client = widget.client ?? HttpAdminBackendClient();
    _ownsAuthController = widget.authController == null;
    _authController = widget.authController ?? AuthController(client: _client!);
  }

  @override
  void dispose() {
    if (_ownsAuthController) {
      _authController?.dispose();
    }
    if (_ownsClient) {
      _client?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasInjectedControllers && widget.authController == null) {
      return AdminHomePage(
        controller: widget.controller,
        machinesController: widget.machinesController,
        structureController: widget.structureController,
        planController: widget.planController,
        executionController: widget.executionController,
        wipController: widget.wipController,
        problemsController: widget.problemsController,
        reportsController: widget.reportsController,
        archiveController: widget.archiveController,
        auditController: widget.auditController,
        usersController: widget.usersController,
        backupController: widget.backupController,
        client: _client,
        currentUserId: 'planner-1',
        currentUserRole: 'planner',
        currentDisplayName: 'Planner One',
      );
    }

    return AnimatedBuilder(
      animation: _authController!,
      builder: (context, _) {
        if (!_authController!.isAuthenticated) {
          return LoginScreen(controller: _authController!);
        }

        return AdminHomePage(
          key: ValueKey(_authController!.userId),
          client: _client,
          currentUserId: _authController!.userId ?? '',
          currentUserRole: _authController!.role ?? 'planner',
          currentDisplayName:
              _authController!.displayName ?? _authController!.userId ?? '',
          onLogout: _authController!.logout,
        );
      },
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
    this.reportsController,
    this.archiveController,
    this.auditController,
    this.usersController,
    this.backupController,
    this.client,
    required this.currentUserId,
    required this.currentUserRole,
    required this.currentDisplayName,
    this.onLogout,
  });

  final ImportFlowController? controller;
  final MachinesRegistryController? machinesController;
  final StructureEditorController? structureController;
  final PlanBoardController? planController;
  final ExecutionBoardController? executionController;
  final WipBoardController? wipController;
  final ProblemsBoardController? problemsController;
  final ReportsBoardController? reportsController;
  final ArchiveBoardController? archiveController;
  final AuditBoardController? auditController;
  final UsersBoardController? usersController;
  final BackupController? backupController;
  final AdminBackendClient? client;
  final String currentUserId;
  final String currentUserRole;
  final String currentDisplayName;
  final Future<void> Function()? onLogout;

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage>
    with SingleTickerProviderStateMixin {
  ImportFlowController? _importController;
  MachinesRegistryController? _machinesController;
  StructureEditorController? _structureController;
  PlanBoardController? _planController;
  ExecutionBoardController? _executionController;
  WipBoardController? _wipController;
  ProblemsBoardController? _problemsController;
  ReportsBoardController? _reportsController;
  ArchiveBoardController? _archiveController;
  AuditBoardController? _auditController;
  UsersBoardController? _usersController;
  BackupController? _backupController;
  late final bool _ownsImportController;
  late final bool _ownsMachinesController;
  late final bool _ownsStructureController;
  late final bool _ownsPlanController;
  late final bool _ownsExecutionController;
  late final bool _ownsWipController;
  late final bool _ownsProblemsController;
  late final bool _ownsReportsController;
  late final bool _ownsArchiveController;
  late final bool _ownsAuditController;
  late final bool _ownsUsersController;
  late final bool _ownsBackupController;
  late final List<_AdminTab> _tabs;
  late final TabController _tabController;

  bool get _canManagePlanning =>
      widget.currentUserRole == 'planner' ||
      widget.currentUserRole == 'supervisor';
  bool get _canViewAudit =>
      widget.currentUserRole == 'planner' ||
      widget.currentUserRole == 'supervisor';
  bool get _canManageUsers => widget.currentUserRole == 'planner';
  bool get _isMaster => widget.currentUserRole == 'master';

  @override
  void initState() {
    super.initState();
    _tabs = _buildTabs();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _ownsImportController = widget.controller == null;
    _ownsMachinesController = widget.machinesController == null;
    _ownsStructureController = widget.structureController == null;
    _ownsPlanController = widget.planController == null;
    _ownsExecutionController = widget.executionController == null;
    _ownsWipController = widget.wipController == null;
    _ownsProblemsController = widget.problemsController == null;
    _ownsReportsController = widget.reportsController == null;
    _ownsArchiveController = widget.archiveController == null;
    _ownsAuditController = widget.auditController == null;
    _ownsUsersController = widget.usersController == null;
    _ownsBackupController = widget.backupController == null;

    AdminBackendClient? backendClient;
    AdminBackendClient ensureBackendClient() {
      return backendClient ??= widget.client ?? HttpAdminBackendClient();
    }

    if (_canManagePlanning) {
      _importController =
          widget.controller ??
          ImportFlowController(client: ensureBackendClient());
      _structureController =
          widget.structureController ??
          StructureEditorController(
            client: ensureBackendClient(),
            actorId: widget.currentUserId,
          );
      _planController =
          widget.planController ??
          PlanBoardController(
            client: ensureBackendClient(),
            releasedBy: widget.currentUserId,
            completedBy: widget.currentUserId,
            canCompletePlans: widget.currentUserRole == 'supervisor',
          );
    } else {
      _importController = widget.controller;
      _structureController = widget.structureController;
      _planController = widget.planController;
    }

    if (!_isMaster) {
      _machinesController =
          widget.machinesController ??
          MachinesRegistryController(client: ensureBackendClient());
    } else {
      _machinesController = widget.machinesController;
    }

    _executionController =
        widget.executionController ??
        ExecutionBoardController(
          client: ensureBackendClient(),
          defaultReportAuthor: widget.currentUserId,
        );
    _wipController =
        widget.wipController ??
        WipBoardController(client: ensureBackendClient());
    _problemsController =
        widget.problemsController ??
        ProblemsBoardController(
          client: ensureBackendClient(),
          actorId: widget.currentUserId,
        );
    _reportsController =
        widget.reportsController ??
        ReportsBoardController(client: ensureBackendClient());

    if (_canViewAudit) {
      _archiveController =
          widget.archiveController ??
          ArchiveBoardController(client: ensureBackendClient());
      _auditController =
          widget.auditController ??
          AuditBoardController(client: ensureBackendClient());
      _backupController =
          widget.backupController ??
          BackupController(
            client: ensureBackendClient(),
            currentUserId: widget.currentUserId,
          );
    } else {
      _archiveController = widget.archiveController;
      _auditController = widget.auditController;
      _backupController = widget.backupController;
    }

    if (_canManageUsers) {
      _usersController =
          widget.usersController ??
          UsersBoardController(client: ensureBackendClient());
    } else {
      _usersController = widget.usersController;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _machinesController?.bootstrap();
      _importController?.bootstrap();
      _structureController?.bootstrap();
      _planController?.bootstrap();
      _executionController?.bootstrap();
      _wipController?.bootstrap();
      _problemsController?.bootstrap();
      _reportsController?.bootstrap();
      _archiveController?.bootstrap();
      _auditController?.bootstrap();
      _usersController?.bootstrap();
      _backupController?.bootstrap();
    });
  }

  @override
  void dispose() {
    if (_ownsImportController) {
      _importController?.dispose();
    }
    if (_ownsMachinesController) {
      _machinesController?.dispose();
    }
    if (_ownsStructureController) {
      _structureController?.dispose();
    }
    if (_ownsPlanController) {
      _planController?.dispose();
    }
    if (_ownsExecutionController) {
      _executionController?.dispose();
    }
    if (_ownsWipController) {
      _wipController?.dispose();
    }
    if (_ownsProblemsController) {
      _problemsController?.dispose();
    }
    if (_ownsReportsController) {
      _reportsController?.dispose();
    }
    if (_ownsArchiveController) {
      _archiveController?.dispose();
    }
    if (_ownsAuditController) {
      _auditController?.dispose();
    }
    if (_ownsUsersController) {
      _usersController?.dispose();
    }
    if (_ownsBackupController) {
      _backupController?.dispose();
    }
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'PDO Lite Next',
      subtitle:
          'Панель управления импортом, версиями оборудования, планированием, отчётами, архивом, аудитом и восстановлением.',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Вы вошли как ${widget.currentDisplayName} (${_translateRole(widget.currentUserRole)})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (widget.onLogout != null)
                FilledButton.tonalIcon(
                  onPressed: widget.onLogout,
                  icon: const Icon(Icons.logout_outlined),
                  label: const Text('Выйти'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: _tabs
                .map((tab) => Tab(text: tab.label))
                .toList(growable: false),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabs
                  .map((tab) => _buildTabView(tab))
                  .toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }

  List<_AdminTab> _buildTabs() {
    if (_isMaster) {
      return const [
        _AdminTab.execution,
        _AdminTab.wip,
        _AdminTab.problems,
        _AdminTab.reports,
      ];
    }

    final tabs = <_AdminTab>[
      _AdminTab.machines,
      _AdminTab.import,
      _AdminTab.structure,
      _AdminTab.plans,
      _AdminTab.execution,
      _AdminTab.wip,
      _AdminTab.problems,
      _AdminTab.reports,
    ];
    if (_canViewAudit) {
      tabs.addAll(const [_AdminTab.archive, _AdminTab.audit]);
    }
    if (_canManageUsers) {
      tabs.add(_AdminTab.users);
    }
    if (_canViewAudit) {
      tabs.add(_AdminTab.settings);
    }
    return tabs;
  }

  Widget _buildTabView(_AdminTab tab) {
    return switch (tab) {
      _AdminTab.machines => MachinesWorkspace(
        controller: _machinesController!,
        onOpenInPlans: _openInPlans,
        onOpenInStructure: _openInStructure,
        onCreateEditableDraftInStructure: _createEditableDraftInStructure,
        onCreateNewVersionInImport: _openCreateVersionInImport,
      ),
      _AdminTab.import => ImportWorkspace(
        controller: _importController!,
        onPickFile: _pickFile,
      ),
      _AdminTab.structure => StructureWorkspace(
        controller: _structureController!,
        onPublished: _handleStructureVersionPublished,
      ),
      _AdminTab.plans => PlanWorkspace(controller: _planController!),
      _AdminTab.execution => ExecutionWorkspace(
        controller: _executionController!,
        onOpenProblems: _openProblemsForTask,
        onOpenWip: _openWipForTask,
      ),
      _AdminTab.wip => WipWorkspace(
        controller: _wipController!,
        onOpenTask: _openTaskInExecution,
        onOpenPlan: _openPlanById,
        onOpenProblems: _openProblemsForTask,
      ),
      _AdminTab.problems => ProblemsWorkspace(
        controller: _problemsController!,
        onOpenTask: _openTaskInExecution,
        onOpenWip: _openWipForTask,
      ),
      _AdminTab.reports => ReportsWorkspace(controller: _reportsController!),
      _AdminTab.archive => ArchiveWorkspace(
        controller: _archiveController!,
        onOpenInReports: _openInReports,
      ),
      _AdminTab.audit => AuditWorkspace(controller: _auditController!),
      _AdminTab.users => UsersWorkspace(controller: _usersController!),
      _AdminTab.settings => SettingsWorkspace(controller: _backupController!),
    };
  }

  int? _tabIndex(_AdminTab tab) {
    final index = _tabs.indexOf(tab);
    return index == -1 ? null : index;
  }

  void _animateTo(_AdminTab tab) {
    final index = _tabIndex(tab);
    if (index == null) {
      return;
    }
    _tabController.animateTo(index);
  }

  Future<void> _openCreateVersionInImport(String machineId) async {
    _importController?.prepareCreateVersion(machineId);
    _animateTo(_AdminTab.import);
  }

  Future<void> _openInPlans(String machineId, String versionId) async {
    if (_planController == null) {
      return;
    }
    await _planController!.openMachineVersion(
      machineId: machineId,
      versionId: versionId,
    );
    if (!mounted) {
      return;
    }
    _animateTo(_AdminTab.plans);
  }

  Future<void> _openInStructure(String machineId, String versionId) async {
    if (_structureController == null) {
      return;
    }
    await _structureController!.openMachineVersion(
      machineId: machineId,
      versionId: versionId,
    );
    if (!mounted) {
      return;
    }
    _animateTo(_AdminTab.structure);
  }

  Future<void> _createEditableDraftInStructure(
    String machineId,
    String versionId,
  ) async {
    if (_structureController == null) {
      return;
    }
    await _structureController!.createDraftFromVersion(
      machineId: machineId,
      versionId: versionId,
    );
    await _machinesController?.loadMachines();
    if (!mounted) {
      return;
    }
    _animateTo(_AdminTab.structure);
  }

  Future<void> _handleStructureVersionPublished(
    String machineId,
    String versionId,
  ) async {
    await _machinesController?.loadMachines();
    await _planController?.openMachineVersion(
      machineId: machineId,
      versionId: versionId,
    );
  }

  Future<void> _openTaskInExecution(String taskId) async {
    await _executionController?.selectTask(taskId);
    if (!mounted) {
      return;
    }
    _animateTo(_AdminTab.execution);
  }

  Future<void> _openProblemsForTask(String taskId) async {
    await _problemsController?.openTaskScope(taskId);
    if (!mounted) {
      return;
    }
    _animateTo(_AdminTab.problems);
  }

  Future<void> _openWipForTask(String taskId) async {
    _wipController?.openTaskScope(taskId);
    if (!mounted) {
      return;
    }
    _animateTo(_AdminTab.wip);
  }

  Future<void> _openPlanById(String planId) async {
    if (_planController == null) {
      return;
    }
    await _planController!.openPlan(planId);
    if (!mounted) {
      return;
    }
    _animateTo(_AdminTab.plans);
  }

  Future<void> _openInReports(String planId) async {
    await _reportsController?.loadPlanFactReport(planId: planId);
    if (!mounted) {
      return;
    }
    _animateTo(_AdminTab.reports);
  }

  Future<void> _pickFile() async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Файлы импорта оборудования',
          extensions: ['xlsx', 'mxl'],
        ),
      ],
    );
    if (file == null) {
      return;
    }

    final bytes = await file.readAsBytes();
    _importController?.setSelectedFile(fileName: file.name, bytes: bytes);
  }
}

enum _AdminTab {
  machines('Оборудование'),
  import('Импорт'),
  structure('Структура'),
  plans('Планы'),
  execution('Выполнение'),
  wip('НЗП'),
  problems('Проблемы'),
  reports('Отчёты'),
  archive('Архив'),
  audit('Аудит'),
  users('Пользователи'),
  settings('Настройки');

  const _AdminTab(this.label);

  final String label;
}

String _translateRole(String role) {
  return switch (role) {
    'planner' => 'Планировщик',
    'supervisor' => 'Диспетчер',
    'master' => 'Мастер',
    _ => role,
  };
}
