import 'package:domain/domain.dart';

class PlanFieldChangeDto {
  const PlanFieldChangeDto({
    required this.targetId,
    required this.field,
    required this.beforeValue,
    required this.afterValue,
  });

  factory PlanFieldChangeDto.fromDomain(PlanFieldChange change) {
    return PlanFieldChangeDto(
      targetId: change.targetId,
      field: change.field,
      beforeValue: change.beforeValue,
      afterValue: change.afterValue,
    );
  }

  factory PlanFieldChangeDto.fromJson(Map<String, Object?> json) {
    return PlanFieldChangeDto(
      targetId: json['targetId'] as String? ?? '',
      field: json['field'] as String? ?? '',
      beforeValue: json['beforeValue'] as String? ?? '',
      afterValue: json['afterValue'] as String? ?? '',
    );
  }

  final String targetId;
  final String field;
  final String beforeValue;
  final String afterValue;

  Map<String, Object?> toJson() => {
    'targetId': targetId,
    'field': field,
    'beforeValue': beforeValue,
    'afterValue': afterValue,
  };
}
