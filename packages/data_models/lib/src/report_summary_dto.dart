class ReportSummaryDto {
  const ReportSummaryDto({
    required this.totalPlans,
    required this.draftPlans,
    required this.releasedPlans,
    required this.completedPlans,
    required this.totalTasks,
    required this.activeTasks,
    required this.completedTasks,
    required this.totalProblems,
    required this.openProblems,
    required this.closedProblems,
    required this.totalWipEntries,
    required this.blockingWipEntries,
    required this.totalExecutionReports,
  });

  factory ReportSummaryDto.fromJson(Map<String, Object?> json) {
    return ReportSummaryDto(
      totalPlans: (json['totalPlans'] as num?)?.toInt() ?? 0,
      draftPlans: (json['draftPlans'] as num?)?.toInt() ?? 0,
      releasedPlans: (json['releasedPlans'] as num?)?.toInt() ?? 0,
      completedPlans: (json['completedPlans'] as num?)?.toInt() ?? 0,
      totalTasks: (json['totalTasks'] as num?)?.toInt() ?? 0,
      activeTasks: (json['activeTasks'] as num?)?.toInt() ?? 0,
      completedTasks: (json['completedTasks'] as num?)?.toInt() ?? 0,
      totalProblems: (json['totalProblems'] as num?)?.toInt() ?? 0,
      openProblems: (json['openProblems'] as num?)?.toInt() ?? 0,
      closedProblems: (json['closedProblems'] as num?)?.toInt() ?? 0,
      totalWipEntries: (json['totalWipEntries'] as num?)?.toInt() ?? 0,
      blockingWipEntries: (json['blockingWipEntries'] as num?)?.toInt() ?? 0,
      totalExecutionReports:
          (json['totalExecutionReports'] as num?)?.toInt() ?? 0,
    );
  }

  final int totalPlans;
  final int draftPlans;
  final int releasedPlans;
  final int completedPlans;
  final int totalTasks;
  final int activeTasks;
  final int completedTasks;
  final int totalProblems;
  final int openProblems;
  final int closedProblems;
  final int totalWipEntries;
  final int blockingWipEntries;
  final int totalExecutionReports;

  Map<String, Object?> toJson() => {
    'totalPlans': totalPlans,
    'draftPlans': draftPlans,
    'releasedPlans': releasedPlans,
    'completedPlans': completedPlans,
    'totalTasks': totalTasks,
    'activeTasks': activeTasks,
    'completedTasks': completedTasks,
    'totalProblems': totalProblems,
    'openProblems': openProblems,
    'closedProblems': closedProblems,
    'totalWipEntries': totalWipEntries,
    'blockingWipEntries': blockingWipEntries,
    'totalExecutionReports': totalExecutionReports,
  };
}
