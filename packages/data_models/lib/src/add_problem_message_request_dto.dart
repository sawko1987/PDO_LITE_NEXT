class AddProblemMessageRequestDto {
  const AddProblemMessageRequestDto({
    required this.requestId,
    required this.authorId,
    required this.message,
  });

  factory AddProblemMessageRequestDto.fromJson(Map<String, Object?> json) {
    return AddProblemMessageRequestDto(
      requestId: json['requestId'] as String? ?? '',
      authorId: json['authorId'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }

  final String requestId;
  final String authorId;
  final String message;

  Map<String, Object?> toJson() => {
    'requestId': requestId,
    'authorId': authorId,
    'message': message,
  };
}
