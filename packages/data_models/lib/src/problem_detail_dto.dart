import 'problem_message_dto.dart';

class ProblemDetailDto {
  const ProblemDetailDto({
    required this.id,
    required this.machineId,
    required this.type,
    required this.status,
    required this.isOpen,
    required this.createdAt,
    required this.messages,
    this.taskId,
    this.title,
  });

  factory ProblemDetailDto.fromJson(Map<String, Object?> json) {
    final messages = (json['messages'] as List<Object?>? ?? const [])
        .whereType<Map<Object?, Object?>>()
        .map((item) => ProblemMessageDto.fromJson(item.cast<String, Object?>()))
        .toList(growable: false);
    return ProblemDetailDto(
      id: json['id'] as String? ?? '',
      machineId: json['machineId'] as String? ?? '',
      type: json['type'] as String? ?? '',
      taskId: json['taskId'] as String?,
      title: json['title'] as String?,
      status: json['status'] as String? ?? '',
      isOpen: json['isOpen'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      messages: messages,
    );
  }

  final String id;
  final String machineId;
  final String type;
  final String? taskId;
  final String? title;
  final String status;
  final bool isOpen;
  final DateTime createdAt;
  final List<ProblemMessageDto> messages;

  Map<String, Object?> toJson() => {
    'id': id,
    'machineId': machineId,
    'type': type,
    'taskId': taskId,
    'title': title,
    'status': status,
    'isOpen': isOpen,
    'createdAt': createdAt.toIso8601String(),
    'messages': messages.map((message) => message.toJson()).toList(),
  };
}
