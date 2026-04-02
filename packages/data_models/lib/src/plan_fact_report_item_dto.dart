class PlanFactReportItemDto {
  const PlanFactReportItemDto({
    required this.structureOccurrenceId,
    required this.displayName,
    required this.pathKey,
    required this.workshop,
    required this.planId,
    required this.planTitle,
    required this.requestedQuantity,
    required this.reportedQuantity,
    required this.remainingQuantity,
    required this.completionPercent,
    required this.taskCount,
    required this.closedTaskCount,
    required this.operationName,
  });

  factory PlanFactReportItemDto.fromJson(Map<String, Object?> json) {
    return PlanFactReportItemDto(
      structureOccurrenceId: json['structureOccurrenceId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      pathKey: json['pathKey'] as String? ?? '',
      workshop: json['workshop'] as String? ?? '',
      planId: json['planId'] as String? ?? '',
      planTitle: json['planTitle'] as String? ?? '',
      requestedQuantity: (json['requestedQuantity'] as num?)?.toDouble() ?? 0,
      reportedQuantity: (json['reportedQuantity'] as num?)?.toDouble() ?? 0,
      remainingQuantity: (json['remainingQuantity'] as num?)?.toDouble() ?? 0,
      completionPercent: (json['completionPercent'] as num?)?.toDouble() ?? 0,
      taskCount: (json['taskCount'] as num?)?.toInt() ?? 0,
      closedTaskCount: (json['closedTaskCount'] as num?)?.toInt() ?? 0,
      operationName: json['operationName'] as String? ?? '',
    );
  }

  final String structureOccurrenceId;
  final String displayName;
  final String pathKey;
  final String workshop;
  final String planId;
  final String planTitle;
  final double requestedQuantity;
  final double reportedQuantity;
  final double remainingQuantity;
  final double completionPercent;
  final int taskCount;
  final int closedTaskCount;
  final String operationName;

  Map<String, Object?> toJson() => {
    'structureOccurrenceId': structureOccurrenceId,
    'displayName': displayName,
    'pathKey': pathKey,
    'workshop': workshop,
    'planId': planId,
    'planTitle': planTitle,
    'requestedQuantity': requestedQuantity,
    'reportedQuantity': reportedQuantity,
    'remainingQuantity': remainingQuantity,
    'completionPercent': completionPercent,
    'taskCount': taskCount,
    'closedTaskCount': closedTaskCount,
    'operationName': operationName,
  };
}
