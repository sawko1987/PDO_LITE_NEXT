import 'package:data_models/data_models.dart';
import 'package:flutter/material.dart';

import 'archive_board_controller.dart';

class ArchiveWorkspace extends StatefulWidget {
  const ArchiveWorkspace({
    super.key,
    required this.controller,
    required this.onOpenInReports,
  });

  final ArchiveBoardController controller;
  final Future<void> Function(String planId) onOpenInReports;

  @override
  State<ArchiveWorkspace> createState() => _ArchiveWorkspaceState();
}

class _ArchiveWorkspaceState extends State<ArchiveWorkspace> {
  late final TextEditingController _fromDateController;
  late final TextEditingController _toDateController;
  String? _machineId;
  String _status = 'completed';

  @override
  void initState() {
    super.initState();
    _machineId = widget.controller.machineFilter;
    _status = widget.controller.status;
    _fromDateController = TextEditingController(
      text: widget.controller.fromDate ?? '',
    );
    _toDateController = TextEditingController(
      text: widget.controller.toDate ?? '',
    );
  }

  @override
  void dispose() {
    _fromDateController.dispose();
    _toDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 260,
                      child: DropdownButtonFormField<String>(
                        initialValue: _machineId,
                        decoration: const InputDecoration(
                          labelText: 'Machine',
                          border: OutlineInputBorder(),
                        ),
                        items: widget.controller.machines
                            .map(
                              (machine) => DropdownMenuItem<String>(
                                value: machine.id,
                                child: Text(
                                  '${machine.code} - ${machine.name}',
                                ),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          setState(() => _machineId = value);
                          widget.controller.setMachineFilter(value);
                        },
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: TextField(
                        controller: _fromDateController,
                        decoration: const InputDecoration(
                          labelText: 'From',
                          hintText: 'YYYY-MM-DD',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: TextField(
                        controller: _toDateController,
                        decoration: const InputDecoration(
                          labelText: 'To',
                          hintText: 'YYYY-MM-DD',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: DropdownButtonFormField<String>(
                        initialValue: _status,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'completed',
                            child: Text('completed'),
                          ),
                          DropdownMenuItem(
                            value: 'cancelled',
                            child: Text('cancelled'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() => _status = value);
                          widget.controller.setStatus(value);
                        },
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: widget.controller.isBusy ? null : _loadArchive,
                      icon: const Icon(Icons.history_outlined),
                      label: Text(
                        widget.controller.isLoading
                            ? 'Loading...'
                            : 'Load Archive',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.controller.errorMessage case final message?)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFB91C1C),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Card(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: widget.controller.plans.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final plan = widget.controller.plans[index];
                          final isSelected =
                              widget.controller.selectedPlan?.id == plan.id;
                          return ListTile(
                            selected: isSelected,
                            title: Text(plan.title),
                            subtitle: Text(
                              '${plan.machineCode} | ${plan.status} | ${plan.completedAt.toIso8601String()}',
                            ),
                            trailing: Text(
                              '${plan.completionPercent.toStringAsFixed(0)}%',
                            ),
                            onTap: () => widget.controller.openPlan(plan.id),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: _ArchiveDetailPane(
                          plan: widget.controller.selectedPlan,
                          summary: widget.controller.selectedSummary,
                          isLoading: widget.controller.isDetailLoading,
                          onOpenInReports:
                              widget.controller.selectedPlan == null
                              ? null
                              : () => widget.onOpenInReports(
                                  widget.controller.selectedPlan!.id,
                                ),
                        ),
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

  Future<void> _loadArchive() {
    return widget.controller.loadArchive(
      machineId: _machineId,
      fromDate: _fromDateController.text,
      toDate: _toDateController.text,
      status: _status,
    );
  }
}

class _ArchiveDetailPane extends StatelessWidget {
  const _ArchiveDetailPane({
    required this.plan,
    required this.summary,
    required this.isLoading,
    required this.onOpenInReports,
  });

  final PlanDetailDto? plan;
  final PlanExecutionSummaryDto? summary;
  final bool isLoading;
  final VoidCallback? onOpenInReports;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (plan == null) {
      return const Center(
        child: Text(
          'Choose an archived plan to inspect revisions and execution.',
        ),
      );
    }
    return ListView(
      children: [
        Text(plan!.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text('Status: ${plan!.status}'),
        Text('Created: ${plan!.createdAt.toIso8601String()}'),
        const SizedBox(height: 16),
        if (summary != null) ...[
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricChip(
                label: 'Requested',
                value: summary!.totalRequested.toStringAsFixed(0),
              ),
              _MetricChip(
                label: 'Reported',
                value: summary!.totalReported.toStringAsFixed(0),
              ),
              _MetricChip(
                label: 'Closed Tasks',
                value: '${summary!.closedTaskCount}/${summary!.taskCount}',
              ),
              _MetricChip(
                label: 'Problems',
                value: summary!.problemCount.toString(),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        Text('Plan Items', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...plan!.items.map(
          (item) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(item.displayName),
            subtitle: Text(item.workshop ?? '-'),
            trailing: Text(item.requestedQuantity.toStringAsFixed(0)),
          ),
        ),
        const SizedBox(height: 12),
        Text('Revisions', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (plan!.revisions.isEmpty)
          const Text('No revisions were recorded for this archived plan.')
        else
          ...plan!.revisions.map(
            (revision) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Revision ${revision.revisionNumber}'),
              subtitle: Text(
                '${revision.changedBy} | ${revision.changedAt.toIso8601String()}',
              ),
            ),
          ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: onOpenInReports,
            icon: const Icon(Icons.open_in_new_outlined),
            label: const Text('Open In Reports'),
          ),
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 4),
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
