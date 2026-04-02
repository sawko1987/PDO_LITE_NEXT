import 'execution_report_dto.dart';

class ShiftReportItemDto {
  const ShiftReportItemDto({
    required this.taskId,
    required this.structureDisplayName,
    required this.operationName,
    required this.workshop,
    required this.requiredQuantity,
    required this.reportedQuantity,
    required this.remainingQuantity,
    required this.status,
    required this.isClosed,
    required this.reports,
    this.assigneeId,
  });

  factory ShiftReportItemDto.fromJson(Map<String, Object?> json) {
    final reports = (json['reports'] as List<Object?>? ?? const [])
        .whereType<Map<Object?, Object?>>()
        .map(
          (item) => ExecutionReportDto.fromJson(item.cast<String, Object?>()),
        )
        .toList(growable: false);
    return ShiftReportItemDto(
      taskId: json['taskId'] as String? ?? '',
      assigneeId: json['assigneeId'] as String?,
      structureDisplayName: json['structureDisplayName'] as String? ?? '',
      operationName: json['operationName'] as String? ?? '',
      workshop: json['workshop'] as String? ?? '',
      requiredQuantity: (json['requiredQuantity'] as num?)?.toDouble() ?? 0,
      reportedQuantity: (json['reportedQuantity'] as num?)?.toDouble() ?? 0,
      remainingQuantity: (json['remainingQuantity'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? '',
      isClosed: json['isClosed'] as bool? ?? false,
      reports: reports,
    );
  }

  final String taskId;
  final String? assigneeId;
  final String structureDisplayName;
  final String operationName;
  final String workshop;
  final double requiredQuantity;
  final double reportedQuantity;
  final double remainingQuantity;
  final String status;
  final bool isClosed;
  final List<ExecutionReportDto> reports;

  Map<String, Object?> toJson() => {
    'taskId': taskId,
    'assigneeId': assigneeId,
    'structureDisplayName': structureDisplayName,
    'operationName': operationName,
    'workshop': workshop,
    'requiredQuantity': requiredQuantity,
    'reportedQuantity': reportedQuantity,
    'remainingQuantity': remainingQuantity,
    'status': status,
    'isClosed': isClosed,
    'reports': reports.map((report) => report.toJson()).toList(growable: false),
  };
}
