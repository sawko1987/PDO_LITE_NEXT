class PlanArchiveItemDto {
  const PlanArchiveItemDto({
    required this.id,
    required this.machineId,
    required this.machineCode,
    required this.versionId,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.completedAt,
    required this.itemCount,
    required this.totalReported,
    required this.completionPercent,
  });

  factory PlanArchiveItemDto.fromJson(Map<String, Object?> json) {
    return PlanArchiveItemDto(
      id: json['id'] as String? ?? '',
      machineId: json['machineId'] as String? ?? '',
      machineCode: json['machineCode'] as String? ?? '',
      versionId: json['versionId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] as String? ??
            DateTime.fromMillisecondsSinceEpoch(0).toIso8601String(),
      ),
      completedAt: DateTime.parse(
        json['completedAt'] as String? ??
            DateTime.fromMillisecondsSinceEpoch(0).toIso8601String(),
      ),
      itemCount: json['itemCount'] as int? ?? 0,
      totalReported: (json['totalReported'] as num? ?? 0).toDouble(),
      completionPercent: (json['completionPercent'] as num? ?? 0).toDouble(),
    );
  }

  final String id;
  final String machineId;
  final String machineCode;
  final String versionId;
  final String title;
  final String status;
  final DateTime createdAt;
  final DateTime completedAt;
  final int itemCount;
  final double totalReported;
  final double completionPercent;

  Map<String, Object?> toJson() => {
    'id': id,
    'machineId': machineId,
    'machineCode': machineCode,
    'versionId': versionId,
    'title': title,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt.toIso8601String(),
    'itemCount': itemCount,
    'totalReported': totalReported,
    'completionPercent': completionPercent,
  };
}
