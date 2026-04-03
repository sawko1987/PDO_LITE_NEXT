import 'package:data_models/data_models.dart';
import 'package:flutter/material.dart';

import 'execution_board_controller.dart';

const _reportOutcomeOptions = <({String label, String value})>[
  (label: 'Завершено', value: 'completed'),
  (label: 'Частично', value: 'partial'),
  (label: 'Не завершено', value: 'not_completed'),
  (label: 'Перевыполнение', value: 'overrun'),
];

class ExecutionWorkspace extends StatelessWidget {
  const ExecutionWorkspace({
    super.key,
    required this.controller,
    required this.onOpenProblems,
    required this.onOpenWip,
  });

  final ExecutionBoardController controller;
  final Future<void> Function(String taskId) onOpenProblems;
  final Future<void> Function(String taskId) onOpenWip;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return ListView(
          children: [
            _SectionCard(
              title: 'Управление выполнением',
              subtitle:
                  'Мониторинг запущенных задач и отправка отчётов о выполнении.',
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: controller.isBusy ? null : controller.refresh,
                    icon: const Icon(Icons.refresh_outlined),
                    label: Text(
                      controller.isLoading ? 'Обновление...' : 'Обновить',
                    ),
                  ),
                  _InfoChip(label: '${controller.tasks.length} задач всего'),
                  _InfoChip(
                    label: '${controller.activeTaskCount} активных задач',
                  ),
                  _InfoChip(
                    label: '${controller.openProblemCount} открытых проблем',
                  ),
                  _InfoChip(label: '${controller.openWipCount} открытых НЗП'),
                ],
              ),
            ),
            if (controller.errorMessage case final message?)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _Banner(
                  title: 'Ошибка выполнения',
                  message: message,
                  color: const Color(0xFF991B1B),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _SectionCard(
                title: 'Монитор задач',
                subtitle:
                    'Просмотр всех запущенных задач и отслеживание прогресса выполнения.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _FilterChip(
                          label: 'Все',
                          selected:
                              controller.filter == ExecutionTaskFilter.all,
                          onSelected: () =>
                              controller.setFilter(ExecutionTaskFilter.all),
                        ),
                        _FilterChip(
                          label: 'Активные',
                          selected:
                              controller.filter == ExecutionTaskFilter.active,
                          onSelected: () =>
                              controller.setFilter(ExecutionTaskFilter.active),
                        ),
                        _FilterChip(
                          label: 'Завершено',
                          selected:
                              controller.filter ==
                              ExecutionTaskFilter.completed,
                          onSelected: () => controller.setFilter(
                            ExecutionTaskFilter.completed,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (controller.visibleTasks.isEmpty)
                      const Text('Нет задач, соответствующих фильтру.')
                    else
                      Column(
                        children: controller.visibleTasks
                            .map(
                              (task) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _TaskTile(
                                  task: task,
                                  selected: controller.isSelectedTask(task.id),
                                  onTap: () => controller.selectTask(task.id),
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _SectionCard(
                title: 'Детали задачи',
                subtitle:
                    'Контекст выбранной задачи, прогресс и форма ручного отчёта.',
                child: controller.selectedTask == null
                    ? const Text(
                        'Выберите задачу для просмотра данных выполнения.',
                      )
                    : _ExecutionReportFormSection(
                        controller: controller,
                        task: controller.selectedTask!,
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _SectionCard(
                title: 'Отчёты о выполнении',
                subtitle: 'Принятая история выполнения для выбранной задачи.',
                child: controller.selectedTask == null
                    ? const Text('Задача не выбрана.')
                    : controller.reports.isEmpty
                    ? const Text(
                        'Отчётов о выполнении для этой задачи ещё нет.',
                      )
                    : Column(
                        children: controller.reports
                            .map(
                              (report) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _DetailTile(
                                  title:
                                      '${report.outcome} | ${report.reportedQuantity}',
                                  lines: [
                                    'Отчёт: ${report.id}',
                                    'Автор отчёта: ${report.reportedBy}',
                                    'Отправлено в: ${_formatDateTime(report.reportedAt)}',
                                    'Принят: ${report.isAccepted ? 'да' : 'нет'}',
                                    if (report.acceptedAt != null)
                                      'Принят в: ${_formatDateTime(report.acceptedAt!)}',
                                    if (report.reason != null &&
                                        report.reason!.isNotEmpty)
                                      'Причина: ${report.reason}',
                                  ],
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _SectionCard(
                title: 'Проблемы',
                subtitle:
                    'Сводка проблем для выбранной задачи и переписка по выбранной проблеме.',
                child: controller.selectedTask == null
                    ? const Text('Задача не выбрана.')
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (controller.taskProblems.isEmpty)
                            const Text('К этой задаче не привязано проблем.')
                          else
                            Column(
                              children: controller.taskProblems
                                  .map(
                                    (problem) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: _ProblemTile(
                                        problem: problem,
                                        selected: controller.isSelectedProblem(
                                          problem.id,
                                        ),
                                        onTap: () => controller.selectProblem(
                                          problem.id,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                          if (controller.selectedProblem != null) ...[
                            const SizedBox(height: 16),
                            _ProblemThreadSection(
                              problem: controller.selectedProblem!,
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              key: const Key('openProblemsWorkspaceButton'),
                              onPressed: controller.selectedTask == null
                                  ? null
                                  : () => onOpenProblems(
                                      controller.selectedTask!.id,
                                    ),
                              icon: const Icon(Icons.open_in_new_outlined),
                              label: const Text('Открыть раздел проблем'),
                            ),
                          ],
                        ],
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _SectionCard(
                title: 'НЗП задачи',
                subtitle:
                    'НЗП, привязанные к выбранной задаче по идентификатору задачи или вхождению операции.',
                child: controller.selectedTask == null
                    ? const Text('Задача не выбрана.')
                    : controller.scopedWipEntries.isEmpty
                    ? const Text('НЗП для выбранной задачи отсутствуют.')
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...controller.scopedWipEntries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _DetailTile(
                                title: '${entry.id} | ${entry.status}',
                                lines: [
                                  'Операция: ${entry.operationOccurrenceId}',
                                  'Баланс: ${entry.balanceQuantity}',
                                  'Блокирует завершение: ${entry.blocksCompletion ? 'да' : 'нет'}',
                                  'Задача: ${entry.taskId ?? '-'}',
                                  'Результат: ${entry.sourceOutcome ?? '-'}',
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            key: const Key('openWipWorkspaceButton'),
                            onPressed: controller.selectedTask == null
                                ? null
                                : () => onOpenWip(controller.selectedTask!.id),
                            icon: const Icon(Icons.open_in_new_outlined),
                            label: const Text('Открыть раздел НЗП'),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ExecutionReportFormSection extends StatefulWidget {
  const _ExecutionReportFormSection({
    required this.controller,
    required this.task,
  });

  final ExecutionBoardController controller;
  final TaskDetailDto task;

  @override
  State<_ExecutionReportFormSection> createState() =>
      _ExecutionReportFormSectionState();
}

class _ExecutionReportFormSectionState
    extends State<_ExecutionReportFormSection> {
  late final TextEditingController _authorController;
  late final TextEditingController _quantityController;
  late final TextEditingController _reasonController;

  @override
  void initState() {
    super.initState();
    _authorController =
        TextEditingController(text: widget.controller.reportAuthor)
          ..addListener(() {
            widget.controller.setReportAuthor(_authorController.text);
          });
    _quantityController =
        TextEditingController(text: widget.controller.reportQuantity)
          ..addListener(() {
            widget.controller.setReportQuantity(_quantityController.text);
          });
    _reasonController =
        TextEditingController(text: widget.controller.reportReason)
          ..addListener(() {
            widget.controller.setReportReason(_reasonController.text);
          });
  }

  @override
  void didUpdateWidget(covariant _ExecutionReportFormSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncControllerText(_authorController, widget.controller.reportAuthor);
    _syncControllerText(_quantityController, widget.controller.reportQuantity);
    _syncControllerText(_reasonController, widget.controller.reportReason);
  }

  @override
  void dispose() {
    _authorController.dispose();
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final controller = widget.controller;
    final isClosed = task.isClosed;
    final isSubmitting = controller.isReportSubmitting;

    _syncControllerText(_authorController, controller.reportAuthor);
    _syncControllerText(_quantityController, controller.reportQuantity);
    _syncControllerText(_reasonController, controller.reportReason);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailTile(
          title: '${task.structureDisplayName} | ${task.operationName}',
          lines: [
            'Задача: ${task.id}',
            'Станок: ${task.machineId}',
            'Версия: ${task.versionId}',
            'Вхождение: ${task.structureOccurrenceId}',
            'Цех: ${task.workshop}',
            'Исполнитель: ${task.assigneeId ?? '-'}',
            'Статус: ${task.status}',
            'Запланировано: ${task.requiredQuantity}',
            'Выполнено: ${task.reportedQuantity}',
            'Осталось: ${task.remainingQuantity}',
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Ручной отчёт о выполнении',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          isClosed
              ? 'Эта задача уже закрыта. Ручной отчёт отключён.'
              : 'Диспетчер может ввести результат выполнения из настольного клиента.',
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('executionReportedByField'),
          controller: _authorController,
          enabled: !isClosed && !isSubmitting,
          decoration: const InputDecoration(
            labelText: 'Автор отчёта',
            hintText: 'Идентификатор диспетчера или оператора',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _reportOutcomeOptions
              .map(
                (option) => ChoiceChip(
                  key: Key('executionOutcome-${option.value}'),
                  label: Text(option.label),
                  selected: controller.reportOutcome == option.value,
                  onSelected: isClosed || isSubmitting
                      ? null
                      : (_) => controller.setReportOutcome(option.value),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('executionQuantityField'),
          controller: _quantityController,
          enabled: !isClosed && !isSubmitting,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Количество',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('executionReasonField'),
          controller: _reasonController,
          enabled: !isClosed && !isSubmitting,
          minLines: 1,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Причина / комментарий',
            border: OutlineInputBorder(),
          ),
        ),
        if (controller.submissionMessage case final message?) ...[
          const SizedBox(height: 12),
          _Banner(
            title: 'Отчёт отправлен',
            message: message,
            color: const Color(0xFF166534),
          ),
        ],
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const Key('submitExecutionReportButton'),
          onPressed: !controller.canSubmitSelectedTaskReport
              ? null
              : controller.submitSelectedTaskReport,
          icon: const Icon(Icons.send_outlined),
          label: Text(
            isSubmitting ? 'Отправка...' : 'Отправить отчёт о выполнении',
          ),
        ),
      ],
    );
  }

  void _syncControllerText(TextEditingController controller, String value) {
    if (controller.text == value) {
      return;
    }
    controller.value = controller.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
      composing: TextRange.empty,
    );
  }
}

class _ProblemThreadSection extends StatelessWidget {
  const _ProblemThreadSection({required this.problem});

  final ProblemDetailDto problem;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailTile(
          title: '${problem.title ?? problem.id} | ${problem.status}',
          lines: [
            'Тип: ${problem.type}',
            'Создана: ${_formatDateTime(problem.createdAt)}',
            'Задача: ${problem.taskId ?? '-'}',
            'Станок: ${problem.machineId}',
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Переписка по проблеме',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ...problem.messages.map(
          (message) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _DetailTile(
              title: message.authorId,
              lines: [
                'Отправлено: ${_formatDateTime(message.createdAt)}',
                'Сообщение: ${message.message}',
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.selected,
    required this.onTap,
  });

  final TaskSummaryDto task;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFE0F2FE) : const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${task.structureDisplayName} | ${task.operationName}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                '${task.status} | ${task.workshop} | ${task.machineId}/${task.versionId}',
              ),
              const SizedBox(height: 6),
              Text(
                'Запланировано ${task.requiredQuantity} шт. | Выполнено ${task.reportedQuantity} шт. | Осталось ${task.remainingQuantity} шт.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProblemTile extends StatelessWidget {
  const _ProblemTile({
    required this.problem,
    required this.selected,
    required this.onTap,
  });

  final ProblemSummaryDto problem;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFFFF7ED) : const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                problem.title ?? problem.id,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                '${problem.type} | ${problem.status} | сообщений: ${problem.messageCount}',
              ),
            ],
          ),
        ),
      ),
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
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(subtitle),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(line),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.title,
    required this.message,
    required this.color,
  });

  final String title;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
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

String _formatDateTime(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${value.year}-$month-$day $hour:$minute UTC';
}
