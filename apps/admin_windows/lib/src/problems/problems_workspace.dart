import 'package:data_models/data_models.dart';
import 'package:flutter/material.dart';

import 'problems_board_controller.dart';

const _problemTypeOptions = <String>[
  'equipment',
  'materials',
  'documentation',
  'planning_error',
  'technology_error',
  'blocked_by_other_workshop',
  'other',
];

const _problemTypeLabels = <String, String>{
  'equipment': 'оборудование',
  'materials': 'материалы',
  'documentation': 'документация',
  'planning_error': 'ошибка планирования',
  'technology_error': 'ошибка технологии',
  'blocked_by_other_workshop': 'блокировано другим цехом',
  'other': 'другое',
};

String _problemTypeLabel(String type) => _problemTypeLabels[type] ?? type;

class ProblemsWorkspace extends StatefulWidget {
  const ProblemsWorkspace({
    super.key,
    required this.controller,
    required this.onOpenTask,
    required this.onOpenWip,
  });

  final ProblemsBoardController controller;
  final Future<void> Function(String taskId) onOpenTask;
  final Future<void> Function(String taskId) onOpenWip;

  @override
  State<ProblemsWorkspace> createState() => _ProblemsWorkspaceState();
}

class _ProblemsWorkspaceState extends State<ProblemsWorkspace> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _messageController = TextEditingController();
  String? _createTaskId;
  String _createType = _problemTypeOptions.first;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        _createTaskId ??= widget.controller.tasks.isNotEmpty
            ? widget.controller.tasks.first.id
            : null;
        final selectedProblem = widget.controller.selectedProblem;
        return ListView(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Проблемы',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Управление проблемами с фильтрами, перепиской и переходами между разделами.',
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.icon(
                          onPressed: widget.controller.isBusy
                              ? null
                              : widget.controller.refresh,
                          icon: const Icon(Icons.refresh_outlined),
                          label: Text(
                            widget.controller.isLoading
                                ? 'Обновление...'
                                : 'Обновить проблемы',
                          ),
                        ),
                        _Chip(
                          label:
                              '${widget.controller.problems.length} problems',
                        ),
                        _Chip(
                          label:
                              '${widget.controller.problems.where((problem) => problem.isOpen).length} open',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (widget.controller.errorMessage case final message?)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _Banner(
                  title: 'Ошибка проблемы',
                  message: message,
                  color: const Color(0xFF991B1B),
                ),
              ),
            if (widget.controller.successMessage case final message?)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _Banner(
                  title: 'Проблема обновлена',
                  message: message,
                  color: const Color(0xFF166534),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Создать проблему',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _createTaskId,
                        decoration: const InputDecoration(
                          labelText: 'Задача',
                          border: OutlineInputBorder(),
                        ),
                        items: widget.controller.tasks
                            .map(
                              (task) => DropdownMenuItem<String>(
                                value: task.id,
                                child: Text(
                                  '${task.structureDisplayName} | ${task.operationName}',
                                ),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) =>
                            setState(() => _createTaskId = value),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _createType,
                        decoration: const InputDecoration(
                          labelText: 'Тип',
                          border: OutlineInputBorder(),
                        ),
                        items: _problemTypeOptions
                            .map(
                              (type) => DropdownMenuItem<String>(
                                value: type,
                                child: Text(_problemTypeLabel(type)),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _createType = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('problemTitleField'),
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Название',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('problemDescriptionField'),
                        controller: _descriptionController,
                        minLines: 2,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Описание',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        key: const Key('createProblemButton'),
                        onPressed:
                            widget.controller.isBusy || _createTaskId == null
                            ? null
                            : () => widget.controller.createProblem(
                                taskId: _createTaskId!,
                                type: _createType,
                                title: _titleController.text,
                                description: _descriptionController.text,
                              ),
                        icon: const Icon(Icons.report_problem_outlined),
                        label: const Text('Создать проблему'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _FilterBar(controller: widget.controller),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final useColumn = constraints.maxWidth < 1080;
                  final listPane = _Pane(
                    title: 'Реестр проблем',
                    child: widget.controller.visibleProblems.isEmpty
                        ? const Text('Нет проблем, соответствующих фильтрам.')
                        : Column(
                            children: widget.controller.visibleProblems
                                .map(
                                  (problem) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _ProblemTile(
                                      problem: problem,
                                      selected:
                                          problem.id ==
                                          widget.controller.selectedProblemId,
                                      onTap: () => widget.controller
                                          .selectProblem(problem.id),
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                          ),
                  );
                  final detailPane = _Pane(
                    title: 'Детали проблемы',
                    child: selectedProblem == null
                        ? const Text(
                            'Выберите проблему для просмотра переписки.',
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _DetailTile(
                                title:
                                    '${selectedProblem.title ?? selectedProblem.id} | ${selectedProblem.status}',
                                lines: [
                                  'Тип: ${_problemTypeLabel(selectedProblem.type)}',
                                  'Оборудование: ${selectedProblem.machineId}',
                                  'Задача: ${selectedProblem.taskId ?? '-'}',
                                  'Сообщений: ${selectedProblem.messages.length}',
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  FilledButton.icon(
                                    onPressed: selectedProblem.taskId == null
                                        ? null
                                        : () => widget.onOpenTask(
                                            selectedProblem.taskId!,
                                          ),
                                    icon: const Icon(Icons.task_outlined),
                                    label: const Text('Открыть задачу'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: selectedProblem.taskId == null
                                        ? null
                                        : () => widget.onOpenWip(
                                            selectedProblem.taskId!,
                                          ),
                                    icon: const Icon(
                                      Icons.inventory_2_outlined,
                                    ),
                                    label: const Text('Открыть НЗП'),
                                  ),
                                  OutlinedButton.icon(
                                    key: const Key('problemInProgressButton'),
                                    onPressed:
                                        widget.controller.isBusy ||
                                            selectedProblem.status ==
                                                'inProgress' ||
                                            selectedProblem.status == 'closed'
                                        ? null
                                        : () => widget.controller
                                              .transitionSelectedProblem(
                                                'inProgress',
                                              ),
                                    icon: const Icon(Icons.play_arrow_outlined),
                                    label: const Text('Взять в работу'),
                                  ),
                                  OutlinedButton.icon(
                                    key: const Key('problemClosedButton'),
                                    onPressed:
                                        widget.controller.isBusy ||
                                            selectedProblem.status == 'closed'
                                        ? null
                                        : () => widget.controller
                                              .transitionSelectedProblem(
                                                'closed',
                                              ),
                                    icon: const Icon(
                                      Icons.check_circle_outline,
                                    ),
                                    label: const Text('Закрыть проблему'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ...selectedProblem.messages.map(
                                (message) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _DetailTile(
                                    title: message.authorId,
                                    lines: [
                                      message.message,
                                      message.createdAt.toIso8601String(),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                key: const Key('problemMessageField'),
                                controller: _messageController,
                                minLines: 1,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  labelText: 'Сообщение',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                key: const Key('sendProblemMessageButton'),
                                onPressed:
                                    widget.controller.isBusy ||
                                        selectedProblem.status == 'closed'
                                    ? null
                                    : () => widget.controller.addMessage(
                                        _messageController.text,
                                      ),
                                icon: const Icon(Icons.send_outlined),
                                label: const Text('Отправить'),
                              ),
                            ],
                          ),
                  );

                  if (useColumn) {
                    return Column(
                      children: [
                        listPane,
                        const SizedBox(height: 16),
                        detailPane,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 4, child: listPane),
                      const SizedBox(width: 16),
                      Expanded(flex: 6, child: detailPane),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.controller});

  final ProblemsBoardController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _DropdownFilter(
              label: 'Статус',
              value: controller.statusFilter,
              options: controller.statusOptions,
              onChanged: (value) {
                controller.setStatusFilter(value);
              },
            ),
            _DropdownFilter(
              label: 'Тип',
              value: controller.typeFilter,
              options: controller.typeOptions,
              onChanged: (value) {
                controller.setTypeFilter(value);
              },
            ),
            _DropdownFilter(
              label: 'Оборудование',
              value: controller.machineFilter,
              options: controller.machineOptions,
              onChanged: (value) {
                controller.setMachineFilter(value);
              },
            ),
            _DropdownFilter(
              label: 'Задача',
              value: controller.taskFilter,
              options: controller.tasks
                  .map((task) => task.id)
                  .toList(growable: false),
              onChanged: (value) {
                controller.setTaskFilter(value);
              },
            ),
            OutlinedButton.icon(
              onPressed: () {
                controller.clearFilters();
              },
              icon: const Icon(Icons.clear_all_outlined),
              label: const Text('Clear Filters'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownFilter extends StatelessWidget {
  const _DropdownFilter({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: options
            .map(
              (option) =>
                  DropdownMenuItem<String>(value: option, child: Text(option)),
            )
            .toList(growable: false),
        onChanged: onChanged,
      ),
    );
  }
}

class _Pane extends StatelessWidget {
  const _Pane({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          child,
        ],
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
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                '${_problemTypeLabel(problem.type)} | ${problem.status} | задача ${problem.taskId ?? '-'}',
              ),
            ],
          ),
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

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(label),
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
