class HealthExtendedDto {
  const HealthExtendedDto({
    required this.status,
    required this.service,
    required this.timestamp,
    required this.databasePath,
    required this.databaseSizeBytes,
    required this.totalMachines,
    required this.totalPlans,
    required this.totalTasks,
    required this.totalAuditEntries,
    required this.lastAuditAt,
    required this.uptime,
  });

  factory HealthExtendedDto.fromJson(Map<String, Object?> json) {
    return HealthExtendedDto(
      status: json['status'] as String? ?? '',
      service: json['service'] as String? ?? '',
      timestamp: DateTime.parse(
        json['timestamp'] as String? ??
            DateTime.fromMillisecondsSinceEpoch(0).toIso8601String(),
      ),
      databasePath: json['databasePath'] as String? ?? '',
      databaseSizeBytes: json['databaseSizeBytes'] as int? ?? 0,
      totalMachines: json['totalMachines'] as int? ?? 0,
      totalPlans: json['totalPlans'] as int? ?? 0,
      totalTasks: json['totalTasks'] as int? ?? 0,
      totalAuditEntries: json['totalAuditEntries'] as int? ?? 0,
      lastAuditAt: (json['lastAuditAt'] as String?) == null
          ? null
          : DateTime.parse(json['lastAuditAt'] as String),
      uptime: json['uptime'] as String? ?? '',
    );
  }

  final String status;
  final String service;
  final DateTime timestamp;
  final String databasePath;
  final int databaseSizeBytes;
  final int totalMachines;
  final int totalPlans;
  final int totalTasks;
  final int totalAuditEntries;
  final DateTime? lastAuditAt;
  final String uptime;

  Map<String, Object?> toJson() => {
    'status': status,
    'service': service,
    'timestamp': timestamp.toIso8601String(),
    'databasePath': databasePath,
    'databaseSizeBytes': databaseSizeBytes,
    'totalMachines': totalMachines,
    'totalPlans': totalPlans,
    'totalTasks': totalTasks,
    'totalAuditEntries': totalAuditEntries,
    'lastAuditAt': lastAuditAt?.toIso8601String(),
    'uptime': uptime,
  };
}
