import 'package:data_models/data_models.dart';
import 'package:flutter/material.dart';

import 'execution_board_controller.dart';

const _reportOutcomeOptions = <({String label, String value})>[
  (label: 'Completed', value: 'completed'),
  (label: 'Partial', value: 'partial'),
  (label: 'Not Completed', value: 'not_completed'),
  (label: 'Overrun', value: 'overrun'),
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
              title: 'Execution Control',
              subtitle:
                  'Monitor released work and send manual execution reports from the desktop client.',
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: controller.isBusy ? null : controller.refresh,
                    icon: const Icon(Icons.refresh_outlined),
                    label: Text(
                      controller.isLoading ? 'Refreshing...' : 'Refresh View',
                    ),
                  ),
                  _InfoChip(label: '${controller.tasks.length} tasks total'),
                  _InfoChip(
                    label: '${controller.activeTaskCount} active tasks',
                  ),
                  _InfoChip(
                    label: '${controller.openProblemCount} open problems',
                  ),
                  _InfoChip(label: '${controller.openWipCount} open WIP'),
                ],
              ),
            ),
            if (controller.errorMessage case final message?)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _Banner(
                  title: 'Execution error',
                  message: message,
                  color: const Color(0xFF991B1B),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _SectionCard(
                title: 'Task Monitor',
                subtitle:
                    'Browse all released tasks, keep the current selection when possible, and inspect completion progress.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _FilterChip(
                          label: 'All',
                          selected:
                              controller.filter == ExecutionTaskFilter.all,
                          onSelected: () =>
                              controller.setFilter(ExecutionTaskFilter.all),
                        ),
                        _FilterChip(
                          label: 'Active',
                          selected:
                              controller.filter == ExecutionTaskFilter.active,
                          onSelected: () =>
                              controller.setFilter(ExecutionTaskFilter.active),
                        ),
                        _FilterChip(
                          label: 'Completed',
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
                      const Text('No tasks match the current filter.')
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
                title: 'Task Detail',
                subtitle:
                    'Selected task context, progress, and manual execution report form.',
                child: controller.selectedTask == null
                    ? const Text('Select a task to inspect its execution data.')
                    : _ExecutionReportFormSection(
                        controller: controller,
                        task: controller.selectedTask!,
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _SectionCard(
                title: 'Execution Reports',
                subtitle: 'Accepted execution history for the selected task.',
                child: controller.selectedTask == null
                    ? const Text('No task selected.')
                    : controller.reports.isEmpty
                    ? const Text('No execution reports for this task yet.')
                    : Column(
                        children: controller.reports
                            .map(
                              (report) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _DetailTile(
                                  title:
                                      '${report.outcome} | ${report.reportedQuantity}',
                                  lines: [
                                    'Report: ${report.id}',
                                    'Reported by: ${report.reportedBy}',
                                    'Reported at: ${_formatDateTime(report.reportedAt)}',
                                    'Accepted: ${report.isAccepted ? 'yes' : 'no'}',
                                    if (report.acceptedAt != null)
                                      'Accepted at: ${_formatDateTime(report.acceptedAt!)}',
                                    if (report.reason != null &&
                                        report.reason!.isNotEmpty)
                                      'Reason: ${report.reason}',
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
                title: 'Problems',
                subtitle:
                    'Problem summaries for the selected task and the thread of the selected problem.',
                child: controller.selectedTask == null
                    ? const Text('No task selected.')
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (controller.taskProblems.isEmpty)
                            const Text('No problems linked to this task.')
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
                              label: const Text('Open Problems Workspace'),
                            ),
                          ],
                        ],
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _SectionCard(
                title: 'Scoped WIP',
                subtitle:
                    'WIP linked to the selected task by task id or operation occurrence.',
                child: controller.selectedTask == null
                    ? const Text('No task selected.')
                    : controller.scopedWipEntries.isEmpty
                    ? const Text('No scoped WIP for the selected task.')
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...controller.scopedWipEntries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _DetailTile(
                                title: '${entry.id} | ${entry.status}',
                                lines: [
                                  'Operation: ${entry.operationOccurrenceId}',
                                  'Balance: ${entry.balanceQuantity}',
                                  'Blocks completion: ${entry.blocksCompletion ? 'yes' : 'no'}',
                                  'Task: ${entry.taskId ?? '-'}',
                                  'Outcome: ${entry.sourceOutcome ?? '-'}',
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
                            label: const Text('Open WIP Workspace'),
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
            'Task: ${task.id}',
            'Machine: ${task.machineId}',
            'Version: ${task.versionId}',
            'Occurrence: ${task.structureOccurrenceId}',
            'Workshop: ${task.workshop}',
            'Assignee: ${task.assigneeId ?? '-'}',
            'Status: ${task.status}',
            'Required: ${task.requiredQuantity}',
            'Reported: ${task.reportedQuantity}',
            'Remaining: ${task.remainingQuantity}',
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Manual Execution Report',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          isClosed
              ? 'This task is already closed. Manual reporting is disabled.'
              : 'Supervisor can enter the execution result from the desktop client.',
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('executionReportedByField'),
          controller: _authorController,
          enabled: !isClosed && !isSubmitting,
          decoration: const InputDecoration(
            labelText: 'Reported by',
            hintText: 'Supervisor or operator id',
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
            labelText: 'Reported quantity',
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
            labelText: 'Reason / comment',
            border: OutlineInputBorder(),
          ),
        ),
        if (controller.submissionMessage case final message?) ...[
          const SizedBox(height: 12),
          _Banner(
            title: 'Execution sent',
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
          label: Text(isSubmitting ? 'Sending...' : 'Send execution report'),
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
            'Type: ${problem.type}',
            'Created: ${_formatDateTime(problem.createdAt)}',
            'Task: ${problem.taskId ?? '-'}',
            'Machine: ${problem.machineId}',
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Problem Thread',
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
                'Sent at: ${_formatDateTime(message.createdAt)}',
                'Message: ${message.message}',
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
                'Required ${task.requiredQuantity} | Reported ${task.reportedQuantity} | Remaining ${task.remainingQuantity}',
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
                '${problem.type} | ${problem.status} | messages: ${problem.messageCount}',
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
