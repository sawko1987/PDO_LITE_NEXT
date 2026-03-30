import 'package:flutter/material.dart';

import 'plan_board_controller.dart';

class PlanWorkspace extends StatefulWidget {
  const PlanWorkspace({super.key, required this.controller});

  final PlanBoardController controller;

  @override
  State<PlanWorkspace> createState() => _PlanWorkspaceState();
}

class _PlanWorkspaceState extends State<PlanWorkspace> {
  late final TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.controller.planTitle)
      ..addListener(() {
        if (widget.controller.planTitle != _titleController.text) {
          widget.controller.setPlanTitle(_titleController.text);
        }
      });
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        if (_titleController.text != widget.controller.planTitle) {
          _titleController.value = TextEditingValue(
            text: widget.controller.planTitle,
            selection: TextSelection.collapsed(
              offset: widget.controller.planTitle.length,
            ),
          );
        }
        final activePlan = widget.controller.activePlan;
        return ListView(
          children: [
            _PlanSectionCard(
              title: 'Plan Board',
              subtitle:
                  'Create draft plans from structure occurrences, inspect plan details, and release tasks by operation.',
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: widget.controller.isBusy
                        ? null
                        : widget.controller.loadPlans,
                    icon: const Icon(Icons.refresh_outlined),
                    label: Text(
                      widget.controller.isPlansLoading
                          ? 'Refreshing...'
                          : 'Refresh Plans',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: widget.controller.isBusy
                        ? null
                        : widget.controller.loadMachines,
                    icon: const Icon(Icons.precision_manufacturing_outlined),
                    label: Text(
                      widget.controller.isMachinesLoading
                          ? 'Loading Machines...'
                          : 'Refresh Machines',
                    ),
                  ),
                  _InfoChip(
                    label: '${widget.controller.plans.length} plans loaded',
                  ),
                  _InfoChip(
                    label:
                        '${widget.controller.planningSource.length} source occurrences',
                  ),
                ],
              ),
            ),
            if (widget.controller.errorMessage case final message?)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _Banner(
                  title: 'Planning error',
                  message: message,
                  color: const Color(0xFF991B1B),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _PlanSectionCard(
                title: 'Draft Builder',
                subtitle:
                    'Choose machine and version, then assemble a draft plan from planning source occurrences.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: widget.controller.selectedMachineId,
                      decoration: const InputDecoration(
                        labelText: 'Machine',
                        border: OutlineInputBorder(),
                      ),
                      items: widget.controller.machines
                          .map(
                            (machine) => DropdownMenuItem<String>(
                              value: machine.id,
                              child: Text('${machine.code} - ${machine.name}'),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: widget.controller.selectMachine,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      key: ValueKey(
                        'version-${widget.controller.selectedMachineId}-${widget.controller.versions.length}',
                      ),
                      initialValue: widget.controller.selectedVersionId,
                      decoration: const InputDecoration(
                        labelText: 'Machine version',
                        border: OutlineInputBorder(),
                      ),
                      items: widget.controller.versions
                          .map(
                            (version) => DropdownMenuItem<String>(
                              value: version.id,
                              child: Text('${version.label} (${version.status})'),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: widget.controller.selectVersion,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Plan title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: widget.controller.canCreatePlan
                          ? widget.controller.createPlan
                          : null,
                      icon: const Icon(Icons.playlist_add_check_outlined),
                      label: Text(
                        widget.controller.isSavingPlan
                            ? 'Creating Draft...'
                            : 'Create Draft Plan',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _PlanSectionCard(
                title: 'Planning Source',
                subtitle:
                    'Every row is a concrete structure occurrence of the selected machine version.',
                child: widget.controller.planningSource.isEmpty
                    ? const Text('No planning source loaded yet.')
                    : Column(
                        children: widget.controller.planningSource
                            .map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _SourceTile(
                                  title: item.displayName,
                                  subtitle:
                                      '${item.pathKey}\nQty/machine: ${item.quantityPerMachine} | Operations: ${item.operationCount}',
                                  selected: widget.controller.isSelectedOccurrence(
                                    item.id,
                                  ),
                                  onAdd: () =>
                                      widget.controller.addOccurrenceToDraft(item),
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _PlanSectionCard(
                title: 'Draft Selections',
                subtitle:
                    'Adjust requested quantity per occurrence before creating the draft plan.',
                child: widget.controller.draftSelections.isEmpty
                    ? const Text('No occurrences added to the draft yet.')
                    : Column(
                        children: widget.controller.draftSelections
                            .map(
                              (selection) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _DraftItemTile(
                                  selection: selection,
                                  onRemove: () => widget.controller
                                      .removeOccurrenceFromDraft(
                                        selection.occurrence.id,
                                      ),
                                  onQuantityChanged: (value) => widget.controller
                                      .updateRequestedQuantity(
                                        selection.occurrence.id,
                                        value,
                                      ),
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
              ),
            ),
            if (activePlan != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _PlanSectionCard(
                  title: 'Active Plan',
                  subtitle:
                      'Current plan detail loaded from backend, including source occurrence context.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _InfoChip(label: 'Plan ${activePlan.id}'),
                          _InfoChip(label: 'Status ${activePlan.status}'),
                          _InfoChip(label: 'Items ${activePlan.itemCount}'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: widget.controller.canReleaseActivePlan
                            ? widget.controller.releaseActivePlan
                            : null,
                        icon: const Icon(Icons.rocket_launch_outlined),
                        label: Text(
                          widget.controller.isReleasingPlan
                              ? 'Releasing...'
                              : 'Release Plan',
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...activePlan.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _DetailTile(
                            title: item.displayName,
                            lines: [
                              'Path: ${item.pathKey}',
                              'Requested: ${item.requestedQuantity}',
                              'Recorded execution: ${item.hasRecordedExecution ? 'yes' : 'no'}',
                              'Can edit: ${item.canEdit ? 'yes' : 'no'}',
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (widget.controller.releaseResult case final release?)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _Banner(
                  title: 'Plan released',
                  message:
                      'Plan ${release.planId} moved to ${release.status} and generated ${release.generatedTaskCount} task(s).',
                  color: const Color(0xFF14532D),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _PlanSectionCard(
                title: 'Plan Index',
                subtitle:
                    'All plans currently available from backend. Open any plan to inspect details.',
                child: widget.controller.plans.isEmpty
                    ? const Text('No plans available.')
                    : Column(
                        children: widget.controller.plans
                            .map(
                              (plan) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _SourceTile(
                                  title: plan.title,
                                  subtitle:
                                      'Status: ${plan.status}\nItems: ${plan.itemCount} | Revisions: ${plan.revisionCount}',
                                  selected: activePlan?.id == plan.id,
                                  actionLabel: 'Open',
                                  onAdd: () => widget.controller.openPlan(plan.id),
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PlanSectionCard extends StatelessWidget {
  const _PlanSectionCard({
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

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onAdd,
    this.actionLabel = 'Add',
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onAdd;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFECFCCB) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? const Color(0xFF65A30D) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
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
                Text(subtitle),
              ],
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton(
            onPressed: selected ? null : onAdd,
            child: Text(selected ? 'Selected' : actionLabel),
          ),
        ],
      ),
    );
  }
}

class _DraftItemTile extends StatelessWidget {
  const _DraftItemTile({
    required this.selection,
    required this.onRemove,
    required this.onQuantityChanged,
  });

  final DraftPlanSelection selection;
  final VoidCallback onRemove;
  final ValueChanged<String> onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selection.occurrence.displayName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(selection.occurrence.pathKey),
              ],
            ),
          ),
          SizedBox(
            width: 110,
            child: TextFormField(
              key: ValueKey(
                '${selection.occurrence.id}-${selection.requestedQuantity}',
              ),
              initialValue: selection.requestedQuantity.toString(),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Qty',
                border: OutlineInputBorder(),
              ),
              onChanged: onQuantityChanged,
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
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
