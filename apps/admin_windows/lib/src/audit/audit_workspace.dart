import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import 'audit_board_controller.dart';

class AuditWorkspace extends StatefulWidget {
  const AuditWorkspace({super.key, required this.controller});

  final AuditBoardController controller;

  @override
  State<AuditWorkspace> createState() => _AuditWorkspaceState();
}

class _AuditWorkspaceState extends State<AuditWorkspace> {
  late final TextEditingController _entityIdController;
  late final TextEditingController _fromDateController;
  late final TextEditingController _toDateController;
  String? _entityType;
  String? _action;
  String? _changedBy;

  @override
  void initState() {
    super.initState();
    _entityType = widget.controller.entityType;
    _action = widget.controller.action;
    _changedBy = widget.controller.changedBy;
    _entityIdController = TextEditingController(
      text: widget.controller.entityId ?? '',
    );
    _fromDateController = TextEditingController(
      text: widget.controller.fromDate ?? '',
    );
    _toDateController = TextEditingController(
      text: widget.controller.toDate ?? '',
    );
  }

  @override
  void dispose() {
    _entityIdController.dispose();
    _fromDateController.dispose();
    _toDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return ListView(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _dropdown(
                      label: 'Тип сущности',
                      value: _entityType,
                      options: const [
                        'план',
                        'задача',
                        'проблема',
                        'нзп',
                        'пользователь',
                        'резервная копия',
                      ],
                      onChanged: (value) {
                        setState(() => _entityType = value);
                        widget.controller.setEntityType(value);
                      },
                    ),
                    _dropdown(
                      label: 'Действие',
                      value: _action,
                      options: const [
                        'создано',
                        'обновлено',
                        'закрыто',
                        'архивировано',
                        'опубликовано',
                      ],
                      onChanged: (value) {
                        setState(() => _action = value);
                        widget.controller.setAction(value);
                      },
                    ),
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<String>(
                        initialValue: _changedBy,
                        decoration: const InputDecoration(
                          labelText: 'Автор изменений',
                          border: OutlineInputBorder(),
                        ),
                        items: widget.controller.users
                            .map(
                              (user) => DropdownMenuItem<String>(
                                value: user.id,
                                child: Text(user.displayName),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          setState(() => _changedBy = value);
                          widget.controller.setChangedBy(value);
                        },
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _entityIdController,
                        decoration: const InputDecoration(
                          labelText: 'Идентификатор сущности',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: widget.controller.setEntityId,
                      ),
                    ),
                    SizedBox(
                      width: 170,
                      child: TextField(
                        controller: _fromDateController,
                        decoration: const InputDecoration(
                          labelText: 'С',
                          hintText: 'ГГГГ-ММ-ДД',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 170,
                      child: TextField(
                        controller: _toDateController,
                        decoration: const InputDecoration(
                          labelText: 'По',
                          hintText: 'ГГГГ-ММ-ДД',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: widget.controller.isLoading
                          ? null
                          : _loadAudit,
                      icon: const Icon(Icons.search_outlined),
                      label: Text(
                        widget.controller.isLoading
                            ? 'Загрузка...'
                            : 'Применить фильтры',
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: widget.controller.entries.isEmpty
                          ? null
                          : _exportCsv,
                      icon: const Icon(Icons.download_outlined),
                      label: const Text('Экспорт CSV'),
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Записи аудита',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Загружено ${widget.controller.entries.length} из ${widget.controller.total ?? widget.controller.entries.length}.',
                    ),
                    const SizedBox(height: 16),
                    if (widget.controller.entries.isEmpty)
                      const Text('Записи аудита ещё не загружены.')
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Время')),
                            DataColumn(label: Text('Автор')),
                            DataColumn(label: Text('Сущность')),
                            DataColumn(label: Text('Действие')),
                            DataColumn(label: Text('Поле')),
                            DataColumn(label: Text('Было')),
                            DataColumn(label: Text('Стало')),
                          ],
                          rows: widget.controller.entries
                              .map(
                                (entry) => DataRow(
                                  cells: [
                                    DataCell(
                                      Text(entry.changedAt.toIso8601String()),
                                    ),
                                    DataCell(Text(entry.changedBy)),
                                    DataCell(
                                      Text(
                                        '${entry.entityType}:${entry.entityId}',
                                      ),
                                    ),
                                    DataCell(Text(entry.action)),
                                    DataCell(Text(entry.field ?? '-')),
                                    DataCell(Text(entry.beforeValue ?? '-')),
                                    DataCell(Text(entry.afterValue ?? '-')),
                                  ],
                                ),
                              )
                              .toList(growable: false),
                        ),
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

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      width: 180,
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

  Future<void> _loadAudit() {
    return widget.controller.loadAudit(
      entityType: _entityType,
      entityId: _entityIdController.text,
      action: _action,
      changedBy: _changedBy,
      fromDate: _fromDateController.text,
      toDate: _toDateController.text,
    );
  }

  Future<void> _exportCsv() async {
    final location = await getSaveLocation(
      suggestedName: 'audit_export.csv',
      acceptedTypeGroups: const [
        XTypeGroup(label: 'CSV', extensions: ['csv']),
      ],
    );
    if (location == null) {
      return;
    }
    final file = File(location.path);
    await file.writeAsString(widget.controller.buildCsv());
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Экспорт аудита сохранён в ${file.path}')),
    );
  }
}
