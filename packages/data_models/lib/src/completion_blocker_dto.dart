import 'package:domain/domain.dart';

class CompletionBlockerDto {
  const CompletionBlockerDto({required this.type, required this.entityIds});

  factory CompletionBlockerDto.fromDomain(CompletionBlocker blocker) {
    return CompletionBlockerDto(
      type: blocker.type.name,
      entityIds: List.unmodifiable(blocker.entityIds),
    );
  }

  factory CompletionBlockerDto.fromJson(Map<String, Object?> json) {
    final rawEntityIds = json['entityIds'] as List<Object?>? ?? const [];
    return CompletionBlockerDto(
      type: json['type'] as String? ?? '',
      entityIds: rawEntityIds
          .map((value) => value as String? ?? '')
          .toList(growable: false),
    );
  }

  final String type;
  final List<String> entityIds;

  Map<String, Object?> toJson() => {'type': type, 'entityIds': entityIds};
}
