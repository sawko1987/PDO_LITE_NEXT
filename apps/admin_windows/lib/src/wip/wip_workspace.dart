import 'package:data_models/data_models.dart';
import 'package:flutter/material.dart';

import 'wip_board_controller.dart';

class WipWorkspace extends StatelessWidget {
  const WipWorkspace({
    super.key,
    required this.controller,
    required this.onOpenTask,
    required this.onOpenPlan,
    required this.onOpenProblems,
  });

  final WipBoardController controller;
  final Future<void> Function(String taskId) onOpenTask;
  final Future<void> Function(String planId) onOpenPlan;
  final Future<void> Function(String taskId) onOpenProblems;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final entry = controller.selectedEntry;
        return ListView(
          children: [
            _SectionCard(
              title: 'Монитор НЗП',
              subtitle:
                  'Просмотр открытых и архивных записей НЗП с быстрым переходом к задачам, планам и проблемам.',
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: controller.isLoading ? null : controller.refresh,
                    icon: const Icon(Icons.refresh_outlined),
                    label: Text(
                      controller.isLoading ? 'Обновление...' : 'Обновить НЗП',
                    ),
                  ),
                  _InfoChip(label: '${controller.entries.length} entries'),
                  _InfoChip(
                    label:
                        '${controller.entries.where((entry) => entry.blocksCompletion).length} блокируют завершение',
                  ),
                ],
              ),
            ),
            if (controller.errorMessage case final message?)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _Banner(
                  title: 'Ошибка НЗП',
                  message: message,
                  color: const Color(0xFF991B1B),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _SectionCard(
                title: 'Фильтры',
                subtitle:
                    'Фильтрация по оборудованию, версии, статусу, цеху, операции или задаче.',
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _FilterDropdown(
                      label: 'Machine',
                      value: controller.machineFilter,
                      options: controller.machineOptions,
                      onChanged: controller.setMachineFilter,
                    ),
                    _FilterDropdown(
                      label: 'Version',
                      value: controller.versionFilter,
                      options: controller.versionOptions,
                      onChanged: controller.setVersionFilter,
                    ),
                    _FilterDropdown(
                      label: 'Status',
                      value: controller.statusFilter,
                      options: controller.statusOptions,
                      onChanged: controller.setStatusFilter,
                    ),
                    _FilterDropdown(
                      label: 'Workshop',
                      value: controller.workshopFilter,
                      options: controller.workshopOptions,
                      onChanged: controller.setWorkshopFilter,
                    ),
                    _FilterDropdown(
                      label: 'Operation',
                      value: controller.operationFilter,
                      options: controller.operationOptions,
                      onChanged: controller.setOperationFilter,
                    ),
                    OutlinedButton.icon(
                      onPressed: controller.clearFilters,
                      icon: const Icon(Icons.clear_all_outlined),
                      label: const Text('Clear Filters'),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final useColumn = constraints.maxWidth < 1080;
                  final listPane = _Pane(
                    title: 'Entries',
                    subtitle: 'Select an entry to inspect its context.',
                    child: controller.visibleEntries.isEmpty
                        ? const Text(
                            'No WIP entries match the current filters.',
                          )
                        : Column(
                            children: controller.visibleEntries
                                .map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _WipTile(
                                      entry: item,
                                      selected:
                                          item.id == controller.selectedEntryId,
                                      onTap: () =>
                                          controller.selectEntry(item.id),
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                          ),
                  );
                  final detailPane = _Pane(
                    title: 'Detail',
                    subtitle:
                        'Use quick links to continue investigation in task, plan, or problems.',
                    child: entry == null
                        ? const Text('Select a WIP entry.')
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (entry.blocksCompletion)
                                const _Banner(
                                  title: 'Blocking WIP',
                                  message:
                                      'This entry still blocks completion of the linked product flow.',
                                  color: Color(0xFF92400E),
                                ),
                              if (entry.blocksCompletion)
                                const SizedBox(height: 12),
                              _DetailTile(
                                title:
                                    '${entry.structureDisplayName ?? entry.structureOccurrenceId} | ${entry.operationName ?? entry.operationOccurrenceId}',
                                lines: [
                                  'Entry: ${entry.id}',
                                  'Machine: ${entry.machineId}',
                                  'Version: ${entry.versionId}',
                                  'Status: ${entry.status}',
                                  'Workshop: ${entry.workshop ?? '-'}',
                                  'Balance: ${entry.balanceQuantity}',
                                  'Task: ${entry.taskId ?? '-'}',
                                  'Plan: ${entry.planId ?? '-'}',
                                  'Source outcome: ${entry.sourceOutcome ?? '-'}',
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  FilledButton.icon(
                                    onPressed: entry.taskId == null
                                        ? null
                                        : () => onOpenTask(entry.taskId!),
                                    icon: const Icon(Icons.task_outlined),
                                    label: const Text('Open Task'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: entry.planId == null
                                        ? null
                                        : () => onOpenPlan(entry.planId!),
                                    icon: const Icon(Icons.playlist_add_check),
                                    label: const Text('Open Plan'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: entry.taskId == null
                                        ? null
                                        : () => onOpenProblems(entry.taskId!),
                                    icon: const Icon(
                                      Icons.report_problem_outlined,
                                    ),
                                    label: const Text('Open Problems'),
                                  ),
                                ],
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

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
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

class _WipTile extends StatelessWidget {
  const _WipTile({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final WipEntryDto entry;
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
                '${entry.structureDisplayName ?? entry.structureOccurrenceId} | ${entry.operationName ?? entry.operationOccurrenceId}',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                '${entry.status} | ${entry.workshop ?? '-'} | balance ${entry.balanceQuantity}',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pane extends StatelessWidget {
  const _Pane({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
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
          const SizedBox(height: 4),
          Text(subtitle),
          const SizedBox(height: 16),
          child,
        ],
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

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
