import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

import 'auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.controller});

  final AuthController controller;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController _loginController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _loginController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'PDO Lite Next',
      subtitle:
          'Войдите с помощью учётной записи для доступа к планированию, диспетчеризации и управлению производством.',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: AnimatedBuilder(
            animation: widget.controller,
            builder: (context, _) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Вход в систему',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Используйте один из тестовых аккаунтов или ваши учётные данные.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        key: const Key('loginField'),
                        controller: _loginController,
                        decoration: const InputDecoration(
                          labelText: 'Логин',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => widget.controller.clearError(),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('passwordField'),
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Пароль',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => widget.controller.clearError(),
                        onSubmitted: (_) => _submit(),
                      ),
                      if (widget.controller.errorMessage case final message?)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            message,
                            key: const Key('loginErrorText'),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: const Color(0xFFB91C1C)),
                          ),
                        ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          key: const Key('signInButton'),
                          onPressed: widget.controller.isSubmitting
                              ? null
                              : _submit,
                          child: Text(
                            widget.controller.isSubmitting
                                ? 'Вход...'
                                : 'Войти',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    await widget.controller.login(
      login: _loginController.text,
      password: _passwordController.text,
    );
  }
}
