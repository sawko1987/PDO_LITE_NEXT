import 'package:data_models/data_models.dart';
import 'package:flutter/material.dart';

import 'reports_board_controller.dart';

class ReportsWorkspace extends StatefulWidget {
  const ReportsWorkspace({super.key, required this.controller});

  final ReportsBoardController controller;

  @override
  State<ReportsWorkspace> createState() => _ReportsWorkspaceState();
}

class _ReportsWorkspaceState extends State<ReportsWorkspace> {
  late final TextEditingController _planFactFromController;
  late final TextEditingController _planFactToController;
  late final TextEditingController _shiftDateController;
  late final TextEditingController _shiftAssigneeController;
  late final TextEditingController _problemFromController;
  late final TextEditingController _problemToController;
  String? _summaryMachineId;
  String? _planFactMachineId;
  String? _planFactVersionId;
  String? _planFactPlanId;
  String? _shiftMachineId;
  String? _problemMachineId;
  String? _problemStatus;
  String? _problemType;

  @override
  void initState() {
    super.initState();
    _summaryMachineId = widget.controller.machineFilter;
    _planFactMachineId = widget.controller.planFactMachineFilter;
    _planFactVersionId = widget.controller.planFactVersionFilter;
    _planFactPlanId = widget.controller.planFactPlanFilter;
    _shiftMachineId = widget.controller.shiftMachineFilter;
    _problemMachineId = widget.controller.problemMachineFilter;
    _problemStatus = widget.controller.problemStatusFilter;
    _problemType = widget.controller.problemTypeFilter;
    _planFactFromController = TextEditingController(
      text: widget.controller.planFactFromDate ?? '',
    );
    _planFactToController = TextEditingController(
      text: widget.controller.planFactToDate ?? '',
    );
    _shiftDateController = TextEditingController(
      text: widget.controller.shiftDate ?? '',
    );
    _shiftAssigneeController = TextEditingController(
      text: widget.controller.shiftAssigneeFilter ?? '',
    );
    _problemFromController = TextEditingController(
      text: widget.controller.problemFromDate ?? '',
    );
    _problemToController = TextEditingController(
      text: widget.controller.problemToDate ?? '',
    );
  }

  @override
  void dispose() {
    _planFactFromController.dispose();
    _planFactToController.dispose();
    _shiftDateController.dispose();
    _shiftAssigneeController.dispose();
    _problemFromController.dispose();
    _problemToController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final summary = widget.controller.summary;
        final planFactLoaded = widget.controller.planFactLoaded;
        final shiftLoaded = widget.controller.shiftLoaded;
        final problemLoaded = widget.controller.problemLoaded;
        final effectiveSummaryMachineId = _effectiveMachineId(
          _summaryMachineId,
          widget.controller.machines,
        );
        final effectivePlanFactMachineId = _effectiveMachineId(
          _planFactMachineId,
          widget.controller.machines,
        );
        final effectiveShiftMachineId = _effectiveMachineId(
          _shiftMachineId,
          widget.controller.machines,
        );
        final effectiveProblemMachineId = _effectiveMachineId(
          _problemMachineId,
          widget.controller.machines,
        );
        final effectivePlanFactPlanId = _effectivePlanId(
          _planFactPlanId,
          widget.controller.plans,
        );

        return ListView(
          children: [
            _SectionCard(
              title: 'Reports',
              subtitle:
                  'Operational summaries for plan-fact, shift execution, problems, and overall production health.',
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: widget.controller.isBusy
                        ? null
                        : widget.controller.bootstrap,
                    icon: const Icon(Icons.refresh_outlined),
                    label: const Text('Refresh All'),
                  ),
                  _InfoChip(
                    label: '${widget.controller.machines.length} machines',
                  ),
                  _InfoChip(label: '${widget.controller.plans.length} plans'),
                  _InfoChip(
                    label:
                        'Mode: ${widget.controller.reportTypeFilter.replaceAll('_', ' ')}',
                  ),
                ],
              ),
            ),
            if (widget.controller.errorMessage case final message?)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _Banner(
                  title: 'Reports error',
                  message: message,
                  color: const Color(0xFF991B1B),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _SectionCard(
                title: 'Summary',
                subtitle: 'Aggregated production indicators by current scope.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _MachineDropdown(
                          label: 'Machine',
                          value: effectiveSummaryMachineId,
                          machines: widget.controller.machines,
                          onChanged: (value) {
                            setState(() => _summaryMachineId = value);
                            widget.controller.setMachineFilter(value);
                          },
                        ),
                        FilledButton.icon(
                          onPressed: widget.controller.isSummaryLoading
                              ? null
                              : () => widget.controller.loadSummary(
                                  machineId: effectiveSummaryMachineId,
                                ),
                          icon: const Icon(Icons.analytics_outlined),
                          label: Text(
                            widget.controller.isSummaryLoading
                                ? 'Loading...'
                                : 'Refresh Summary',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (summary == null)
                      const Text('Summary is not loaded yet.')
                    else
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _MetricCard(
                            label: 'Total Plans',
                            value: summary.totalPlans.toString(),
                          ),
                          _MetricCard(
                            label: 'Active Tasks',
                            value: summary.activeTasks.toString(),
                          ),
                          _MetricCard(
                            label: 'Open Problems',
                            value: summary.openProblems.toString(),
                          ),
                          _MetricCard(
                            label: 'Blocking WIP',
                            value: summary.blockingWipEntries.toString(),
                          ),
                          _MetricCard(
                            label: 'Total Reports',
                            value: summary.totalExecutionReports.toString(),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _SectionCard(
                title: 'Plan-Fact',
                subtitle: 'Execution balance by structure occurrence.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _MachineDropdown(
                          label: 'Machine',
                          value: effectivePlanFactMachineId,
                          machines: widget.controller.machines,
                          onChanged: (value) {
                            setState(() => _planFactMachineId = value);
                            widget.controller.setPlanFactMachineFilter(value);
                          },
                        ),
                        _PlanDropdown(
                          value: effectivePlanFactPlanId,
                          plans: widget.controller.plans,
                          onChanged: (value) {
                            setState(() => _planFactPlanId = value);
                            widget.controller.setPlanFactPlanFilter(value);
                          },
                        ),
                        _DateField(
                          label: 'From',
                          controller: _planFactFromController,
                          onChanged: (value) {
                            widget.controller.setPlanFactDateRange(
                              value,
                              _planFactToController.text,
                            );
                          },
                        ),
                        _DateField(
                          label: 'To',
                          controller: _planFactToController,
                          onChanged: (value) {
                            widget.controller.setPlanFactDateRange(
                              _planFactFromController.text,
                              value,
                            );
                          },
                        ),
                        FilledButton.icon(
                          onPressed: widget.controller.isPlanFactLoading
                              ? null
                              : () => widget.controller.loadPlanFactReport(
                                  machineId: effectivePlanFactMachineId,
                                  versionId: _planFactVersionId,
                                  planId: effectivePlanFactPlanId,
                                  fromDate: _planFactFromController.text,
                                  toDate: _planFactToController.text,
                                ),
                          icon: const Icon(Icons.download_outlined),
                          label: Text(
                            widget.controller.isPlanFactLoading
                                ? 'Loading...'
                                : 'Load',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (!planFactLoaded)
                      const Text('Выберите параметры и загрузите отчёт')
                    else if (widget.controller.planFactReport.isEmpty)
                      const Text('Нет данных по выбранным фильтрам.')
                    else
                      _ScrollableTable(
                        columns: const [
                          DataColumn(label: Text('Display Name')),
                          DataColumn(label: Text('Operation')),
                          DataColumn(label: Text('Workshop')),
                          DataColumn(label: Text('Requested')),
                          DataColumn(label: Text('Reported')),
                          DataColumn(label: Text('Remaining')),
                          DataColumn(label: Text('Completion %')),
                          DataColumn(label: Text('Tasks')),
                        ],
                        rows: widget.controller.planFactReport
                            .map(
                              (item) => DataRow(
                                cells: [
                                  DataCell(Text(item.displayName)),
                                  DataCell(Text(item.operationName)),
                                  DataCell(Text(item.workshop)),
                                  DataCell(
                                    Text(item.requestedQuantity.toString()),
                                  ),
                                  DataCell(
                                    Text(item.reportedQuantity.toString()),
                                  ),
                                  DataCell(
                                    Text(item.remainingQuantity.toString()),
                                  ),
                                  DataCell(
                                    Text(
                                      '${item.completionPercent.toStringAsFixed(0)}%',
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      '${item.taskCount}/${item.closedTaskCount}',
                                    ),
                                  ),
                                ],
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
                title: 'Shift Report',
                subtitle: 'Tasks with execution facts for a selected day.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _DateField(
                          label: 'Date',
                          controller: _shiftDateController,
                          onChanged: (value) {
                            widget.controller.setShiftDate(value);
                          },
                        ),
                        _MachineDropdown(
                          label: 'Machine',
                          value: effectiveShiftMachineId,
                          machines: widget.controller.machines,
                          onChanged: (value) {
                            setState(() => _shiftMachineId = value);
                            widget.controller.setShiftMachineFilter(value);
                          },
                        ),
                        SizedBox(
                          width: 220,
                          child: TextField(
                            controller: _shiftAssigneeController,
                            decoration: const InputDecoration(
                              labelText: 'Master',
                              hintText: 'assigneeId',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: widget.controller.setShiftAssigneeFilter,
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: widget.controller.isShiftLoading
                              ? null
                              : () => widget.controller.loadShiftReport(
                                  _shiftDateController.text,
                                  machineId: effectiveShiftMachineId,
                                  assigneeId: _shiftAssigneeController.text,
                                ),
                          icon: const Icon(Icons.schedule_outlined),
                          label: Text(
                            widget.controller.isShiftLoading
                                ? 'Loading...'
                                : 'Load',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (!shiftLoaded)
                      const Text('Укажите дату и загрузите сменный отчёт.')
                    else if (widget.controller.shiftReport.isEmpty)
                      const Text(
                        'Нет заданий с фактами выполнения за эту дату.',
                      )
                    else
                      _ShiftTable(items: widget.controller.shiftReport),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _SectionCard(
                title: 'Problems Report',
                subtitle: 'Problem list with task drill-down context.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _MachineDropdown(
                          label: 'Machine',
                          value: effectiveProblemMachineId,
                          machines: widget.controller.machines,
                          onChanged: (value) {
                            setState(() => _problemMachineId = value);
                            widget.controller.setProblemMachineFilter(value);
                          },
                        ),
                        _DropdownField(
                          label: 'Status',
                          value: _problemStatus,
                          options: const ['open', 'inProgress', 'closed'],
                          onChanged: (value) {
                            setState(() => _problemStatus = value);
                            widget.controller.setProblemStatusFilter(value);
                          },
                        ),
                        _DropdownField(
                          label: 'Type',
                          value: _problemType,
                          options: const [
                            'equipment',
                            'materials',
                            'documentation',
                            'planning_error',
                            'technology_error',
                            'blocked_by_other_workshop',
                            'other',
                          ],
                          onChanged: (value) {
                            setState(() => _problemType = value);
                            widget.controller.setProblemTypeFilter(value);
                          },
                        ),
                        _DateField(
                          label: 'From',
                          controller: _problemFromController,
                          onChanged: (value) {
                            widget.controller.setProblemDateRange(
                              value,
                              _problemToController.text,
                            );
                          },
                        ),
                        _DateField(
                          label: 'To',
                          controller: _problemToController,
                          onChanged: (value) {
                            widget.controller.setProblemDateRange(
                              _problemFromController.text,
                              value,
                            );
                          },
                        ),
                        FilledButton.icon(
                          onPressed: widget.controller.isProblemLoading
                              ? null
                              : () => widget.controller.loadProblemReport(
                                  machineId: effectiveProblemMachineId,
                                  status: _problemStatus,
                                  type: _problemType,
                                  fromDate: _problemFromController.text,
                                  toDate: _problemToController.text,
                                ),
                          icon: const Icon(Icons.warning_amber_outlined),
                          label: Text(
                            widget.controller.isProblemLoading
                                ? 'Loading...'
                                : 'Load',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (!problemLoaded)
                      const Text('Выберите параметры и загрузите отчёт.')
                    else if (widget.controller.problemReport.isEmpty)
                      const Text('Нет проблем по выбранным фильтрам.')
                    else
                      _ProblemTable(items: widget.controller.problemReport),
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
      width: 190,
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
            label,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _MachineDropdown extends StatelessWidget {
  const _MachineDropdown({
    required this.label,
    required this.value,
    required this.machines,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<MachineSummaryDto> machines;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: DropdownButtonFormField<String>(
        key: ValueKey('$label-$value-${machines.length}'),
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: machines
            .map(
              (machine) => DropdownMenuItem<String>(
                value: machine.id,
                child: Text('${machine.code} - ${machine.name}'),
              ),
            )
            .toList(growable: false),
        onChanged: onChanged,
      ),
    );
  }
}

class _PlanDropdown extends StatelessWidget {
  const _PlanDropdown({
    required this.value,
    required this.plans,
    required this.onChanged,
  });

  final String? value;
  final List<PlanSummaryDto> plans;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: DropdownButtonFormField<String>(
        key: ValueKey('plan-$value-${plans.length}'),
        initialValue: value,
        decoration: const InputDecoration(
          labelText: 'Plan',
          border: OutlineInputBorder(),
        ),
        items: plans
            .map(
              (plan) => DropdownMenuItem<String>(
                value: plan.id,
                child: Text('${plan.title} (${plan.status})'),
              ),
            )
            .toList(growable: false),
        onChanged: onChanged,
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
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
        key: ValueKey('$label-$value-${options.length}'),
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

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: 'YYYY-MM-DD',
          border: const OutlineInputBorder(),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _ScrollableTable extends StatelessWidget {
  const _ScrollableTable({required this.columns, required this.rows});

  final List<DataColumn> columns;
  final List<DataRow> rows;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(columns: columns, rows: rows),
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

String? _effectiveMachineId(String? value, List<MachineSummaryDto> machines) {
  if (value == null || value.isEmpty) {
    return null;
  }
  return machines.any((machine) => machine.id == value) ? value : null;
}

String? _effectivePlanId(String? value, List<PlanSummaryDto> plans) {
  if (value == null || value.isEmpty) {
    return null;
  }
  return plans.any((plan) => plan.id == value) ? value : null;
}

class _ShiftRowTile extends StatelessWidget {
  const _ShiftRowTile({required this.item});

  final ShiftReportItemDto item;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 12),
      title: Text(
        '${item.structureDisplayName} | ${item.operationName}',
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        'Task ${item.taskId} | ${item.status} | ${item.reportedQuantity}/${item.requiredQuantity} pcs',
      ),
      children: [
        _DetailTile(
          title: item.workshop,
          lines: [
            'Remaining: ${item.remainingQuantity}',
            'Closed: ${item.isClosed ? 'yes' : 'no'}',
            'Assignee: ${item.assigneeId ?? '-'}',
          ],
        ),
        const SizedBox(height: 10),
        ...item.reports.map(
          (report) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _DetailTile(
              title: report.reportedBy,
              lines: [
                report.reportedAt.toIso8601String(),
                'Outcome: ${report.outcome}',
                'Quantity: ${report.reportedQuantity}',
                if (report.reason != null) report.reason!,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProblemTable extends StatelessWidget {
  const _ProblemTable({required this.items});

  final List<ProblemReportItemDto> items;

  @override
  Widget build(BuildContext context) {
    return _ScrollableTable(
      columns: const [
        DataColumn(label: Text('Title')),
        DataColumn(label: Text('Type')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Structure')),
        DataColumn(label: Text('Operation')),
        DataColumn(label: Text('Created At')),
        DataColumn(label: Text('Messages')),
      ],
      rows: items
          .map(
            (item) => DataRow(
              cells: [
                DataCell(Text(item.title)),
                DataCell(Text(item.type)),
                DataCell(Text(item.status)),
                DataCell(Text(item.structureDisplayName)),
                DataCell(Text(item.operationName)),
                DataCell(Text(item.createdAt.toIso8601String())),
                DataCell(Text(item.messageCount.toString())),
              ],
            ),
          )
          .toList(growable: false),
    );
  }
}

class _ShiftTable extends StatelessWidget {
  const _ShiftTable({required this.items});

  final List<ShiftReportItemDto> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ShiftRowTile(item: item),
            ),
          )
          .toList(growable: false),
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
