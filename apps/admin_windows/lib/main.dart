import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  runApp(const AdminWindowsApp());
}

class AdminWindowsApp extends StatelessWidget {
  const AdminWindowsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDO Lite Next Admin',
      theme: buildPdoTheme(),
      home: const AdminHomePage(),
    );
  }
}

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShell(
      title: 'PDO Lite Next',
      subtitle: 'Windows panel for machine versions, import preview, planning, and release control.',
      child: _AdminDashboard(),
    );
  }
}

class _AdminDashboard extends StatelessWidget {
  const _AdminDashboard();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 18,
      mainAxisSpacing: 18,
      childAspectRatio: 1.8,
      children: const [
        FeatureCard(
          title: 'Import Preview',
          description: 'Excel-first import with explicit conflicts, skipped special processes, and version creation only after confirmation.',
          icon: Icons.upload_file_outlined,
        ),
        FeatureCard(
          title: 'Machine Versions',
          description: 'Immutable published versions built from occurrences, not duplicated detail copies.',
          icon: Icons.account_tree_outlined,
        ),
        FeatureCard(
          title: 'Planning Board',
          description: 'Plans are assembled from concrete structure occurrences and can mix versions only by explicit choice.',
          icon: Icons.view_kanban_outlined,
        ),
        FeatureCard(
          title: 'Task Release',
          description: 'Operations are generated on plan release and inherit quantity from their parent occurrence.',
          icon: Icons.playlist_add_check_circle_outlined,
        ),
      ],
    );
  }
}
