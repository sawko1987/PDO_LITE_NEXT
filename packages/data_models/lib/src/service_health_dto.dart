class ServiceHealthDto {
  const ServiceHealthDto({
    required this.status,
    required this.service,
    required this.timestamp,
  });

  final String status;
  final String service;
  final DateTime timestamp;

  Map<String, Object?> toJson() => {
        'status': status,
        'service': service,
        'timestamp': timestamp.toIso8601String(),
      };
}
