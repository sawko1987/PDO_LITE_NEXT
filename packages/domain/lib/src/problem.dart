import 'problem_status.dart';

class Problem {
  const Problem({
    required this.id,
    required this.machineId,
    required this.status,
    this.taskId,
    this.title,
  });

  final String id;
  final String machineId;
  final String? taskId;
  final String? title;
  final ProblemStatus status;

  bool get isOpen => status != ProblemStatus.closed;
}
