class TransitionProblemRequestDto {
  const TransitionProblemRequestDto({
    required this.requestId,
    required this.changedBy,
    required this.toStatus,
  });

  factory TransitionProblemRequestDto.fromJson(Map<String, Object?> json) {
    return TransitionProblemRequestDto(
      requestId: json['requestId'] as String? ?? '',
      changedBy: json['changedBy'] as String? ?? '',
      toStatus: json['toStatus'] as String? ?? '',
    );
  }

  final String requestId;
  final String changedBy;
  final String toStatus;

  Map<String, Object?> toJson() => {
    'requestId': requestId,
    'changedBy': changedBy,
    'toStatus': toStatus,
  };
}
