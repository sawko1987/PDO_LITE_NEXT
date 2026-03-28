class AuditEntry {
  const AuditEntry({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.changedBy,
    required this.changedAt,
    this.field,
    this.beforeValue,
    this.afterValue,
  });

  final String id;
  final String entityType;
  final String entityId;
  final AuditAction action;
  final String changedBy;
  final DateTime changedAt;
  final String? field;
  final String? beforeValue;
  final String? afterValue;
}

enum AuditAction { created, updated, statusChanged, archived }
