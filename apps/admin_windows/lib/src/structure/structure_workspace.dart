import 'package:data_models/data_models.dart';
import 'package:flutter/material.dart';

import 'structure_editor_controller.dart';

class StructureWorkspace extends StatefulWidget {
  const StructureWorkspace({
    super.key,
    required this.controller,
    required this.onPublished,
  });

  final StructureEditorController controller;
  final Future<void> Function(String machineId, String versionId) onPublished;

  @override
  State<StructureWorkspace> createState() => _StructureWorkspaceState();
}

class _StructureWorkspaceState extends State<StructureWorkspace> {
  final _occurrenceNameController = TextEditingController();
  final _occurrenceQuantityController = TextEditingController();
  final _occurrenceWorkshopController = TextEditingController();
  final _childNameController = TextEditingController();
  final _childQuantityController = TextEditingController(text: '1');
  final _childWorkshopController = TextEditingController();
  final _operationNameController = TextEditingController();
  final _operationQuantityController = TextEditingController(text: '1');
  final _operationWorkshopController = TextEditingController();

  @override
  void dispose() {
    _occurrenceNameController.dispose();
    _occurrenceQuantityController.dispose();
    _occurrenceWorkshopController.dispose();
    _childNameController.dispose();
    _childQuantityController.dispose();
    _childWorkshopController.dispose();
    _operationNameController.dispose();
    _operationQuantityController.dispose();
    _operationWorkshopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        _syncOccurrenceForm(widget.controller.selectedOccurrence);
        _syncOperationForm(widget.controller.selectedOperation);
        final detail = widget.controller.versionDetail;
        final isDraft = detail != null && !detail.isImmutable;
        return ListView(
          children: [
            _SectionCard(
              title: 'Structure Editor',
              subtitle:
                  'Create editable drafts from machine versions, maintain structure nodes, manage operation lists, and publish a new active version.',
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: widget.controller.isBusy
                        ? null
                        : widget.controller.loadMachines,
                    icon: const Icon(Icons.refresh_outlined),
                    label: Text(
                      widget.controller.isMachinesLoading
                          ? 'Refreshing...'
                          : 'Refresh Structure',
                    ),
                  ),
                  _InfoChip(
                    label: '${widget.controller.machines.length} machines',
                  ),
                  _InfoChip(
                    label: '${widget.controller.versions.length} versions',
                  ),
                  _InfoChip(
                    label:
                        '${detail?.structureOccurrences.length ?? 0} structure rows',
                  ),
                  _InfoChip(
                    label:
                        '${detail?.operationOccurrences.length ?? 0} operations',
                  ),
                ],
              ),
            ),
            if (widget.controller.errorMessage case final message?)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _Banner(
                  title: 'Structure error',
                  message: message,
                  color: const Color(0xFF991B1B),
                ),
              ),
            if (widget.controller.successMessage case final message?)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _Banner(
                  title: 'Structure updated',
                  message: message,
                  color: const Color(0xFF166534),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _SectionCard(
                title: 'Version Context',
                subtitle:
                    'Published versions stay read-only. Create an editable draft to continue editing.',
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
                        'structure-version-${widget.controller.selectedMachineId}-${widget.controller.versions.length}',
                      ),
                      initialValue: widget.controller.selectedVersionId,
                      decoration: const InputDecoration(
                        labelText: 'Version',
                        border: OutlineInputBorder(),
                      ),
                      items: widget.controller.versions
                          .map(
                            (version) => DropdownMenuItem<String>(
                              value: version.id,
                              child: Text(
                                '${version.label} (${version.status})',
                              ),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: widget.controller.selectVersion,
                    ),
                    const SizedBox(height: 16),
                    if (detail != null)
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _InfoChip(label: detail.label),
                          _InfoChip(label: detail.status),
                          _InfoChip(
                            label: detail.isActiveVersion
                                ? 'Active version'
                                : 'History version',
                          ),
                          _InfoChip(
                            label: detail.isImmutable
                                ? 'Read-only'
                                : 'Editable draft',
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.icon(
                          key: const Key('createStructureDraftButton'),
                          onPressed: widget.controller.isBusy
                              ? null
                              : widget.controller.createDraftFromCurrentVersion,
                          icon: const Icon(Icons.copy_outlined),
                          label: const Text('Create Editable Draft'),
                        ),
                        FilledButton.icon(
                          key: const Key('publishStructureVersionButton'),
                          onPressed: !isDraft || widget.controller.isBusy
                              ? null
                              : () async {
                                  final published = await widget.controller
                                      .publishCurrentVersion();
                                  if (published != null) {
                                    await widget.onPublished(
                                      published.machineId,
                                      published.id,
                                    );
                                  }
                                },
                          icon: const Icon(Icons.publish_outlined),
                          label: Text(
                            widget.controller.isSaving
                                ? 'Saving...'
                                : 'Publish Draft',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final useColumn = constraints.maxWidth < 1100;
                  final treePane = _EditorPane(
                    title: 'Structure Tree',
                    subtitle:
                        'Select a structure row to edit it, create a child node, or manage operations.',
                    child: detail == null || widget.controller.treeRoot == null
                        ? const Text('No version detail loaded yet.')
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FilledButton.icon(
                                key: const Key('addRootStructureNodeButton'),
                                onPressed: !isDraft || widget.controller.isBusy
                                    ? null
                                    : () => widget.controller
                                          .addStructureOccurrence(
                                            displayName:
                                                _childNameController.text,
                                            quantityPerMachine:
                                                _childQuantityController.text,
                                            workshop:
                                                _childWorkshopController.text,
                                          ),
                                icon: const Icon(Icons.add_outlined),
                                label: const Text('Add Root Node From Form'),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                key: const Key('structureTreePane'),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Column(
                                  children: widget.controller.treeRoot!.children
                                      .map(
                                        (node) => _TreeNodeTile(
                                          node: node,
                                          selectedOccurrenceId: widget
                                              .controller
                                              .selectedOccurrenceId,
                                          onTap: widget
                                              .controller
                                              .selectOccurrence,
                                        ),
                                      )
                                      .toList(growable: false),
                                ),
                              ),
                            ],
                          ),
                  );
                  final detailPane = _EditorPane(
                    title: 'Selected Node',
                    subtitle:
                        'Edit the selected draft node and maintain operations linked to it.',
                    child: _SelectedNodePane(
                      controller: widget.controller,
                      isDraft: isDraft,
                      occurrenceNameController: _occurrenceNameController,
                      occurrenceQuantityController:
                          _occurrenceQuantityController,
                      occurrenceWorkshopController:
                          _occurrenceWorkshopController,
                      childNameController: _childNameController,
                      childQuantityController: _childQuantityController,
                      childWorkshopController: _childWorkshopController,
                      operationNameController: _operationNameController,
                      operationQuantityController: _operationQuantityController,
                      operationWorkshopController: _operationWorkshopController,
                    ),
                  );

                  if (useColumn) {
                    return Column(
                      children: [
                        treePane,
                        const SizedBox(height: 16),
                        detailPane,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 4, child: treePane),
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

  void _syncOccurrenceForm(StructureOccurrenceDetailDto? occurrence) {
    if (occurrence == null) {
      _writeText(_occurrenceNameController, '');
      _writeText(_occurrenceQuantityController, '');
      _writeText(_occurrenceWorkshopController, '');
      return;
    }
    _writeText(_occurrenceNameController, occurrence.displayName);
    _writeText(
      _occurrenceQuantityController,
      occurrence.quantityPerMachine.toString(),
    );
    _writeText(_occurrenceWorkshopController, occurrence.workshop ?? '');
  }

  void _syncOperationForm(OperationOccurrenceDetailDto? operation) {
    if (operation == null) {
      _writeText(_operationNameController, '');
      _writeText(_operationQuantityController, '1');
      _writeText(_operationWorkshopController, '');
      return;
    }
    _writeText(_operationNameController, operation.name);
    _writeText(
      _operationQuantityController,
      operation.quantityPerMachine.toString(),
    );
    _writeText(_operationWorkshopController, operation.workshop ?? '');
  }

  void _writeText(TextEditingController controller, String value) {
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

class _SelectedNodePane extends StatelessWidget {
  const _SelectedNodePane({
    required this.controller,
    required this.isDraft,
    required this.occurrenceNameController,
    required this.occurrenceQuantityController,
    required this.occurrenceWorkshopController,
    required this.childNameController,
    required this.childQuantityController,
    required this.childWorkshopController,
    required this.operationNameController,
    required this.operationQuantityController,
    required this.operationWorkshopController,
  });

  final StructureEditorController controller;
  final bool isDraft;
  final TextEditingController occurrenceNameController;
  final TextEditingController occurrenceQuantityController;
  final TextEditingController occurrenceWorkshopController;
  final TextEditingController childNameController;
  final TextEditingController childQuantityController;
  final TextEditingController childWorkshopController;
  final TextEditingController operationNameController;
  final TextEditingController operationQuantityController;
  final TextEditingController operationWorkshopController;

  @override
  Widget build(BuildContext context) {
    if (controller.versionDetail == null) {
      return const Text('Select a version to start.');
    }
    if (controller.selectedOccurrence == null) {
      return const Text('Select a structure node in the tree.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: const Key('structureOccurrenceNameField'),
          controller: occurrenceNameController,
          enabled: isDraft,
          decoration: const InputDecoration(
            labelText: 'Display name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('structureOccurrenceQuantityField'),
          controller: occurrenceQuantityController,
          enabled: isDraft,
          decoration: const InputDecoration(
            labelText: 'Quantity per machine',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('structureOccurrenceWorkshopField'),
          controller: occurrenceWorkshopController,
          enabled: isDraft,
          decoration: const InputDecoration(
            labelText: 'Workshop',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              key: const Key('saveStructureOccurrenceButton'),
              onPressed: !isDraft || controller.isBusy
                  ? null
                  : () => controller.updateSelectedOccurrence(
                      displayName: occurrenceNameController.text,
                      quantityPerMachine: occurrenceQuantityController.text,
                      workshop: occurrenceWorkshopController.text,
                    ),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Node'),
            ),
            OutlinedButton.icon(
              key: const Key('deleteStructureOccurrenceButton'),
              onPressed: !isDraft || controller.isBusy
                  ? null
                  : controller.deleteSelectedOccurrence,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete Node'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Add Child Node',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('newChildStructureNameField'),
          controller: childNameController,
          enabled: isDraft,
          decoration: const InputDecoration(
            labelText: 'Child display name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('newChildStructureQuantityField'),
          controller: childQuantityController,
          enabled: isDraft,
          decoration: const InputDecoration(
            labelText: 'Child quantity',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('newChildStructureWorkshopField'),
          controller: childWorkshopController,
          enabled: isDraft,
          decoration: const InputDecoration(
            labelText: 'Child workshop',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const Key('addChildStructureNodeButton'),
          onPressed: !isDraft || controller.isBusy
              ? null
              : () => controller.addStructureOccurrence(
                  displayName: childNameController.text,
                  quantityPerMachine: childQuantityController.text,
                  workshop: childWorkshopController.text,
                  parentOccurrenceId: controller.selectedOccurrenceId,
                ),
          icon: const Icon(Icons.subdirectory_arrow_right),
          label: const Text('Add Child Node'),
        ),
        const SizedBox(height: 20),
        Text(
          'Operations',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (controller.selectedOccurrenceOperations.isEmpty)
          const Text('No operations linked to this node yet.')
        else
          Column(
            children: controller.selectedOccurrenceOperations
                .map(
                  (operation) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _OperationTile(
                      operation: operation,
                      selected: controller.selectedOperationId == operation.id,
                      onTap: () => controller.selectOperation(operation.id),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('structureOperationNameField'),
          controller: operationNameController,
          enabled: isDraft,
          decoration: const InputDecoration(
            labelText: 'Operation name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('structureOperationQuantityField'),
          controller: operationQuantityController,
          enabled: isDraft,
          decoration: const InputDecoration(
            labelText: 'Operation quantity',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('structureOperationWorkshopField'),
          controller: operationWorkshopController,
          enabled: isDraft,
          decoration: const InputDecoration(
            labelText: 'Operation workshop',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              key: const Key('saveStructureOperationButton'),
              onPressed: !isDraft || controller.isBusy
                  ? null
                  : controller.selectedOperation == null
                  ? () => controller.addOperation(
                      name: operationNameController.text,
                      quantityPerMachine: operationQuantityController.text,
                      workshop: operationWorkshopController.text,
                    )
                  : () => controller.updateSelectedOperation(
                      name: operationNameController.text,
                      quantityPerMachine: operationQuantityController.text,
                      workshop: operationWorkshopController.text,
                    ),
              icon: const Icon(Icons.build_outlined),
              label: Text(
                controller.selectedOperation == null
                    ? 'Add Operation'
                    : 'Save Operation',
              ),
            ),
            OutlinedButton.icon(
              key: const Key('deleteStructureOperationButton'),
              onPressed:
                  !isDraft ||
                      controller.isBusy ||
                      controller.selectedOperation == null
                  ? null
                  : controller.deleteSelectedOperation,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete Operation'),
            ),
          ],
        ),
      ],
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

class _EditorPane extends StatelessWidget {
  const _EditorPane({
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

class _TreeNodeTile extends StatelessWidget {
  const _TreeNodeTile({
    required this.node,
    required this.selectedOccurrenceId,
    required this.onTap,
  });

  final StructureTreeNode node;
  final String? selectedOccurrenceId;
  final ValueChanged<String?> onTap;

  @override
  Widget build(BuildContext context) {
    final occurrence = node.occurrence!;
    final isSelected = occurrence.id == selectedOccurrenceId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: node.depth * 18.0, bottom: 8),
          child: InkWell(
            key: ValueKey('structureNode-${occurrence.id}'),
            onTap: () => onTap(occurrence.id),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFDBEAFE)
                    : const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    occurrence.displayName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${occurrence.pathKey}\nQty/machine: ${occurrence.quantityPerMachine} | Workshop: ${occurrence.workshop ?? '-'}',
                  ),
                ],
              ),
            ),
          ),
        ),
        ...node.children.map(
          (child) => _TreeNodeTile(
            node: child,
            selectedOccurrenceId: selectedOccurrenceId,
            onTap: onTap,
          ),
        ),
      ],
    );
  }
}

class _OperationTile extends StatelessWidget {
  const _OperationTile({
    required this.operation,
    required this.selected,
    required this.onTap,
  });

  final OperationOccurrenceDetailDto operation;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFECFCCB) : const Color(0xFFFFFFFF),
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
                operation.name,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Qty/machine: ${operation.quantityPerMachine} | Workshop: ${operation.workshop ?? '-'}',
              ),
            ],
          ),
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
