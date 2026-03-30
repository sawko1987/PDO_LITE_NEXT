import 'package:domain/domain.dart';

class MachineSummaryDto {
  const MachineSummaryDto({
    required this.id,
    required this.code,
    required this.name,
    this.activeVersionId,
  });

  factory MachineSummaryDto.fromDomain(Machine machine) {
    return MachineSummaryDto(
      id: machine.id,
      code: machine.code,
      name: machine.name,
      activeVersionId: machine.activeVersionId,
    );
  }

  factory MachineSummaryDto.fromJson(Map<String, Object?> json) {
    return MachineSummaryDto(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      activeVersionId: json['activeVersionId'] as String?,
    );
  }

  final String id;
  final String code;
  final String name;
  final String? activeVersionId;

  Map<String, Object?> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'activeVersionId': activeVersionId,
  };
}
