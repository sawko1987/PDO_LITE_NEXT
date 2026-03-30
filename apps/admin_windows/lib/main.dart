import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

import 'src/import/admin_backend_client.dart';
import 'src/import/http_admin_backend_client.dart';
import 'src/import/import_flow_controller.dart';
import 'src/import/import_workspace.dart';

void main() {
  runApp(const AdminWindowsApp());
}

class AdminWindowsApp extends StatelessWidget {
  const AdminWindowsApp({super.key, this.controller, this.client});

  final ImportFlowController? controller;
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
  const AdminHomePage({super.key, this.controller, this.client});

  final ImportFlowController? controller;
  final AdminBackendClient? client;

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  late final ImportFlowController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        ImportFlowController(client: widget.client ?? HttpAdminBackendClient());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.bootstrap();
    });
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'PDO Lite Next',
      subtitle:
          'Windows panel for import sessions, machine versions, planning, and release control.',
      child: ImportWorkspace(controller: _controller, onPickFile: _pickFile),
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
    _controller.setSelectedFile(fileName: file.name, bytes: bytes);
  }
}
