class ExecutionReportWipEffectDto {
  const ExecutionReportWipEffectDto({
    required this.type,
    this.wipEntryId,
    this.balanceQuantity,
    this.status,
  });

  factory ExecutionReportWipEffectDto.fromJson(Map<String, Object?> json) {
    return ExecutionReportWipEffectDto(
      type: json['type'] as String? ?? 'none',
      wipEntryId: json['wipEntryId'] as String?,
      balanceQuantity: (json['balanceQuantity'] as num?)?.toDouble(),
      status: json['status'] as String?,
    );
  }

  final String type;
  final String? wipEntryId;
  final double? balanceQuantity;
  final String? status;

  Map<String, Object?> toJson() => {
    'type': type,
    'wipEntryId': wipEntryId,
    'balanceQuantity': balanceQuantity,
    'status': status,
  };
}
