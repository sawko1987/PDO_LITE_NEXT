import 'package:domain/domain.dart';

class MachineVersionSummaryDto {
  const MachineVersionSummaryDto({
    required this.id,
    required this.machineId,
    required this.label,
    required this.createdAt,
    required this.status,
    required this.isImmutable,
  });

  factory MachineVersionSummaryDto.fromDomain(MachineVersion version) {
    return MachineVersionSummaryDto(
      id: version.id,
      machineId: version.machineId,
      label: version.label,
      createdAt: version.createdAt,
      status: version.status.name,
      isImmutable: version.isImmutable,
    );
  }

  factory MachineVersionSummaryDto.fromJson(Map<String, Object?> json) {
    return MachineVersionSummaryDto(
      id: json['id'] as String? ?? '',
      machineId: json['machineId'] as String? ?? '',
      label: json['label'] as String? ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] as String? ??
            DateTime.fromMillisecondsSinceEpoch(0).toIso8601String(),
      ),
      status: json['status'] as String? ?? '',
      isImmutable: json['isImmutable'] as bool? ?? false,
    );
  }

  final String id;
  final String machineId;
  final String label;
  final DateTime createdAt;
  final String status;
  final bool isImmutable;

  Map<String, Object?> toJson() => {
    'id': id,
    'machineId': machineId,
    'label': label,
    'createdAt': createdAt.toIso8601String(),
    'status': status,
    'isImmutable': isImmutable,
  };
}
