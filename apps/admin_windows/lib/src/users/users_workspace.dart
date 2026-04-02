import 'package:data_models/data_models.dart';
import 'package:flutter/material.dart';

import 'users_board_controller.dart';

class UsersWorkspace extends StatefulWidget {
  const UsersWorkspace({super.key, required this.controller});

  final UsersBoardController controller;

  @override
  State<UsersWorkspace> createState() => _UsersWorkspaceState();
}

class _UsersWorkspaceState extends State<UsersWorkspace> {
  late final TextEditingController _loginController;
  late final TextEditingController _passwordController;
  late final TextEditingController _displayNameController;
  String _role = 'master';

  @override
  void initState() {
    super.initState();
    _loginController = TextEditingController();
    _passwordController = TextEditingController();
    _displayNameController = TextEditingController();
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return ListView(
          children: [
            _SectionCard(
              title: 'Users',
              subtitle:
                  'Create pilot accounts, deactivate access, and reset passwords for desktop users.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: 220,
                        child: TextField(
                          controller: _loginController,
                          decoration: const InputDecoration(
                            labelText: 'Login',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 220,
                        child: TextField(
                          controller: _displayNameController,
                          decoration: const InputDecoration(
                            labelText: 'Display Name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 220,
                        child: TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Temporary Password',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 200,
                        child: DropdownButtonFormField<String>(
                          initialValue: _role,
                          decoration: const InputDecoration(
                            labelText: 'Role',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'planner',
                              child: Text('planner'),
                            ),
                            DropdownMenuItem(
                              value: 'supervisor',
                              child: Text('supervisor'),
                            ),
                            DropdownMenuItem(
                              value: 'master',
                              child: Text('master'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() => _role = value);
                          },
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: widget.controller.isBusy
                            ? null
                            : _createUser,
                        icon: const Icon(Icons.person_add_alt_1_outlined),
                        label: Text(
                          widget.controller.isSaving ? 'Saving...' : 'Add User',
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: widget.controller.isLoading
                            ? null
                            : widget.controller.loadUsers,
                        icon: const Icon(Icons.refresh_outlined),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ),
                  if (widget.controller.errorMessage case final message?)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        message,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFFB91C1C),
                        ),
                      ),
                    ),
                  if (widget.controller.successMessage case final message?)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        message,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF166534),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'User List',
              subtitle:
                  'Current planner, supervisor, and master accounts with activity status.',
              child: widget.controller.users.isEmpty
                  ? const Text('No users loaded yet.')
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Login')),
                          DataColumn(label: Text('Display Name')),
                          DataColumn(label: Text('Role')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Created')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: widget.controller.users
                            .map((user) => _buildRow(context, user))
                            .toList(growable: false),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  DataRow _buildRow(BuildContext context, UserSummaryDto user) {
    return DataRow(
      cells: [
        DataCell(Text(user.login)),
        DataCell(Text(user.displayName)),
        DataCell(Text(user.role)),
        DataCell(Text(user.isActive ? 'Active' : 'Disabled')),
        DataCell(Text(user.createdAt.toIso8601String())),
        DataCell(
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: user.isActive && !widget.controller.isBusy
                    ? () => widget.controller.deactivateUser(user.id)
                    : null,
                child: const Text('Deactivate'),
              ),
              TextButton(
                onPressed: widget.controller.isBusy
                    ? null
                    : () => _showResetPasswordDialog(context, user),
                child: const Text('Reset Password'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _createUser() async {
    final created = await widget.controller.createUser(
      login: _loginController.text,
      password: _passwordController.text,
      role: _role,
      displayName: _displayNameController.text,
    );
    if (!created) {
      return;
    }
    _loginController.clear();
    _passwordController.clear();
    _displayNameController.clear();
    setState(() => _role = 'master');
  }

  Future<void> _showResetPasswordDialog(
    BuildContext context,
    UserSummaryDto user,
  ) async {
    final controller = TextEditingController();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Reset Password: ${user.login}'),
            content: TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Reset'),
              ),
            ],
          );
        },
      );
      if (confirmed != true || !mounted) {
        return;
      }
      await widget.controller.resetPassword(
        userId: user.id,
        newPassword: controller.text,
      );
    } finally {
      controller.dispose();
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(subtitle),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}
