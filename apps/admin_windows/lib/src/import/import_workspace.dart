import 'package:flutter/material.dart';

import 'import_flow_controller.dart';

class ImportWorkspace extends StatelessWidget {
  const ImportWorkspace({
    super.key,
    required this.controller,
    required this.onPickFile,
  });

  final ImportFlowController controller;
  final Future<void> Function() onPickFile;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final session = controller.session;
        final preview = session?.preview;

        return ListView(
          children: [
            _SectionCard(
              title: 'Импорт',
              subtitle:
                  'Выберите файл Excel/MXL, просмотрите предварительный результат и подтвердите импорт.',
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: controller.isBusy ? null : onPickFile,
                    icon: const Icon(Icons.file_open_outlined),
                    label: const Text('Выбрать файл'),
                  ),
                  OutlinedButton.icon(
                    onPressed: controller.canBuildPreview
                        ? controller.createPreview
                        : null,
                    icon: const Icon(Icons.preview_outlined),
                    label: Text(
                      controller.isPreviewLoading
                          ? 'Формирование...'
                          : 'Сформировать предпросмотр',
                    ),
                  ),
                  TextButton.icon(
                    onPressed: controller.isMachinesLoading
                        ? null
                        : controller.loadMachines,
                    icon: const Icon(Icons.sync_outlined),
                    label: Text(
                      controller.isMachinesLoading
                          ? 'Обновление...'
                          : 'Обновить оборудование',
                    ),
                  ),
                  if (session != null)
                    TextButton.icon(
                      onPressed: controller.isPreviewLoading
                          ? null
                          : controller.refreshSession,
                      icon: const Icon(Icons.refresh_outlined),
                      label: const Text('Обновить сессию'),
                    ),
                  _ChipLabel(
                    label: controller.selectedFileName ?? 'Файл не выбран',
                    icon: Icons.description_outlined,
                  ),
                  _ChipLabel(
                    label: '${controller.machines.length} machines loaded',
                    icon: Icons.precision_manufacturing_outlined,
                  ),
                ],
              ),
            ),
            if (controller.errorMessage case final message?)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _StatusBanner(
                  title: 'Ошибка передачи или проверки',
                  message: message,
                  tone: _StatusTone.error,
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _SectionCard(
                title: 'Сводка сессии',
                subtitle: session == null
                    ? 'Предпросмотр ещё не сформирован.'
                    : 'Текущая сессия импорта и метаданные черновика оборудования.',
                child: session == null
                    ? const Text(
                        'Загрузите файл и сформируйте предпросмотр для просмотра сессии импорта.',
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _MetricChip(
                                label: 'Сессия',
                                value: session.sessionId,
                              ),
                              _MetricChip(
                                label: 'Статус',
                                value: session.status,
                              ),
                              _MetricChip(
                                label: 'Формат',
                                value: preview!.sourceFormat,
                              ),
                              _MetricChip(
                                label: 'Готов к подтверждению',
                                value: preview.canConfirm ? 'yes' : 'no',
                                tone: preview.canConfirm
                                    ? _StatusTone.success
                                    : _StatusTone.error,
                              ),
                              _MetricChip(
                                label: 'Строки',
                                value: '${preview.rowCount}',
                              ),
                              _MetricChip(
                                label: 'Каталог',
                                value: '${preview.catalogItemCount}',
                              ),
                              _MetricChip(
                                label: 'Структура',
                                value: '${preview.structureOccurrenceCount}',
                              ),
                              _MetricChip(
                                label: 'Операции',
                                value: '${preview.operationOccurrenceCount}',
                              ),
                              _MetricChip(
                                label: 'Конфликты',
                                value: '${preview.conflictCount}',
                                tone: preview.conflictCount == 0
                                    ? _StatusTone.normal
                                    : _StatusTone.error,
                              ),
                              _MetricChip(
                                label: 'Предупреждения',
                                value: '${preview.warningCount}',
                                tone: preview.warningCount == 0
                                    ? _StatusTone.normal
                                    : _StatusTone.warning,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Source file: ${preview.fileName}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Detection: ${preview.detectionReason}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Черновик оборудования',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Название: ${preview.machineName ?? 'не определено'}',
                          ),
                          Text(
                            'Код: ${preview.machineCode ?? 'не определено'}',
                          ),
                        ],
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _SectionCard(
                title: 'Режим подтверждения',
                subtitle:
                    'Выберите: создать новое оборудование или новую версию существующего.',
                child: session == null
                    ? const Text(
                        'Подтверждение доступно после формирования предпросмотра.',
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SegmentedButton<ImportConfirmMode>(
                            segments: const [
                              ButtonSegment(
                                value: ImportConfirmMode.createMachine,
                                label: Text('Создать оборудование'),
                                icon: Icon(Icons.add_box_outlined),
                              ),
                              ButtonSegment(
                                value: ImportConfirmMode.createVersion,
                                label: Text('Создать версию'),
                                icon: Icon(Icons.layers_outlined),
                              ),
                            ],
                            selected: {controller.confirmMode},
                            onSelectionChanged: (selection) {
                              controller.setConfirmMode(selection.single);
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            key: ValueKey(
                              '${controller.confirmMode.name}:${controller.targetMachineId ?? ''}:${controller.machines.length}',
                            ),
                            initialValue:
                                controller.confirmMode ==
                                    ImportConfirmMode.createVersion
                                ? controller.targetMachineId
                                : null,
                            decoration: const InputDecoration(
                              labelText: 'Целевое оборудование',
                              border: OutlineInputBorder(),
                            ),
                            items: controller.machines
                                .map(
                                  (machine) => DropdownMenuItem<String>(
                                    value: machine.id,
                                    child: Text(
                                      '${machine.code} - ${machine.name}',
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged:
                                controller.confirmMode ==
                                    ImportConfirmMode.createVersion
                                ? controller.selectTargetMachine
                                : null,
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: controller.canConfirm
                                ? controller.confirmImport
                                : null,
                            icon: controller.isConfirming
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.cloud_upload_outlined),
                            label: Text(
                              controller.isConfirming
                                  ? 'Подтверждение...'
                                  : 'Подтвердить импорт',
                            ),
                          ),
                          if (!preview!.canConfirm)
                            const Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: Text(
                                'Предпросмотр содержит блокирующие конфликты. Устраните их перед подтверждением.',
                              ),
                            ),
                          if (controller.confirmMode ==
                                  ImportConfirmMode.createVersion &&
                              controller.targetMachineId == null)
                            const Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: Text(
                                'Выберите целевое оборудование для создания новой версии.',
                              ),
                            ),
                        ],
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _SectionCard(
                title: 'Диагностика',
                subtitle:
                    'Конфликты блокируют подтверждение. Предупреждения отображаются, но не блокируют импорт.',
                child: session == null
                    ? const Text(
                        'Диагностика появится после формирования предпросмотра.',
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Конфликты',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          if (preview!.conflicts.isEmpty)
                            const Text('Блокирующих конфликтов нет.')
                          else
                            ...preview.conflicts.map(
                              (conflict) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _IssueTile(
                                  title:
                                      'Строка ${conflict.rowNumber}: ${conflict.reason}',
                                  body: conflict.candidates.isEmpty
                                      ? 'Кандидаты-владельцы не предоставлены сервером.'
                                      : 'Кандидаты: ${conflict.candidates.join(', ')}',
                                  tone: _StatusTone.error,
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          Text(
                            'Предупреждения',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          if (preview.warnings.isEmpty)
                            const Text('Предупреждений нет.')
                          else
                            ...preview.warnings.map(
                              (warning) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _IssueTile(
                                  title: warning.code,
                                  body: warning.rowNumber == null
                                      ? warning.message
                                      : 'Строка ${warning.rowNumber}: ${warning.message}',
                                  tone: _StatusTone.warning,
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _SectionCard(
                title: 'Структура',
                subtitle:
                    'Вхождения, которые станут нормализованной структурой оборудования.',
                child: preview == null
                    ? const Text(
                        'Предпросмотр структуры пуст, пока сессия не доступна.',
                      )
                    : _OccurrenceList(
                        emptyLabel: 'Вхождений структуры нет.',
                        children: preview.structureOccurrences
                            .map(
                              (occurrence) => _PreviewTile(
                                title: occurrence.displayName,
                                lines: [
                                  'Path: ${occurrence.pathKey}',
                                  'Qty/machine: ${occurrence.quantityPerMachine}',
                                  'Цех: ${occurrence.workshop ?? 'наследуется/нет'}',
                                  'Родитель: ${occurrence.parentOccurrenceId ?? 'корень'}',
                                ],
                              ),
                            )
                            .toList(growable: false),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _SectionCard(
                title: 'Операции',
                subtitle:
                    'Вхождения операций, созданные движком импорта для текущего черновика.',
                child: preview == null
                    ? const Text(
                        'Предпросмотр операций пуст, пока сессия не доступна.',
                      )
                    : _OccurrenceList(
                        emptyLabel: 'Вхождений операций нет.',
                        children: preview.operationOccurrences
                            .map(
                              (occurrence) => _PreviewTile(
                                title: occurrence.name,
                                lines: [
                                  'Structure occurrence: ${occurrence.structureOccurrenceId}',
                                  'Qty/machine: ${occurrence.quantityPerMachine}',
                                  'Цех: ${occurrence.workshop ?? 'наследуется/нет'}',
                                  'Позиция источника: ${occurrence.sourcePositionNumber ?? 'н/д'}',
                                ],
                              ),
                            )
                            .toList(growable: false),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _SectionCard(
                title: 'Реестр оборудования',
                subtitle:
                    'Актуальный список оборудования для режима создания версии и проверки после подтверждения.',
                child: controller.machines.isEmpty
                    ? const Text('Список оборудования пуст.')
                    : Column(
                        children: controller.machines
                            .map(
                              (machine) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _PreviewTile(
                                  title: '${machine.code} - ${machine.name}',
                                  lines: [
                                    'Id: ${machine.id}',
                                    'Активная версия: ${machine.activeVersionId ?? 'не установлена'}',
                                  ],
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
              ),
            ),
            if (controller.confirmResult case final result?)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _SectionCard(
                  title: 'Результат импорта',
                  subtitle:
                      'Последний успешный результат подтверждения от сервера.',
                  child: _StatusBanner(
                    title: 'Импорт подтверждён',
                    message:
                        'Mode: ${result.mode}\nMachine: ${result.machineId}\nVersion: ${result.versionId}\nLabel: ${result.versionLabel}',
                    tone: _StatusTone.success,
                  ),
                ),
              ),
          ],
        );
      },
    );
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
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

enum _StatusTone { normal, success, warning, error }

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.title,
    required this.message,
    required this.tone,
  });

  final String title;
  final String message;
  final _StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      _StatusTone.success => const Color(0xFF14532D),
      _StatusTone.warning => const Color(0xFF92400E),
      _StatusTone.error => const Color(0xFF991B1B),
      _StatusTone.normal => const Color(0xFF334155),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(message),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    this.tone = _StatusTone.normal,
  });

  final String label;
  final String value;
  final _StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final background = switch (tone) {
      _StatusTone.success => const Color(0xFFDCFCE7),
      _StatusTone.warning => const Color(0xFFFEF3C7),
      _StatusTone.error => const Color(0xFFFEE2E2),
      _StatusTone.normal => const Color(0xFFF1F5F9),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: const Color(0xFF475569)),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ChipLabel extends StatelessWidget {
  const _ChipLabel({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF475569)),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

class _IssueTile extends StatelessWidget {
  const _IssueTile({
    required this.title,
    required this.body,
    required this.tone,
  });

  final String title;
  final String body;
  final _StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      _StatusTone.success => const Color(0xFF14532D),
      _StatusTone.warning => const Color(0xFF92400E),
      _StatusTone.error => const Color(0xFF991B1B),
      _StatusTone.normal => const Color(0xFF334155),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(body),
        ],
      ),
    );
  }
}

class _OccurrenceList extends StatelessWidget {
  const _OccurrenceList({required this.emptyLabel, required this.children});

  final String emptyLabel;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return Text(emptyLabel);
    }

    return Column(children: children);
  }
}

class _PreviewTile extends StatelessWidget {
  const _PreviewTile({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(line),
            ),
          ),
        ],
      ),
    );
  }
}
