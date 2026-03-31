import 'package:domain/domain.dart';

class ProblemMessageDto {
  const ProblemMessageDto({
    required this.id,
    required this.problemId,
    required this.authorId,
    required this.message,
    required this.createdAt,
  });

  factory ProblemMessageDto.fromDomain(ProblemMessage message) {
    return ProblemMessageDto(
      id: message.id,
      problemId: message.problemId,
      authorId: message.authorId,
      message: message.message,
      createdAt: message.createdAt,
    );
  }

  factory ProblemMessageDto.fromJson(Map<String, Object?> json) {
    return ProblemMessageDto(
      id: json['id'] as String? ?? '',
      problemId: json['problemId'] as String? ?? '',
      authorId: json['authorId'] as String? ?? '',
      message: json['message'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  final String id;
  final String problemId;
  final String authorId;
  final String message;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'problemId': problemId,
    'authorId': authorId,
    'message': message,
    'createdAt': createdAt.toIso8601String(),
  };
}
