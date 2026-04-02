class CreateBackupRequestDto {
  const CreateBackupRequestDto({
    required this.requestId,
    required this.createdBy,
  });

  factory CreateBackupRequestDto.fromJson(Map<String, Object?> json) {
    return CreateBackupRequestDto(
      requestId: json['requestId'] as String? ?? '',
      createdBy: json['createdBy'] as String? ?? '',
    );
  }

  final String requestId;
  final String createdBy;

  Map<String, Object?> toJson() => {
    'requestId': requestId,
    'createdBy': createdBy,
  };
}
