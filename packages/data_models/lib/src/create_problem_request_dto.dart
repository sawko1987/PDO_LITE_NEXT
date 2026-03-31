class CreateProblemRequestDto {
  const CreateProblemRequestDto({
    required this.requestId,
    required this.createdBy,
    required this.type,
    required this.title,
    required this.description,
  });

  factory CreateProblemRequestDto.fromJson(Map<String, Object?> json) {
    return CreateProblemRequestDto(
      requestId: json['requestId'] as String? ?? '',
      createdBy: json['createdBy'] as String? ?? '',
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  final String requestId;
  final String createdBy;
  final String type;
  final String title;
  final String description;

  Map<String, Object?> toJson() => {
    'requestId': requestId,
    'createdBy': createdBy,
    'type': type,
    'title': title,
    'description': description,
  };
}
