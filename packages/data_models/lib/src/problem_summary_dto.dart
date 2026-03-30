import 'package:domain/domain.dart';

class ProblemSummaryDto {
  const ProblemSummaryDto({
    required this.id,
    required this.machineId,
    required this.status,
    required this.isOpen,
    this.taskId,
    this.title,
  });

  factory ProblemSummaryDto.fromDomain(Problem problem) {
    return ProblemSummaryDto(
      id: problem.id,
      machineId: problem.machineId,
      taskId: problem.taskId,
      title: problem.title,
      status: problem.status.name,
      isOpen: problem.isOpen,
    );
  }

  final String id;
  final String machineId;
  final String? taskId;
  final String? title;
  final String status;
  final bool isOpen;

  Map<String, Object?> toJson() => {
    'id': id,
    'machineId': machineId,
    'taskId': taskId,
    'title': title,
    'status': status,
    'isOpen': isOpen,
  };
}
