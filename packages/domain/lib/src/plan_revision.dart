class PlanRevision {
  const PlanRevision({
    required this.id,
    required this.planId,
    required this.revisionNumber,
    required this.changedBy,
    required this.changedAt,
    required this.changes,
  });

  final String id;
  final String planId;
  final int revisionNumber;
  final String changedBy;
  final DateTime changedAt;
  final List<PlanFieldChange> changes;
}

class PlanFieldChange {
  const PlanFieldChange({
    required this.targetId,
    required this.field,
    required this.beforeValue,
    required this.afterValue,
  });

  final String targetId;
  final String field;
  final String beforeValue;
  final String afterValue;
}
