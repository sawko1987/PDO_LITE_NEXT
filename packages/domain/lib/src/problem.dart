import 'problem_status.dart';
import 'problem_type.dart';

class Problem {
  const Problem({
    required this.id,
    required this.machineId,
    required this.type,
    required this.createdAt,
    required this.status,
    this.taskId,
    this.title,
  });

  final String id;
  final String machineId;
  final ProblemType type;
  final DateTime createdAt;
  final String? taskId;
  final String? title;
  final ProblemStatus status;

  bool get isOpen => status != ProblemStatus.closed;
}
