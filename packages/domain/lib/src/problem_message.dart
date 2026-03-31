class ProblemMessage {
  const ProblemMessage({
    required this.id,
    required this.problemId,
    required this.authorId,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String problemId;
  final String authorId;
  final String message;
  final DateTime createdAt;
}
