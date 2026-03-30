class ReleasePlanRequestDto {
  const ReleasePlanRequestDto({
    required this.requestId,
    required this.releasedBy,
  });

  factory ReleasePlanRequestDto.fromJson(Map<String, Object?> json) {
    return ReleasePlanRequestDto(
      requestId: json['requestId'] as String? ?? '',
      releasedBy: json['releasedBy'] as String? ?? '',
    );
  }

  final String requestId;
  final String releasedBy;

  Map<String, Object?> toJson() => {
    'requestId': requestId,
    'releasedBy': releasedBy,
  };
}
