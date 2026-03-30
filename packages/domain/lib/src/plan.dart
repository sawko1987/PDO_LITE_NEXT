import 'plan_item_source.dart';
import 'plan_revision.dart';
import 'plan_status.dart';

class Plan {
  const Plan({
    required this.id,
    required this.machineId,
    required this.versionId,
    required this.title,
    required this.createdAt,
    required this.items,
    this.status = PlanStatus.draft,
    this.revisions = const [],
  });

  final String id;
  final String machineId;
  final String versionId;
  final String title;
  final DateTime createdAt;
  final List<PlanItem> items;
  final PlanStatus status;
  final List<PlanRevision> revisions;

  bool get hasItems => items.isNotEmpty;
  bool get isReleased => status == PlanStatus.released;
  bool get canRelease => status == PlanStatus.draft && hasItems;

  bool get hasDuplicateStructureOccurrences {
    final occurrenceIds = <String>{};
    for (final item in items) {
      if (!occurrenceIds.add(item.source.structureOccurrenceId)) {
        return true;
      }
    }
    return false;
  }

  bool canEditItem(PlanItem item) {
    if (!isReleased) {
      return true;
    }

    return !item.hasRecordedExecution;
  }
}

class PlanItem {
  const PlanItem({
    required this.id,
    required this.source,
    required this.requestedQuantity,
    this.hasRecordedExecution = false,
  }) : assert(requestedQuantity > 0, 'requestedQuantity must be positive.');

  final String id;
  final PlanItemSource source;
  final double requestedQuantity;
  final bool hasRecordedExecution;

  String get structureOccurrenceId => source.structureOccurrenceId;
}
