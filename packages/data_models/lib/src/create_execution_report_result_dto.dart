import 'execution_report_dto.dart';

class CreateExecutionReportResultDto {
  const CreateExecutionReportResultDto({
    required this.report,
    required this.taskStatus,
    required this.reportedQuantityTotal,
    required this.remainingQuantity,
    required this.outboxStatus,
  });

  factory CreateExecutionReportResultDto.fromJson(Map<String, Object?> json) {
    return CreateExecutionReportResultDto(
      report: ExecutionReportDto.fromJson(
        (json['report'] as Map<Object?, Object?>?)?.cast<String, Object?>() ??
            const <String, Object?>{},
      ),
      taskStatus: json['taskStatus'] as String? ?? '',
      reportedQuantityTotal:
          (json['reportedQuantityTotal'] as num?)?.toDouble() ?? 0,
      remainingQuantity: (json['remainingQuantity'] as num?)?.toDouble() ?? 0,
      outboxStatus: json['outboxStatus'] as String? ?? '',
    );
  }

  final ExecutionReportDto report;
  final String taskStatus;
  final double reportedQuantityTotal;
  final double remainingQuantity;
  final String outboxStatus;

  Map<String, Object?> toJson() => {
    'report': report.toJson(),
    'taskStatus': taskStatus,
    'reportedQuantityTotal': reportedQuantityTotal,
    'remainingQuantity': remainingQuantity,
    'outboxStatus': outboxStatus,
  };
}
