import 'package:data_models/data_models.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

import 'master_outbox_item.dart';
import 'master_workspace_controller.dart';

const _problemTypeOptions = <({String label, String value})>[
  (label: 'Оборудование', value: 'equipment'),
  (label: 'Материалы', value: 'materials'),
  (label: 'Документация', value: 'documentation'),
  (label: 'Ошибка планирования', value: 'planning_error'),
  (label: 'Ошибка технологии', value: 'technology_error'),
  (label: 'Блокировано другим цехом', value: 'blocked_by_other_workshop'),
  (label: 'Другое', value: 'other'),
];

const _reportOutcomeOptions = <({String label, String value})>[
  (label: 'Завершено', value: 'completed'),
  (label: 'Частично', value: 'partial'),
  (label: 'Не завершено', value: 'not_completed'),
  (label: 'Перевыполнение', value: 'overrun'),
];

class MasterWorkspace extends StatefulWidget {
  const MasterWorkspace({super.key, required this.controller});

  final MasterWorkspaceController controller;

  @override
  State<MasterWorkspace> createState() => _MasterWorkspaceState();
}

class _MasterWorkspaceState extends State<MasterWorkspace> {
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  final _searchController = TextEditingController();
  String _selectedReportOutcome = 'completed';

  MasterWorkspaceController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _searchController.text = _controller.searchQuery;
    _controller.bootstrap();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.isLoading &&
            _controller.tasks.isEmpty &&
            _controller.selectedTask == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: _controller.refresh,
          child: ListView(
            children: [
              const FeatureCard(
                title: 'Назначенные задачи',
                description:
                    'Мастер отправляет факты выполнения и создаёт проблемы по задачам из этого же рабочего пространства.',
                icon: Icons.assignment_turned_in_outlined,
              ),
              const SizedBox(height: 16),
              _FilterCard(
                assigneeId: _controller.assigneeId,
                filter: _controller.taskFilter,
                onChanged: _controller.setFilter,
                onSearchChanged: _controller.setSearchQuery,
                searchController: _searchController,
              ),
              const SizedBox(height: 16),
              if (_controller.errorMessage case final error?)
                _ErrorCard(message: error),
              if (_controller.errorMessage != null) const SizedBox(height: 16),
              _TaskListCard(
                tasks: _controller.visibleTasks,
                selectedTaskId: _controller.selectedTask?.id,
                onSelected: _controller.selectTask,
              ),
              const SizedBox(height: 16),
              if (_controller.selectedTask case final task?
                  when _controller.visibleTasks.any(
                    (visibleTask) => visibleTask.id == task.id,
                  ))
                _TaskDetailCard(
                  isSubmitting: _controller.isSubmitting,
                  onCreateProblem: () => _showCreateProblemSheet(context, task),
                  onOpenProblem: (problem) =>
                      _showProblemSheet(context, problem),
                  onSubmitReport: () async {
                    var quantity = double.tryParse(
                      _quantityController.text.replaceAll(',', '.'),
                    );
                    if (quantity == null || quantity <= 0) {
                      if (_selectedReportOutcome != 'not_completed') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Введите корректное количество больше нуля.',
                            ),
                          ),
                        );
                        return;
                      }
                      quantity = 0;
                    }

                    if (_selectedReportOutcome == 'completed' &&
                        quantity != task.remainingQuantity) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '«Завершено» должно равняться оставшемуся количеству: ${task.remainingQuantity}.',
                          ),
                        ),
                      );
                      return;
                    }
                    if (_selectedReportOutcome == 'partial' &&
                        (quantity <= 0 || quantity >= task.remainingQuantity)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '«Частично» должно быть больше 0 и меньше ${task.remainingQuantity}.',
                          ),
                        ),
                      );
                      return;
                    }
                    if (_selectedReportOutcome == 'not_completed' &&
                        quantity != 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            '«Не завершено» означает количество 0.',
                          ),
                        ),
                      );
                      return;
                    }
                    if (_selectedReportOutcome == 'overrun' &&
                        quantity <= task.remainingQuantity) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '«Перевыполнение» должно превышать оставшееся количество: ${task.remainingQuantity}.',
                          ),
                        ),
                      );
                      return;
                    }
                    if ((_selectedReportOutcome == 'partial' ||
                            _selectedReportOutcome == 'not_completed') &&
                        _reasonController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Причина обязательна для отчётов «Частично» и «Не завершено».',
                          ),
                        ),
                      );
                      return;
                    }

                    await _controller.submitExecutionReport(
                      taskId: task.id,
                      reportedQuantity: quantity,
                      outcome: _selectedReportOutcome,
                      reason: _reasonController.text,
                    );
                    _quantityController.clear();
                    _reasonController.clear();
                    setState(() => _selectedReportOutcome = 'completed');
                  },
                  onReportOutcomeChanged: (value) {
                    setState(() => _selectedReportOutcome = value);
                  },
                  problems: _controller.problems,
                  quantityController: _quantityController,
                  reasonController: _reasonController,
                  reportFeedbackMessage: _controller.reportFeedbackMessage,
                  reportOutcome: _selectedReportOutcome,
                  reports: _controller.reports,
                  task: task,
                ),
              const SizedBox(height: 16),
              _OutboxCard(
                items: _controller.outboxItems,
                onRetry: _controller.retryOutboxItem,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCreateProblemSheet(
    BuildContext context,
    TaskDetailDto task,
  ) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    var selectedType = _problemTypeOptions.first.value;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Создать проблему: ${task.operationName}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    key: const Key('problemTypeDropdown'),
                    initialValue: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Тип проблемы',
                      border: OutlineInputBorder(),
                    ),
                    items: _problemTypeOptions
                        .map(
                          (option) => DropdownMenuItem<String>(
                            value: option.value,
                            child: Text(option.label),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setModalState(() => selectedType = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('problemTitleField'),
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Название',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('problemDescriptionField'),
                    controller: descriptionController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Первое сообщение',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      key: const Key('createProblemButton'),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);
                        final title = titleController.text.trim();
                        final description = descriptionController.text.trim();
                        if (title.isEmpty || description.isEmpty) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Название и первое сообщение обязательны.',
                              ),
                            ),
                          );
                          return;
                        }

                        await _controller.createProblem(
                          taskId: task.id,
                          type: selectedType,
                          title: title,
                          description: description,
                        );
                        if (mounted) {
                          navigator.pop();
                        }
                      },
                      icon: const Icon(Icons.report_problem_outlined),
                      label: const Text('Создать проблему'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    titleController.dispose();
    descriptionController.dispose();
  }

  Future<void> _showProblemSheet(
    BuildContext context,
    ProblemSummaryDto problem,
  ) async {
    await _controller.selectProblem(problem.id);
    if (!mounted || !context.mounted) {
      return;
    }

    final messageController = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: _ProblemDetailSheet(
            controller: _controller,
            messageController: messageController,
          ),
        );
      },
    );
    messageController.dispose();
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
      ),
    );
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({
    required this.assigneeId,
    required this.filter,
    required this.onChanged,
    required this.onSearchChanged,
    required this.searchController,
  });

  final String assigneeId;
  final MasterTaskFilter filter;
  final ValueChanged<MasterTaskFilter> onChanged;
  final ValueChanged<String> onSearchChanged;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 280,
              child: TextField(
                key: const Key('taskSearchField'),
                controller: searchController,
                onChanged: onSearchChanged,
                decoration: const InputDecoration(
                  labelText: 'Поиск задач',
                  hintText: 'Задача, операция, деталь, оборудование, цех',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Chip(
              avatar: const Icon(Icons.person_outline, size: 18),
              label: Text('Исполнитель: $assigneeId'),
            ),
            ChoiceChip(
              label: const Text('Активные'),
              selected: filter == MasterTaskFilter.active,
              onSelected: (_) => onChanged(MasterTaskFilter.active),
            ),
            ChoiceChip(
              label: const Text('Завершённые'),
              selected: filter == MasterTaskFilter.completed,
              onSelected: (_) => onChanged(MasterTaskFilter.completed),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskListCard extends StatelessWidget {
  const _TaskListCard({
    required this.tasks,
    required this.selectedTaskId,
    required this.onSelected,
  });

  final ValueChanged<String> onSelected;
  final String? selectedTaskId;
  final List<TaskSummaryDto> tasks;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('taskListCard'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Список назначенных задач',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (tasks.isEmpty)
              const Text('Нет задач, соответствующих фильтру.')
            else
              for (final task in tasks) ...[
                ListTile(
                  key: Key('taskTile-${task.id}'),
                  selected: task.id == selectedTaskId,
                  contentPadding: EdgeInsets.zero,
                  title: Text('Задача ${task.id}'),
                  subtitle: Text(
                    'Запланировано ${task.requiredQuantity} - ${task.status}',
                  ),
                  trailing: task.isClosed
                      ? const Icon(Icons.check_circle_outline)
                      : const Icon(Icons.chevron_right),
                  onTap: () => onSelected(task.id),
                ),
                const Divider(height: 1),
              ],
          ],
        ),
      ),
    );
  }
}

class _TaskDetailCard extends StatelessWidget {
  const _TaskDetailCard({
    required this.isSubmitting,
    required this.onCreateProblem,
    required this.onOpenProblem,
    required this.onSubmitReport,
    required this.onReportOutcomeChanged,
    required this.problems,
    required this.quantityController,
    required this.reasonController,
    required this.reportFeedbackMessage,
    required this.reportOutcome,
    required this.reports,
    required this.task,
  });

  final bool isSubmitting;
  final VoidCallback onCreateProblem;
  final ValueChanged<ProblemSummaryDto> onOpenProblem;
  final VoidCallback onSubmitReport;
  final ValueChanged<String> onReportOutcomeChanged;
  final List<ProblemSummaryDto> problems;
  final TextEditingController quantityController;
  final TextEditingController reasonController;
  final String? reportFeedbackMessage;
  final String reportOutcome;
  final List<ExecutionReportDto> reports;
  final TaskDetailDto task;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('taskDetailCard'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Детали задачи',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                Chip(label: Text(task.structureDisplayName)),
                Chip(label: Text(task.operationName)),
                Chip(label: Text('Цех ${task.workshop}')),
                Chip(label: Text(task.status)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Required: ${task.requiredQuantity} - Reported: ${task.reportedQuantity} - Remaining: ${task.remainingQuantity}',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _reportOutcomeOptions
                  .map(
                    (option) => ChoiceChip(
                      label: Text(option.label),
                      selected: reportOutcome == option.value,
                      onSelected: (_) => onReportOutcomeChanged(option.value),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('reportQuantityField'),
              controller: quantityController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Количество',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('reportReasonField'),
              controller: reasonController,
              minLines: 1,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Причина / комментарий',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('submitReportButton'),
              onPressed: isSubmitting || task.isClosed ? null : onSubmitReport,
              icon: const Icon(Icons.send_outlined),
              label: Text(
                isSubmitting ? 'Отправка...' : 'Отправить отчёт о выполнении',
              ),
            ),
            if (reportFeedbackMessage case final message?) ...[
              const SizedBox(height: 12),
              Text(
                message,
                key: const Key('reportFeedbackMessage'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Проблемы',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                TextButton.icon(
                  key: const Key('openCreateProblemSheetButton'),
                  onPressed: onCreateProblem,
                  icon: const Icon(Icons.add_comment_outlined),
                  label: const Text('Создать проблему'),
                ),
              ],
            ),
            if (problems.isEmpty)
              const Text('Нет проблем по этой задаче.')
            else
              for (final problem in problems) ...[
                ListTile(
                  key: Key('problemTile-${problem.id}'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(problem.title ?? problem.id),
                  subtitle: Text(
                    '${problem.type} - ${problem.status} - ${problem.messageCount} сообщ.',
                  ),
                  trailing: const Icon(Icons.chat_bubble_outline),
                  onTap: () => onOpenProblem(problem),
                ),
                const Divider(height: 1),
              ],
            const SizedBox(height: 20),
            Text(
              'Принятые отчёты',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (reports.isEmpty)
              const Text('Принятых отчётов ещё нет.')
            else
              for (final report in reports) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${report.reportedQuantity} шт. от ${report.reportedBy}',
                  ),
                  subtitle: Text(
                    '${report.outcome} - ${report.reportedAt.toIso8601String()}'
                    '${report.reason == null ? '' : '\n${report.reason}'}',
                  ),
                ),
                const Divider(height: 1),
              ],
          ],
        ),
      ),
    );
  }
}

class _ProblemDetailSheet extends StatelessWidget {
  const _ProblemDetailSheet({
    required this.controller,
    required this.messageController,
  });

  final MasterWorkspaceController controller;
  final TextEditingController messageController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final problem = controller.selectedProblem;
        if (problem == null) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final isClosed = !problem.isOpen;
        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                problem.title ?? problem.id,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  Chip(label: Text(problem.type)),
                  Chip(label: Text(problem.status)),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final message in problem.messages) ...[
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(message.authorId),
                        subtitle: Text(message.message),
                        trailing: Text(
                          TimeOfDay.fromDateTime(
                            message.createdAt,
                          ).format(context),
                        ),
                      ),
                      const Divider(height: 1),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('problemMessageField'),
                controller: messageController,
                minLines: 1,
                maxLines: 3,
                enabled: !isClosed,
                decoration: const InputDecoration(
                  labelText: 'Сообщение',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    key: const Key('sendProblemMessageButton'),
                    onPressed: isClosed
                        ? null
                        : () async {
                            final message = messageController.text.trim();
                            if (message.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Сообщение обязательно.'),
                                ),
                              );
                              return;
                            }
                            await controller.addProblemMessage(
                              problemId: problem.id,
                              message: message,
                            );
                            messageController.clear();
                          },
                    icon: const Icon(Icons.send_outlined),
                    label: const Text('Отправить'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('startProblemButton'),
                    onPressed: isClosed || problem.status == 'inProgress'
                        ? null
                        : () => controller.transitionProblem(
                            problemId: problem.id,
                            toStatus: 'inProgress',
                          ),
                    icon: const Icon(Icons.play_arrow_outlined),
                    label: const Text('Взять в работу'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('closeProblemButton'),
                    onPressed: isClosed
                        ? null
                        : () => controller.transitionProblem(
                            problemId: problem.id,
                            toStatus: 'closed',
                          ),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Закрыть проблему'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OutboxCard extends StatelessWidget {
  const _OutboxCard({required this.items, required this.onRetry});

  final List<MasterOutboxItem> items;
  final ValueChanged<String> onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('outboxCard'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Исходящая очередь',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Отчёты о выполнении и проблемы сохраняются локально со статусами: ожидание, ошибка, отправлено.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const Text('Исходящих записей ещё нет.')
            else
              for (final item in items.take(8)) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.displayLabel),
                  subtitle: Text(
                    '${item.operationType.name} - ${item.status.name.toUpperCase()}'
                    '${item.lastError == null ? '' : ' - ${item.lastError}'}',
                  ),
                  trailing: item.status == MasterOutboxStatus.failed
                      ? TextButton(
                          onPressed: () => onRetry(item.localId),
                          child: const Text('Повторить'),
                        )
                      : null,
                ),
                const Divider(height: 1),
              ],
          ],
        ),
      ),
    );
  }
}
