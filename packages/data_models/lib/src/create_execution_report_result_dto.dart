import 'execution_report_dto.dart';
import 'execution_report_wip_effect_dto.dart';

class CreateExecutionReportResultDto {
  const CreateExecutionReportResultDto({
    required this.report,
    required this.taskStatus,
    required this.reportedQuantityTotal,
    required this.remainingQuantity,
    required this.outboxStatus,
    this.wipEffect,
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
      wipEffect: _parseWipEffect(json['wipEffect']),
    );
  }

  final ExecutionReportDto report;
  final String taskStatus;
  final double reportedQuantityTotal;
  final double remainingQuantity;
  final String outboxStatus;
  final ExecutionReportWipEffectDto? wipEffect;

  Map<String, Object?> toJson() => {
    'report': report.toJson(),
    'taskStatus': taskStatus,
    'reportedQuantityTotal': reportedQuantityTotal,
    'remainingQuantity': remainingQuantity,
    'outboxStatus': outboxStatus,
    'wipEffect': wipEffect?.toJson(),
  };
}

ExecutionReportWipEffectDto? _parseWipEffect(Object? rawValue) {
  final effect = (rawValue as Map<Object?, Object?>?)?.cast<String, Object?>();
  if (effect == null) {
    return null;
  }
  return ExecutionReportWipEffectDto.fromJson(effect);
}
