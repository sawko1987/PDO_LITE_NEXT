class CreateExecutionReportRequestDto {
  const CreateExecutionReportRequestDto({
    required this.requestId,
    required this.reportedBy,
    required this.reportedQuantity,
    this.reason,
  });

  factory CreateExecutionReportRequestDto.fromJson(Map<String, Object?> json) {
    return CreateExecutionReportRequestDto(
      requestId: json['requestId'] as String? ?? '',
      reportedBy: json['reportedBy'] as String? ?? '',
      reportedQuantity: (json['reportedQuantity'] as num?)?.toDouble() ?? 0,
      reason: json['reason'] as String?,
    );
  }

  final String requestId;
  final String reportedBy;
  final double reportedQuantity;
  final String? reason;

  Map<String, Object?> toJson() => {
    'requestId': requestId,
    'reportedBy': reportedBy,
    'reportedQuantity': reportedQuantity,
    'reason': reason,
  };
}
