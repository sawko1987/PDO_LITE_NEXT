import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_ui/shared_ui.dart';

import 'src/auth/auth_controller.dart';
import 'src/auth/login_screen.dart';
import 'src/auth/master_session_repository.dart';
import 'src/auth/shared_preferences_master_session_repository.dart';
import 'src/master/http_master_backend_client.dart';
import 'src/master/master_backend_client.dart';
import 'src/master/master_outbox_repository.dart';
import 'src/master/master_workspace.dart';
import 'src/master/master_workspace_controller.dart';
import 'src/master/shared_preferences_master_outbox_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  runApp(
    MasterMobileApp(
      outboxRepository: SharedPreferencesMasterOutboxRepository(preferences),
      sessionRepository: SharedPreferencesMasterSessionRepository(preferences),
    ),
  );
}

class MasterMobileApp extends StatelessWidget {
  const MasterMobileApp({
    super.key,
    this.authController,
    this.client,
    this.outboxRepository,
    this.sessionRepository,
    this.workspaceController,
  });

  final AuthController? authController;
  final MasterBackendClient? client;
  final MasterOutboxRepository? outboxRepository;
  final MasterSessionRepository? sessionRepository;
  final MasterWorkspaceController? workspaceController;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDO Lite Next — Мастер',
      theme: buildPdoTheme(),
      home: _MasterRoot(
        authController: authController,
        client: client,
        outboxRepository: outboxRepository,
        sessionRepository: sessionRepository,
        workspaceController: workspaceController,
      ),
    );
  }
}

class _MasterRoot extends StatefulWidget {
  const _MasterRoot({
    required this.authController,
    required this.client,
    required this.outboxRepository,
    required this.sessionRepository,
    required this.workspaceController,
  });

  final AuthController? authController;
  final MasterBackendClient? client;
  final MasterOutboxRepository? outboxRepository;
  final MasterSessionRepository? sessionRepository;
  final MasterWorkspaceController? workspaceController;

  @override
  State<_MasterRoot> createState() => _MasterRootState();
}

class _MasterRootState extends State<_MasterRoot> {
  AuthController? _authController;
  MasterBackendClient? _client;
  MasterWorkspaceController? _workspaceController;
  String? _workspaceUserId;
  late final bool _ownsAuthController;
  late final bool _ownsClient;
  late final bool _ownsWorkspaceController;

  @override
  void initState() {
    super.initState();
    _ownsClient = widget.client == null;
    _client = widget.client ?? HttpMasterBackendClient();
    _ownsAuthController = widget.authController == null;
    _authController =
        widget.authController ??
        AuthController(
          client: _client!,
          sessionRepository: widget.sessionRepository!,
        );
    _ownsWorkspaceController = widget.workspaceController == null;
    if (widget.workspaceController != null) {
      _workspaceController = widget.workspaceController;
      _workspaceUserId = widget.workspaceController!.assigneeId;
    }
    _authController!.bootstrap();
  }

  @override
  void dispose() {
    if (_ownsWorkspaceController) {
      _workspaceController?.dispose();
    }
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
    return AnimatedBuilder(
      animation: _authController!,
      builder: (context, _) {
        if (_authController!.isBootstrapping) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!_authController!.isAuthenticated) {
          _disposeOwnedWorkspaceController();
          return LoginScreen(controller: _authController!);
        }

        final session = _authController!.session!;
        _ensureWorkspaceController(session.userId);
        return MasterHomePage(
          controller: _workspaceController!,
          currentDisplayName: session.displayName,
          currentUserId: session.userId,
          onLogout: _authController!.logout,
        );
      },
    );
  }

  void _disposeOwnedWorkspaceController() {
    if (_ownsWorkspaceController) {
      _workspaceController?.dispose();
      _workspaceController = null;
      _workspaceUserId = null;
    }
  }

  void _ensureWorkspaceController(String userId) {
    if (_workspaceController != null && _workspaceUserId == userId) {
      return;
    }
    _disposeOwnedWorkspaceController();
    _workspaceController =
        widget.workspaceController ??
        MasterWorkspaceController(
          client: _client!,
          outboxRepository: widget.outboxRepository!,
          assigneeId: userId,
          onUnauthorized: _authController!.expireSession,
        );
    _workspaceUserId = userId;
  }
}

class MasterHomePage extends StatelessWidget {
  const MasterHomePage({
    super.key,
    required this.controller,
    required this.currentDisplayName,
    required this.currentUserId,
    required this.onLogout,
  });

  final MasterWorkspaceController controller;
  final String currentDisplayName;
  final String currentUserId;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Рабочее место мастера',
      subtitle:
          'Мобильное рабочее пространство для назначенных операций, отчётов о выполнении и локальной исходящей очереди.',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Вы вошли как $currentDisplayName ($currentUserId)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              FilledButton.tonalIcon(
                key: const Key('logoutButton'),
                onPressed: onLogout,
                icon: const Icon(Icons.logout_outlined),
                label: const Text('Выйти'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: MasterWorkspace(controller: controller)),
        ],
      ),
    );
  }
}
