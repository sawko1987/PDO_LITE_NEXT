class PlanCompletionResultDto {
  const PlanCompletionResultDto({required this.planId, required this.status});

  factory PlanCompletionResultDto.fromJson(Map<String, Object?> json) {
    return PlanCompletionResultDto(
      planId: json['planId'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }

  final String planId;
  final String status;

  Map<String, Object?> toJson() => {'planId': planId, 'status': status};
}
