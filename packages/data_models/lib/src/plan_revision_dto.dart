import 'package:domain/domain.dart';

import 'plan_field_change_dto.dart';

class PlanRevisionDto {
  const PlanRevisionDto({
    required this.id,
    required this.planId,
    required this.revisionNumber,
    required this.changedBy,
    required this.changedAt,
    required this.changes,
  });

  factory PlanRevisionDto.fromDomain(PlanRevision revision) {
    return PlanRevisionDto(
      id: revision.id,
      planId: revision.planId,
      revisionNumber: revision.revisionNumber,
      changedBy: revision.changedBy,
      changedAt: revision.changedAt,
      changes: revision.changes
          .map(PlanFieldChangeDto.fromDomain)
          .toList(growable: false),
    );
  }

  factory PlanRevisionDto.fromJson(Map<String, Object?> json) {
    final rawChanges = json['changes'] as List<Object?>? ?? const [];
    return PlanRevisionDto(
      id: json['id'] as String? ?? '',
      planId: json['planId'] as String? ?? '',
      revisionNumber: json['revisionNumber'] as int? ?? 0,
      changedBy: json['changedBy'] as String? ?? '',
      changedAt: DateTime.parse(
        json['changedAt'] as String? ??
            DateTime.fromMillisecondsSinceEpoch(0).toIso8601String(),
      ),
      changes: rawChanges
          .map(
            (item) => PlanFieldChangeDto.fromJson(
              (item as Map<Object?, Object?>).cast(),
            ),
          )
          .toList(growable: false),
    );
  }

  final String id;
  final String planId;
  final int revisionNumber;
  final String changedBy;
  final DateTime changedAt;
  final List<PlanFieldChangeDto> changes;

  Map<String, Object?> toJson() => {
    'id': id,
    'planId': planId,
    'revisionNumber': revisionNumber,
    'changedBy': changedBy,
    'changedAt': changedAt.toIso8601String(),
    'changes': changes.map((item) => item.toJson()).toList(growable: false),
  };
}
