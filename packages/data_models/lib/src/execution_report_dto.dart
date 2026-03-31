import 'package:domain/domain.dart';

class ExecutionReportDto {
  const ExecutionReportDto({
    required this.id,
    required this.taskId,
    required this.reportedBy,
    required this.reportedAt,
    required this.reportedQuantity,
    required this.isAccepted,
    this.reason,
    this.acceptedAt,
  });

  factory ExecutionReportDto.fromDomain(ExecutionReport report) {
    return ExecutionReportDto(
      id: report.id,
      taskId: report.taskId,
      reportedBy: report.reportedBy,
      reportedAt: report.reportedAt,
      reportedQuantity: report.reportedQuantity,
      reason: report.reason,
      acceptedAt: report.acceptedAt,
      isAccepted: report.isAccepted,
    );
  }

  factory ExecutionReportDto.fromJson(Map<String, Object?> json) {
    return ExecutionReportDto(
      id: json['id'] as String? ?? '',
      taskId: json['taskId'] as String? ?? '',
      reportedBy: json['reportedBy'] as String? ?? '',
      reportedAt:
          DateTime.tryParse(json['reportedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      reportedQuantity: (json['reportedQuantity'] as num?)?.toDouble() ?? 0,
      reason: json['reason'] as String?,
      acceptedAt: DateTime.tryParse(json['acceptedAt'] as String? ?? ''),
      isAccepted: json['isAccepted'] as bool? ?? false,
    );
  }

  final String id;
  final String taskId;
  final String reportedBy;
  final DateTime reportedAt;
  final double reportedQuantity;
  final String? reason;
  final DateTime? acceptedAt;
  final bool isAccepted;

  Map<String, Object?> toJson() => {
    'id': id,
    'taskId': taskId,
    'reportedBy': reportedBy,
    'reportedAt': reportedAt.toIso8601String(),
    'reportedQuantity': reportedQuantity,
    'reason': reason,
    'acceptedAt': acceptedAt?.toIso8601String(),
    'isAccepted': isAccepted,
  };
}
