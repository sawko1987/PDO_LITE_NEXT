class ConfirmImportResultDto {
  const ConfirmImportResultDto({
    required this.sessionId,
    required this.status,
    required this.mode,
    required this.machineId,
    required this.versionId,
    required this.versionLabel,
  });

  factory ConfirmImportResultDto.fromJson(Map<String, Object?> json) {
    return ConfirmImportResultDto(
      sessionId: json['sessionId'] as String? ?? '',
      status: json['status'] as String? ?? '',
      mode: json['mode'] as String? ?? '',
      machineId: json['machineId'] as String? ?? '',
      versionId: json['versionId'] as String? ?? '',
      versionLabel: json['versionLabel'] as String? ?? '',
    );
  }

  final String sessionId;
  final String status;
  final String mode;
  final String machineId;
  final String versionId;
  final String versionLabel;

  Map<String, Object?> toJson() => {
    'sessionId': sessionId,
    'status': status,
    'mode': mode,
    'machineId': machineId,
    'versionId': versionId,
    'versionLabel': versionLabel,
  };
}
