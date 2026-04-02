class ProblemReportItemDto {
  const ProblemReportItemDto({
    required this.problemId,
    required this.title,
    required this.type,
    required this.status,
    required this.isOpen,
    required this.machineId,
    required this.createdAt,
    required this.messageCount,
    required this.structureDisplayName,
    required this.operationName,
    this.taskId,
    this.closedAt,
  });

  factory ProblemReportItemDto.fromJson(Map<String, Object?> json) {
    return ProblemReportItemDto(
      problemId: json['problemId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      isOpen: json['isOpen'] as bool? ?? false,
      machineId: json['machineId'] as String? ?? '',
      taskId: json['taskId'] as String?,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      closedAt: DateTime.tryParse(json['closedAt'] as String? ?? ''),
      messageCount: (json['messageCount'] as num?)?.toInt() ?? 0,
      structureDisplayName: json['structureDisplayName'] as String? ?? '',
      operationName: json['operationName'] as String? ?? '',
    );
  }

  final String problemId;
  final String title;
  final String type;
  final String status;
  final bool isOpen;
  final String machineId;
  final String? taskId;
  final DateTime createdAt;
  final DateTime? closedAt;
  final int messageCount;
  final String structureDisplayName;
  final String operationName;

  Map<String, Object?> toJson() => {
    'problemId': problemId,
    'title': title,
    'type': type,
    'status': status,
    'isOpen': isOpen,
    'machineId': machineId,
    'taskId': taskId,
    'createdAt': createdAt.toIso8601String(),
    'closedAt': closedAt?.toIso8601String(),
    'messageCount': messageCount,
    'structureDisplayName': structureDisplayName,
    'operationName': operationName,
  };
}
