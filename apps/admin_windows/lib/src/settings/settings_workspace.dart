import 'package:data_models/data_models.dart';
import 'package:flutter/material.dart';

import 'backup_controller.dart';

class SettingsWorkspace extends StatelessWidget {
  const SettingsWorkspace({super.key, required this.controller});

  final BackupController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return ListView(
          children: [
            _SectionCard(
              title: 'Диагностика',
              subtitle:
                  'Состояние, хранилище, идемпотентность и метрики аудита локального сервера.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: controller.isBusy
                            ? null
                            : controller.loadDiagnostics,
                        icon: const Icon(Icons.monitor_heart_outlined),
                        label: Text(
                          controller.isDiagnosticsLoading
                              ? 'Обновление...'
                              : 'Обновить диагностику',
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: controller.isBusy
                            ? null
                            : controller.loadBackups,
                        icon: const Icon(Icons.refresh_outlined),
                        label: const Text('Обновить резервные копии'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (controller.errorMessage case final message?)
                    Text(
                      message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFFB91C1C),
                      ),
                    ),
                  if (controller.successMessage case final message?)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        message,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF166534),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (controller.health == null)
                    const Text('Диагностика ещё не загружена.')
                  else
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _MetricCard(
                          label: 'Сервис',
                          value: controller.health!.service,
                        ),
                        _MetricCard(
                          label: 'Размер БД',
                          value: '${controller.health!.databaseSizeBytes} B',
                        ),
                        _MetricCard(
                          label: 'Планы',
                          value: controller.health!.totalPlans.toString(),
                        ),
                        _MetricCard(
                          label: 'Задачи',
                          value: controller.health!.totalTasks.toString(),
                        ),
                        _MetricCard(
                          label: 'Записи аудита',
                          value: controller.health!.totalAuditEntries
                              .toString(),
                        ),
                        _MetricCard(
                          label: 'Время работы',
                          value: controller.health!.uptime,
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'Записи идемпотентности',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (controller.idempotencyStats == null)
                    const Text('Статистика идемпотентности ещё не загружена.')
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: controller.idempotencyStats!.byCategory
                          .map(
                            (item) => Chip(
                              label: Text('${item.category}: ${item.count}'),
                            ),
                          )
                          .toList(growable: false),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Резервное копирование и восстановление',
              subtitle:
                  'Создание снимка данных или восстановление из предыдущей резервной копии.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FilledButton.icon(
                    onPressed: controller.isBusy
                        ? null
                        : controller.createBackup,
                    icon: const Icon(Icons.backup_outlined),
                    label: Text(
                      controller.isSaving
                          ? 'Выполняется...'
                          : 'Создать резервную копию',
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (controller.backups.isEmpty)
                    const Text('Резервные копии ещё не созданы.')
                  else
                    ...controller.backups.map(
                      (backup) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(backup.fileName),
                        subtitle: Text(
                          '${backup.createdAt.toIso8601String()} | ${backup.sizeBytes} B | ${backup.status}',
                        ),
                        trailing: FilledButton.tonal(
                          onPressed: controller.isBusy
                              ? null
                              : () => _confirmRestore(context, backup),
                          child: const Text('Восстановить'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmRestore(
    BuildContext context,
    BackupInfoDto backup,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Восстановление резервной копии'),
          content: Text(
            'Восстановить из ${backup.fileName}? Текущие данные будут заменены, текущее состояние будет автоматически сохранено.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Восстановить'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    await controller.restoreBackup(backup.fileName);
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
