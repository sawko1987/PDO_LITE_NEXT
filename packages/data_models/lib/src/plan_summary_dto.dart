import 'package:domain/domain.dart';

class PlanSummaryDto {
  const PlanSummaryDto({
    required this.id,
    required this.machineId,
    required this.versionId,
    required this.title,
    required this.createdAt,
    required this.status,
    required this.itemCount,
    required this.revisionCount,
  });

  factory PlanSummaryDto.fromDomain(Plan plan) {
    return PlanSummaryDto(
      id: plan.id,
      machineId: plan.machineId,
      versionId: plan.versionId,
      title: plan.title,
      createdAt: plan.createdAt,
      status: plan.status.name,
      itemCount: plan.items.length,
      revisionCount: plan.revisions.length,
    );
  }

  final String id;
  final String machineId;
  final String versionId;
  final String title;
  final DateTime createdAt;
  final String status;
  final int itemCount;
  final int revisionCount;

  Map<String, Object?> toJson() => {
    'id': id,
    'machineId': machineId,
    'versionId': versionId,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'status': status,
    'itemCount': itemCount,
    'revisionCount': revisionCount,
  };
}
