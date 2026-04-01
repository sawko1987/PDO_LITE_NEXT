class CreateDraftMachineVersionRequestDto {
  const CreateDraftMachineVersionRequestDto({
    required this.requestId,
    required this.createdBy,
  });

  factory CreateDraftMachineVersionRequestDto.fromJson(
    Map<String, Object?> json,
  ) {
    return CreateDraftMachineVersionRequestDto(
      requestId: json['requestId'] as String? ?? '',
      createdBy: json['createdBy'] as String? ?? '',
    );
  }

  final String requestId;
  final String createdBy;

  Map<String, Object?> toJson() => {
    'requestId': requestId,
    'createdBy': createdBy,
  };
}
