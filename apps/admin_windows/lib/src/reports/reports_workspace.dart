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
              title: 'Отчёты',
              subtitle:
                  'Оперативные сводки: план-факт, сменное выполнение, проблемы и общее состояние производства.',
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: widget.controller.isBusy
                        ? null
                        : widget.controller.bootstrap,
                    icon: const Icon(Icons.refresh_outlined),
                    label: const Text('Обновить всё'),
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
                  title: 'Ошибка отчётов',
                  message: message,
                  color: const Color(0xFF991B1B),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _SectionCard(
                title: 'Сводка',
                subtitle:
                    'Агрегированные производственные показатели по текущей области.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _MachineDropdown(
                          label: 'Оборудование',
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
                                ? 'Загрузка...'
                                : 'Обновить сводку',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (summary == null)
                      const Text('Сводка ещё не загружена.')
                    else
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _MetricCard(
                            label: 'Всего планов',
                            value: summary.totalPlans.toString(),
                          ),
                          _MetricCard(
                            label: 'Активных задач',
                            value: summary.activeTasks.toString(),
                          ),
                          _MetricCard(
                            label: 'Открытых проблем',
                            value: summary.openProblems.toString(),
                          ),
                          _MetricCard(
                            label: 'Блокирующих НЗП',
                            value: summary.blockingWipEntries.toString(),
                          ),
                          _MetricCard(
                            label: 'Всего отчётов',
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
                title: 'План-факт',
                subtitle: 'Баланс выполнения по вхождениям структуры.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _MachineDropdown(
                          label: 'Оборудование',
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
                          label: 'С',
                          controller: _planFactFromController,
                          onChanged: (value) {
                            widget.controller.setPlanFactDateRange(
                              value,
                              _planFactToController.text,
                            );
                          },
                        ),
                        _DateField(
                          label: 'По',
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
                                ? 'Загрузка...'
                                : 'Загрузить',
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
                          DataColumn(label: Text('Название')),
                          DataColumn(label: Text('Операция')),
                          DataColumn(label: Text('Цех')),
                          DataColumn(label: Text('Запланировано')),
                          DataColumn(label: Text('Выполнено')),
                          DataColumn(label: Text('Осталось')),
                          DataColumn(label: Text('Выполнение %')),
                          DataColumn(label: Text('Задачи')),
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
                title: 'Сменный отчёт',
                subtitle: 'Задачи с фактами выполнения за выбранный день.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _DateField(
                          label: 'Дата',
                          controller: _shiftDateController,
                          onChanged: (value) {
                            widget.controller.setShiftDate(value);
                          },
                        ),
                        _MachineDropdown(
                          label: 'Оборудование',
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
                              labelText: 'Мастер',
                              hintText: 'Идентификатор исполнителя',
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
                                ? 'Загрузка...'
                                : 'Загрузить',
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
                title: 'Отчёт по проблемам',
                subtitle: 'Список проблем с детализацией по задачам.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _MachineDropdown(
                          label: 'Оборудование',
                          value: effectiveProblemMachineId,
                          machines: widget.controller.machines,
                          onChanged: (value) {
                            setState(() => _problemMachineId = value);
                            widget.controller.setProblemMachineFilter(value);
                          },
                        ),
                        _DropdownField(
                          label: 'Статус',
                          value: _problemStatus,
                          options: const ['открыт', 'в работе', 'закрыт'],
                          onChanged: (value) {
                            setState(() => _problemStatus = value);
                            widget.controller.setProblemStatusFilter(value);
                          },
                        ),
                        _DropdownField(
                          label: 'Тип',
                          value: _problemType,
                          options: const [
                            'оборудование',
                            'материалы',
                            'документация',
                            'ошибка планирования',
                            'ошибка технологии',
                            'блокировано другим цехом',
                            'другое',
                          ],
                          onChanged: (value) {
                            setState(() => _problemType = value);
                            widget.controller.setProblemTypeFilter(value);
                          },
                        ),
                        _DateField(
                          label: 'С',
                          controller: _problemFromController,
                          onChanged: (value) {
                            widget.controller.setProblemDateRange(
                              value,
                              _problemToController.text,
                            );
                          },
                        ),
                        _DateField(
                          label: 'По',
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
                                ? 'Загрузка...'
                                : 'Загрузить',
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
          labelText: 'План',
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
          hintText: 'ГГГГ-ММ-ДД',
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
        'Задача ${item.taskId} | ${item.status} | ${item.reportedQuantity}/${item.requiredQuantity} шт.',
      ),
      children: [
        _DetailTile(
          title: item.workshop,
          lines: [
            'Осталось: ${item.remainingQuantity}',
            'Закрыта: ${item.isClosed ? 'да' : 'нет'}',
            'Исполнитель: ${item.assigneeId ?? '-'}',
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
                'Исход: ${report.outcome}',
                'Количество: ${report.reportedQuantity}',
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
        DataColumn(label: Text('Название')),
        DataColumn(label: Text('Тип')),
        DataColumn(label: Text('Статус')),
        DataColumn(label: Text('Структура')),
        DataColumn(label: Text('Операция')),
        DataColumn(label: Text('Создана')),
        DataColumn(label: Text('Сообщения')),
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
