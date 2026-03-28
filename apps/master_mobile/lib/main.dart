import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  runApp(const MasterMobileApp());
}

class MasterMobileApp extends StatelessWidget {
  const MasterMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDO Lite Next Master',
      theme: buildPdoTheme(),
      home: const MasterHomePage(),
    );
  }
}

class MasterHomePage extends StatelessWidget {
  const MasterHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShell(
      title: 'Master Flow',
      subtitle: 'Mobile workspace for assigned operations, problem reporting, and offline sync queue.',
      child: _MasterDashboard(),
    );
  }
}

class _MasterDashboard extends StatelessWidget {
  const _MasterDashboard();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        FeatureCard(
          title: 'Assigned Operations',
          description: 'Tasks are linked to operation occurrences generated from released plans.',
          icon: Icons.factory_outlined,
        ),
        SizedBox(height: 16),
        FeatureCard(
          title: 'Offline Queue',
          description: 'Execution reports and issues are stored locally until the transport layer confirms sync.',
          icon: Icons.cloud_off_outlined,
        ),
        SizedBox(height: 16),
        FeatureCard(
          title: 'Problem Chat',
          description: 'Masters raise incidents against the exact task context instead of loose free-text reports.',
          icon: Icons.chat_bubble_outline,
        ),
      ],
    );
  }
}
