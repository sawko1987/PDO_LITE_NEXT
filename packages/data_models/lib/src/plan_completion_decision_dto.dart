import 'package:domain/domain.dart';

import 'completion_blocker_dto.dart';

class PlanCompletionDecisionDto {
  const PlanCompletionDecisionDto({
    required this.planId,
    required this.canComplete,
    required this.blockers,
  });

  factory PlanCompletionDecisionDto.fromDomain(
    String planId,
    CompletionDecision decision,
  ) {
    return PlanCompletionDecisionDto(
      planId: planId,
      canComplete: decision.canComplete,
      blockers: decision.blockers
          .map(CompletionBlockerDto.fromDomain)
          .toList(growable: false),
    );
  }

  factory PlanCompletionDecisionDto.fromJson(Map<String, Object?> json) {
    final rawBlockers = json['blockers'] as List<Object?>? ?? const [];
    return PlanCompletionDecisionDto(
      planId: json['planId'] as String? ?? '',
      canComplete: json['canComplete'] as bool? ?? false,
      blockers: rawBlockers
          .map(
            (value) => CompletionBlockerDto.fromJson(
              (value as Map<Object?, Object?>).cast(),
            ),
          )
          .toList(growable: false),
    );
  }

  final String planId;
  final bool canComplete;
  final List<CompletionBlockerDto> blockers;

  Map<String, Object?> toJson() => {
    'planId': planId,
    'canComplete': canComplete,
    'blockers': blockers.map((blocker) => blocker.toJson()).toList(),
  };
}
