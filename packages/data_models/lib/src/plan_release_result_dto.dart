class PlanReleaseResultDto {
  const PlanReleaseResultDto({
    required this.planId,
    required this.status,
    required this.generatedTaskCount,
  });

  factory PlanReleaseResultDto.fromJson(Map<String, Object?> json) {
    return PlanReleaseResultDto(
      planId: json['planId'] as String? ?? '',
      status: json['status'] as String? ?? '',
      generatedTaskCount: json['generatedTaskCount'] as int? ?? 0,
    );
  }

  final String planId;
  final String status;
  final int generatedTaskCount;

  Map<String, Object?> toJson() => {
    'planId': planId,
    'status': status,
    'generatedTaskCount': generatedTaskCount,
  };
}
