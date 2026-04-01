import 'package:data_models/data_models.dart';
import 'package:flutter/material.dart';

import 'machines_registry_controller.dart';

class MachinesWorkspace extends StatelessWidget {
  const MachinesWorkspace({
    super.key,
    required this.controller,
    required this.onOpenInPlans,
    required this.onCreateNewVersionInImport,
  });

  final MachinesRegistryController controller;
  final Future<void> Function(String machineId, String versionId) onOpenInPlans;
  final Future<void> Function(String machineId) onCreateNewVersionInImport;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final selectedMachine = controller.selectedMachine;
        final selectedVersion = controller.selectedVersion;
        return ListView(
          children: [
            _MachinesSectionCard(
              title: 'Machines Registry',
              subtitle:
                  'Read-only registry for machines, version history, and version structure preview.',
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: controller.isBusy
                        ? null
                        : controller.loadMachines,
                    icon: const Icon(Icons.sync_outlined),
                    label: Text(
                      controller.isMachinesLoading
                          ? 'Refreshing...'
                          : 'Refresh Registry',
                    ),
                  ),
                  _InfoChip(label: '${controller.machines.length} machines'),
                  _InfoChip(label: '${controller.versions.length} versions'),
                  _InfoChip(
                    label:
                        '${controller.selectedVersionOccurrenceCount} structure rows',
                  ),
                  _InfoChip(
                    label:
                        '${controller.selectedVersionOperationCount} operations',
                  ),
                ],
              ),
            ),
            if (controller.errorMessage case final message?)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _Banner(
                  title: 'Registry error',
                  message: message,
                  color: const Color(0xFF991B1B),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final useColumn = constraints.maxWidth < 1080;
                  final machinePane = _MachinesSectionCard(
                    title: 'Machines',
                    subtitle:
                        'Select a machine to inspect version history and structure.',
                    child: _MachineListPane(controller: controller),
                  );
                  final detailPane = _MachinesSectionCard(
                    title: 'Machine Detail',
                    subtitle:
                        'Version history, active version marker, and structure preview for the selected machine.',
                    child: selectedMachine == null
                        ? const Text('No machine selected.')
                        : _MachineDetailPane(
                            controller: controller,
                            selectedMachine: selectedMachine,
                            selectedVersion: selectedVersion,
                            onOpenInPlans: onOpenInPlans,
                            onCreateNewVersionInImport:
                                onCreateNewVersionInImport,
                          ),
                  );

                  if (useColumn) {
                    return Column(
                      children: [
                        machinePane,
                        const SizedBox(height: 16),
                        detailPane,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 4, child: machinePane),
                      const SizedBox(width: 16),
                      Expanded(flex: 7, child: detailPane),
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

class _MachineListPane extends StatelessWidget {
  const _MachineListPane({required this.controller});

  final MachinesRegistryController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.machines.isEmpty) {
      return const Text('No machines available yet.');
    }

    return Column(
      key: const Key('machinesListPane'),
      children: controller.machines
          .map(
            (machine) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MachineTile(
                machine: machine,
                selected: machine.id == controller.selectedMachineId,
                onSelect: () => controller.selectMachine(machine.id),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _MachineDetailPane extends StatelessWidget {
  const _MachineDetailPane({
    required this.controller,
    required this.selectedMachine,
    required this.selectedVersion,
    required this.onOpenInPlans,
    required this.onCreateNewVersionInImport,
  });

  final MachinesRegistryController controller;
  final MachineSummaryDto selectedMachine;
  final MachineVersionSummaryDto? selectedVersion;
  final Future<void> Function(String machineId, String versionId) onOpenInPlans;
  final Future<void> Function(String machineId) onCreateNewVersionInImport;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _InfoChip(label: selectedMachine.code),
            _InfoChip(label: selectedMachine.name),
            _InfoChip(
              label: 'Active: ${selectedMachine.activeVersionId ?? '-'}',
            ),
            _InfoChip(
              label: '${controller.selectedMachineVersionCount} version(s)',
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              key: const Key('openInPlansButton'),
              onPressed: selectedVersion == null
                  ? null
                  : () =>
                        onOpenInPlans(selectedMachine.id, selectedVersion!.id),
              icon: const Icon(Icons.playlist_add_check_outlined),
              label: const Text('Open In Plans'),
            ),
            OutlinedButton.icon(
              key: const Key('createNewVersionInImportButton'),
              onPressed: () => onCreateNewVersionInImport(selectedMachine.id),
              icon: const Icon(Icons.layers_outlined),
              label: const Text('Create New Version In Import'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _PaneSurface(
          title: 'Version History',
          subtitle:
              'Labels are shown as imported. Active version is marked directly in the list.',
          child: controller.versions.isEmpty
              ? const Text('No versions available for this machine.')
              : Column(
                  key: const Key('machineVersionsPane'),
                  children: controller.versions
                      .map(
                        (version) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _VersionTile(
                            version: version,
                            selected:
                                version.id == controller.selectedVersionId,
                            isActive:
                                selectedMachine.activeVersionId == version.id,
                            onSelect: () =>
                                controller.selectVersion(version.id),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
        ),
        const SizedBox(height: 16),
        _PaneSurface(
          title: 'Version Summary',
          subtitle:
              'Read-only aggregates for the selected version and structure preview below.',
          child: selectedVersion == null
              ? const Text('Select a version to see summary.')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _InfoChip(label: 'Label ${selectedVersion!.label}'),
                        _InfoChip(label: 'Status ${selectedVersion!.status}'),
                        _InfoChip(
                          label:
                              'Created ${selectedVersion!.createdAt.toIso8601String().split('T').first}',
                        ),
                        _InfoChip(
                          label:
                              '${controller.selectedVersionOccurrenceCount} structure rows',
                        ),
                        _InfoChip(
                          label:
                              '${controller.selectedVersionOperationCount} operations',
                        ),
                        _InfoChip(
                          label: controller.selectedVersionIsActive
                              ? 'Active version'
                              : 'History version',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (controller.planningTreeRoot == null)
                      const Text(
                        'No planning source available for this version.',
                      )
                    else
                      Container(
                        key: const Key('machineStructureTreePane'),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: _StructureNodeTile(
                          node: controller.planningTreeRoot!,
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _StructureNodeTile extends StatelessWidget {
  const _StructureNodeTile({required this.node});

  final MachineVersionTreeNode node;

  @override
  Widget build(BuildContext context) {
    final subtitle = node.isLeaf
        ? '${node.pathKey}\nQty/machine: ${node.occurrence!.quantityPerMachine} | Operations: ${node.occurrence!.operationCount}'
        : node.pathKey.isEmpty
        ? '${node.descendantOccurrenceIds.length} occurrence(s) in this machine'
        : '${node.descendantOccurrenceIds.length} occurrence(s) in ${node.pathKey}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: node.depth * 18.0, bottom: 8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    node.isLeaf
                        ? Icons.precision_manufacturing_outlined
                        : Icons.folder_open_outlined,
                    color: const Color(0xFF475569),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        node.label,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(subtitle),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _InfoChip(label: '${node.descendantOccurrenceIds.length} occ'),
              ],
            ),
          ),
        ),
        ...node.children.map((child) => _StructureNodeTile(node: child)),
      ],
    );
  }
}

class _MachineTile extends StatelessWidget {
  const _MachineTile({
    required this.machine,
    required this.selected,
    required this.onSelect,
  });

  final MachineSummaryDto machine;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFDBEAFE) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
        ),
      ),
      child: InkWell(
        key: ValueKey('machineTile-${machine.id}'),
        onTap: onSelect,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${machine.code} - ${machine.name}',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text('Active version: ${machine.activeVersionId ?? '-'}'),
          ],
        ),
      ),
    );
  }
}

class _VersionTile extends StatelessWidget {
  const _VersionTile({
    required this.version,
    required this.selected,
    required this.isActive,
    required this.onSelect,
  });

  final MachineVersionSummaryDto version;
  final bool selected;
  final bool isActive;
  final VoidCallback onSelect;

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
      child: InkWell(
        key: ValueKey('versionTile-${version.id}'),
        onTap: onSelect,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    version.label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (isActive) const _InfoChip(label: 'Active'),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Status: ${version.status}\nCreated: ${version.createdAt.toIso8601String().split('T').first}',
            ),
          ],
        ),
      ),
    );
  }
}

class _MachinesSectionCard extends StatelessWidget {
  const _MachinesSectionCard({
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

class _PaneSurface extends StatelessWidget {
  const _PaneSurface({
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
