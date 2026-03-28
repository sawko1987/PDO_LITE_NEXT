import 'machine_version_status.dart';

class MachineVersion {
  const MachineVersion({
    required this.id,
    required this.machineId,
    required this.label,
    required this.createdAt,
    this.status = MachineVersionStatus.draft,
  });

  final String id;
  final String machineId;
  final String label;
  final DateTime createdAt;
  final MachineVersionStatus status;

  bool get isImmutable => status != MachineVersionStatus.draft;
}
