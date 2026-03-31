class CreateExecutionReportRequestDto {
  const CreateExecutionReportRequestDto({
    required this.requestId,
    required this.reportedBy,
    required this.reportedQuantity,
    required this.outcome,
    this.reason,
  });

  factory CreateExecutionReportRequestDto.fromJson(Map<String, Object?> json) {
    return CreateExecutionReportRequestDto(
      requestId: json['requestId'] as String? ?? '',
      reportedBy: json['reportedBy'] as String? ?? '',
      reportedQuantity: (json['reportedQuantity'] as num?)?.toDouble() ?? 0,
      outcome: json['outcome'] as String? ?? '',
      reason: json['reason'] as String?,
    );
  }

  final String requestId;
  final String reportedBy;
  final double reportedQuantity;
  final String outcome;
  final String? reason;

  Map<String, Object?> toJson() => {
    'requestId': requestId,
    'reportedBy': reportedBy,
    'reportedQuantity': reportedQuantity,
    'outcome': outcome,
    'reason': reason,
  };
}
