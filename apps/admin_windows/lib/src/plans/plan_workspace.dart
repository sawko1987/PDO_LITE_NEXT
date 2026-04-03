import 'package:data_models/data_models.dart';
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
  late final TextEditingController _bulkQuantityController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.controller.planTitle)
      ..addListener(() {
        if (widget.controller.planTitle != _titleController.text) {
          widget.controller.setPlanTitle(_titleController.text);
        }
      });
    _bulkQuantityController =
        TextEditingController(
          text: widget.controller.bulkAddQuantity,
        )..addListener(() {
          if (widget.controller.bulkAddQuantity !=
              _bulkQuantityController.text) {
            widget.controller.setBulkAddQuantity(_bulkQuantityController.text);
          }
        });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bulkQuantityController.dispose();
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
        if (_bulkQuantityController.text != widget.controller.bulkAddQuantity) {
          _bulkQuantityController.value = TextEditingValue(
            text: widget.controller.bulkAddQuantity,
            selection: TextSelection.collapsed(
              offset: widget.controller.bulkAddQuantity.length,
            ),
          );
        }
        final activePlan = widget.controller.activePlan;
        final bulkAddPreview = widget.controller.bulkAddPreview;
        return ListView(
          children: [
            _PlanSectionCard(
              title: 'Планирование',
              subtitle:
                  'Создание черновиков планов, просмотр деталей и запуск задач по операциям.',
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
                          ? 'Обновление...'
                          : 'Обновить планы',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: widget.controller.isBusy
                        ? null
                        : widget.controller.loadMachines,
                    icon: const Icon(Icons.precision_manufacturing_outlined),
                    label: Text(
                      widget.controller.isMachinesLoading
                          ? 'Загрузка оборудования...'
                          : 'Обновить оборудование',
                    ),
                  ),
                  _InfoChip(
                    label: '${widget.controller.plans.length} plans loaded',
                  ),
                  _InfoChip(
                    label:
                        '${widget.controller.planningSource.length} source occurrences',
                  ),
                  _InfoChip(
                    label:
                        '${widget.controller.visibleWipEntries.length} WIP entries in scope',
                  ),
                ],
              ),
            ),
            if (widget.controller.errorMessage case final message?)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _Banner(
                  title: 'Ошибка планирования',
                  message: message,
                  color: const Color(0xFF991B1B),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _PlanSectionCard(
                title: 'Конструктор плана',
                subtitle:
                    'Выберите оборудование и версию, затем соберите черновик плана из дерева оборудования.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: widget.controller.selectedMachineId,
                      decoration: const InputDecoration(
                        labelText: 'Оборудование',
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
                        labelText: 'Версия оборудования',
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
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Название плана',
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
                            ? 'Создание...'
                            : 'Создать черновик плана',
                      ),
                    ),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final useColumn = constraints.maxWidth < 1040;
                        final treePane = Expanded(
                          child: _TreeSelectionPane(
                            controller: widget.controller,
                            bulkQuantityController: _bulkQuantityController,
                            preview: bulkAddPreview,
                          ),
                        );
                        final draftPane = Expanded(
                          child: _DraftSelectionsPane(
                            controller: widget.controller,
                          ),
                        );

                        if (useColumn) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _TreeSelectionPane(
                                controller: widget.controller,
                                bulkQuantityController: _bulkQuantityController,
                                preview: bulkAddPreview,
                              ),
                              const SizedBox(height: 16),
                              _DraftSelectionsPane(
                                controller: widget.controller,
                              ),
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            treePane,
                            const SizedBox(width: 16),
                            draftPane,
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _PlanSectionCard(
                title: 'Монитор НЗП',
                subtitle:
                    'Текущие записи НЗП для выбранного оборудования/версии или активного плана.',
                child: widget.controller.visibleWipEntries.isEmpty
                    ? const Text('Записей НЗП в текущей области нет.')
                    : Column(
                        children: widget.controller.visibleWipEntries
                            .map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _DetailTile(
                                  title: entry.id,
                                  lines: [
                                    'Operation: ${entry.operationOccurrenceId}',
                                    'Balance: ${entry.balanceQuantity}',
                                    'Status: ${entry.status}',
                                    'Task: ${entry.taskId ?? '-'}',
                                    'Outcome: ${entry.sourceOutcome ?? '-'}',
                                  ],
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
                  title: 'Активный план',
                  subtitle:
                      'Детали текущего плана, включая контекст вхождений источника.',
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
                              ? 'Запуск...'
                              : 'Запустить план',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          OutlinedButton.icon(
                            onPressed:
                                widget.controller.canCheckActivePlanCompletion
                                ? widget.controller.checkActivePlanCompletion
                                : null,
                            icon: const Icon(Icons.rule_folder_outlined),
                            label: Text(
                              widget.controller.isCheckingCompletion
                                  ? 'Проверка...'
                                  : 'Проверить завершение',
                            ),
                          ),
                          FilledButton.icon(
                            onPressed:
                                widget.controller.canConfirmActivePlanCompletion
                                ? widget.controller.completeActivePlan
                                : null,
                            icon: const Icon(Icons.verified_outlined),
                            label: Text(
                              widget.controller.isCompletingPlan
                                  ? 'Подтверждение...'
                                  : 'Подтвердить завершение',
                            ),
                          ),
                        ],
                      ),
                      if (widget.controller.completionDecision != null) ...[
                        const SizedBox(height: 16),
                        _CompletionDecisionCard(
                          decision: widget.controller.completionDecision!,
                        ),
                      ],
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
                  title: 'План запущен',
                  message:
                      'План ${release.planId} переведён в ${release.status} и создал ${release.generatedTaskCount} задач.',
                  color: const Color(0xFF14532D),
                ),
              ),
            if (widget.controller.completionResult case final completion?)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _Banner(
                  title: 'План завершён',
                  message:
                      'План ${completion.planId} переведён в ${completion.status}. Завершение подтверждено диспетчером.',
                  color: const Color(0xFF14532D),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _PlanSectionCard(
                title: 'Реестр планов',
                subtitle:
                    'Все планы, доступные на сервере. Откройте план для просмотра деталей.',
                child: widget.controller.plans.isEmpty
                    ? const Text('Планов нет.')
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
                                  actionLabel: 'Открыть',
                                  onAdd: () =>
                                      widget.controller.openPlan(plan.id),
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

class _DraftSelectionsPane extends StatelessWidget {
  const _DraftSelectionsPane({required this.controller});

  final PlanBoardController controller;

  @override
  Widget build(BuildContext context) {
    return _PaneSurface(
      title: 'Выбранные вхождения',
      subtitle:
          'Сервер получает плоский список вхождений. Вы можете настроить количество для каждой строки.',
      child: controller.draftSelections.isEmpty
          ? const Text('Вхождения ещё не добавлены в черновик.')
          : Column(
              children: controller.draftSelections
                  .map(
                    (selection) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _DraftItemTile(
                        selection: selection,
                        onRemove: () => controller.removeOccurrenceFromDraft(
                          selection.occurrence.id,
                        ),
                        onQuantityChanged: (value) =>
                            controller.updateRequestedQuantity(
                              selection.occurrence.id,
                              value,
                            ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }
}

class _TreeSelectionPane extends StatelessWidget {
  const _TreeSelectionPane({
    required this.controller,
    required this.bulkQuantityController,
    required this.preview,
  });

  final PlanBoardController controller;
  final TextEditingController bulkQuantityController;
  final BulkAddPreview? preview;

  @override
  Widget build(BuildContext context) {
    final bulkAddResult = controller.lastBulkDraftAddResult;
    return _PaneSurface(
      title: 'Дерево структуры',
      subtitle:
          'Выберите оборудование целиком, ветку, место или отдельную деталь и добавьте все дочерние вхождения.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.planningTreeRoot == null)
            const Text('Источник планирования ещё не загружен.')
          else ...[
            Container(
              key: const Key('planningTreePane'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PlanningNodeTile(
                    node: controller.planningTreeRoot!,
                    selectedNodeId: controller.selectedPlanningNodeId,
                    onSelect: controller.selectPlanningNode,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('bulkPlanningQuantityField'),
              controller: bulkQuantityController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Количество для новых строк',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (preview != null)
              Container(
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
                      'Выбранная ветка: ${preview!.selectedNodeLabel}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Вхождений в ветке: ${preview!.totalOccurrenceCount}',
                      key: const Key('bulkPreviewTotalCount'),
                    ),
                    Text(
                      'Будет добавлено строк: ${preview!.newOccurrenceCount}',
                      key: const Key('bulkPreviewNewCount'),
                    ),
                    Text(
                      'Пропущено как дубликаты: ${preview!.skippedOccurrenceCount}',
                      key: const Key('bulkPreviewSkippedCount'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('addPlanningSelectionButton'),
              onPressed: controller.canBulkAddSelectedNode
                  ? controller.addSelectedPlanningNodeToDraft
                  : null,
              icon: const Icon(Icons.account_tree_outlined),
              label: const Text('Добавить в черновик'),
            ),
          ],
          if (bulkAddResult != null) ...[
            const SizedBox(height: 16),
            _Banner(
              title: 'Выбранные вхождения добавлены в черновик',
              message:
                  '${bulkAddResult.selectedNodeLabel}: ${bulkAddResult.addedOccurrenceCount} добавлено, ${bulkAddResult.skippedOccurrenceCount} пропущено как дубликаты, количество ${bulkAddResult.requestedQuantity}.',
              color: const Color(0xFF14532D),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanningNodeTile extends StatelessWidget {
  const _PlanningNodeTile({
    required this.node,
    required this.selectedNodeId,
    required this.onSelect,
  });

  final PlanningTreeNode node;
  final String? selectedNodeId;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final isSelected = node.id == selectedNodeId;
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
          child: InkWell(
            key: ValueKey('planningNode-${node.id}'),
            onTap: () => onSelect(node.id),
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      node.isLeaf
                          ? Icons.precision_manufacturing_outlined
                          : Icons.folder_open_outlined,
                      color: isSelected
                          ? const Color(0xFF1D4ED8)
                          : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          node.label,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(subtitle),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _InfoChip(
                    label: '${node.descendantOccurrenceIds.length} occ',
                  ),
                ],
              ),
            ),
          ),
        ),
        ...node.children.map(
          (child) => _PlanningNodeTile(
            node: child,
            selectedNodeId: selectedNodeId,
            onSelect: onSelect,
          ),
        ),
      ],
    );
  }
}

class _CompletionDecisionCard extends StatelessWidget {
  const _CompletionDecisionCard({required this.decision});

  final PlanCompletionDecisionDto decision;

  @override
  Widget build(BuildContext context) {
    if (decision.canComplete) {
      return const _Banner(
        title: 'Проверка завершения пройдена',
        message: 'Нет открытых задач, проблем или НЗП, блокирующих этот план.',
        color: Color(0xFF14532D),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF59E0B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Блокировщики завершения',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF92400E),
            ),
          ),
          const SizedBox(height: 8),
          ...decision.blockers.map(
            (blocker) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${_formatBlockerType(blocker.type)}: ${blocker.entityIds.join(', ')}',
              ),
            ),
          ),
        ],
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
            child: Text(selected ? 'Выбрано' : actionLabel),
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
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Кол-во',
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

String _formatBlockerType(String value) {
  return switch (value) {
    'openTasks' => 'Открытые задачи',
    'openProblems' => 'Открытые проблемы',
    'openWip' => 'Открытые НЗП',
    _ => value,
  };
}
