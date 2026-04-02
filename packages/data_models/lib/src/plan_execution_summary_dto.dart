class PlanExecutionSummaryDto {
  const PlanExecutionSummaryDto({
    required this.planId,
    required this.totalRequested,
    required this.totalReported,
    required this.completionPercent,
    required this.taskCount,
    required this.closedTaskCount,
    required this.problemCount,
    required this.wipConsumedCount,
  });

  factory PlanExecutionSummaryDto.fromJson(Map<String, Object?> json) {
    return PlanExecutionSummaryDto(
      planId: json['planId'] as String? ?? '',
      totalRequested: (json['totalRequested'] as num? ?? 0).toDouble(),
      totalReported: (json['totalReported'] as num? ?? 0).toDouble(),
      completionPercent: (json['completionPercent'] as num? ?? 0).toDouble(),
      taskCount: json['taskCount'] as int? ?? 0,
      closedTaskCount: json['closedTaskCount'] as int? ?? 0,
      problemCount: json['problemCount'] as int? ?? 0,
      wipConsumedCount: json['wipConsumedCount'] as int? ?? 0,
    );
  }

  final String planId;
  final double totalRequested;
  final double totalReported;
  final double completionPercent;
  final int taskCount;
  final int closedTaskCount;
  final int problemCount;
  final int wipConsumedCount;

  Map<String, Object?> toJson() => {
    'planId': planId,
    'totalRequested': totalRequested,
    'totalReported': totalReported,
    'completionPercent': completionPercent,
    'taskCount': taskCount,
    'closedTaskCount': closedTaskCount,
    'problemCount': problemCount,
    'wipConsumedCount': wipConsumedCount,
  };
}
