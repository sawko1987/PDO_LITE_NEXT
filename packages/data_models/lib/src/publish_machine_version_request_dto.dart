class PublishMachineVersionRequestDto {
  const PublishMachineVersionRequestDto({
    required this.requestId,
    required this.publishedBy,
  });

  factory PublishMachineVersionRequestDto.fromJson(Map<String, Object?> json) {
    return PublishMachineVersionRequestDto(
      requestId: json['requestId'] as String? ?? '',
      publishedBy: json['publishedBy'] as String? ?? '',
    );
  }

  final String requestId;
  final String publishedBy;

  Map<String, Object?> toJson() => {
    'requestId': requestId,
    'publishedBy': publishedBy,
  };
}
