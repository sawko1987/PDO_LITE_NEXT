class BackupInfoDto {
  const BackupInfoDto({
    required this.backupId,
    required this.fileName,
    required this.createdAt,
    required this.sizeBytes,
    required this.status,
  });

  factory BackupInfoDto.fromJson(Map<String, Object?> json) {
    return BackupInfoDto(
      backupId: json['backupId'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] as String? ??
            DateTime.fromMillisecondsSinceEpoch(0).toIso8601String(),
      ),
      sizeBytes: json['sizeBytes'] as int? ?? 0,
      status: json['status'] as String? ?? '',
    );
  }

  final String backupId;
  final String fileName;
  final DateTime createdAt;
  final int sizeBytes;
  final String status;

  Map<String, Object?> toJson() => {
    'backupId': backupId,
    'fileName': fileName,
    'createdAt': createdAt.toIso8601String(),
    'sizeBytes': sizeBytes,
    'status': status,
  };
}
