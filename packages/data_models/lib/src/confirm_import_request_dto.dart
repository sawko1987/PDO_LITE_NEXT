class ConfirmImportRequestDto {
  const ConfirmImportRequestDto({
    required this.requestId,
    required this.mode,
    this.targetMachineId,
  });

  factory ConfirmImportRequestDto.fromJson(Map<String, Object?> json) {
    return ConfirmImportRequestDto(
      requestId: json['requestId'] as String? ?? '',
      mode: json['mode'] as String? ?? '',
      targetMachineId: json['targetMachineId'] as String?,
    );
  }

  final String requestId;
  final String mode;
  final String? targetMachineId;

  Map<String, Object?> toJson() => {
    'requestId': requestId,
    'mode': mode,
    'targetMachineId': targetMachineId,
  };
}
