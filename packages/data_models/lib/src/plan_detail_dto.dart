import 'package:domain/domain.dart';

import 'plan_detail_item_dto.dart';

class PlanDetailDto {
  const PlanDetailDto({
    required this.id,
    required this.machineId,
    required this.versionId,
    required this.title,
    required this.createdAt,
    required this.status,
    required this.canRelease,
    required this.itemCount,
    required this.revisionCount,
    required this.items,
  });

  factory PlanDetailDto.fromDomain(
    Plan plan, {
    required List<PlanDetailItemDto> items,
  }) {
    return PlanDetailDto(
      id: plan.id,
      machineId: plan.machineId,
      versionId: plan.versionId,
      title: plan.title,
      createdAt: plan.createdAt,
      status: plan.status.name,
      canRelease: plan.canRelease,
      itemCount: plan.items.length,
      revisionCount: plan.revisions.length,
      items: items,
    );
  }

  factory PlanDetailDto.fromJson(Map<String, Object?> json) {
    final rawItems = json['items'] as List<Object?>? ?? const [];
    return PlanDetailDto(
      id: json['id'] as String? ?? '',
      machineId: json['machineId'] as String? ?? '',
      versionId: json['versionId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] as String? ??
            DateTime.fromMillisecondsSinceEpoch(0).toIso8601String(),
      ),
      status: json['status'] as String? ?? '',
      canRelease: json['canRelease'] as bool? ?? false,
      itemCount: json['itemCount'] as int? ?? 0,
      revisionCount: json['revisionCount'] as int? ?? 0,
      items: rawItems
          .map(
            (item) => PlanDetailItemDto.fromJson(
              (item as Map<Object?, Object?>).cast(),
            ),
          )
          .toList(growable: false),
    );
  }

  final String id;
  final String machineId;
  final String versionId;
  final String title;
  final DateTime createdAt;
  final String status;
  final bool canRelease;
  final int itemCount;
  final int revisionCount;
  final List<PlanDetailItemDto> items;

  Map<String, Object?> toJson() => {
    'id': id,
    'machineId': machineId,
    'versionId': versionId,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'status': status,
    'canRelease': canRelease,
    'itemCount': itemCount,
    'revisionCount': revisionCount,
    'items': items.map((item) => item.toJson()).toList(growable: false),
  };
}
