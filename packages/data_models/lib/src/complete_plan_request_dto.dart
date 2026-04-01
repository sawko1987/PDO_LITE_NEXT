class CompletePlanRequestDto {
  const CompletePlanRequestDto({
    required this.requestId,
    required this.completedBy,
  });

  factory CompletePlanRequestDto.fromJson(Map<String, Object?> json) {
    return CompletePlanRequestDto(
      requestId: json['requestId'] as String? ?? '',
      completedBy: json['completedBy'] as String? ?? '',
    );
  }

  final String requestId;
  final String completedBy;

  Map<String, Object?> toJson() => {
    'requestId': requestId,
    'completedBy': completedBy,
  };
}
