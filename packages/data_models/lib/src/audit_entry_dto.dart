import 'package:domain/domain.dart';

class AuditEntryDto {
  const AuditEntryDto({
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

  factory AuditEntryDto.fromDomain(AuditEntry entry) {
    return AuditEntryDto(
      id: entry.id,
      entityType: entry.entityType,
      entityId: entry.entityId,
      action: entry.action.name,
      changedBy: entry.changedBy,
      changedAt: entry.changedAt,
      field: entry.field,
      beforeValue: entry.beforeValue,
      afterValue: entry.afterValue,
    );
  }

  final String id;
  final String entityType;
  final String entityId;
  final String action;
  final String changedBy;
  final DateTime changedAt;
  final String? field;
  final String? beforeValue;
  final String? afterValue;

  Map<String, Object?> toJson() => {
    'id': id,
    'entityType': entityType,
    'entityId': entityId,
    'action': action,
    'changedBy': changedBy,
    'changedAt': changedAt.toIso8601String(),
    'field': field,
    'beforeValue': beforeValue,
    'afterValue': afterValue,
  };
}
