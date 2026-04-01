class UpdateStructureOccurrenceRequestDto {
  const UpdateStructureOccurrenceRequestDto({
    required this.requestId,
    required this.displayName,
    required this.quantityPerMachine,
    this.workshop,
  });

  factory UpdateStructureOccurrenceRequestDto.fromJson(
    Map<String, Object?> json,
  ) {
    return UpdateStructureOccurrenceRequestDto(
      requestId: json['requestId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      quantityPerMachine: (json['quantityPerMachine'] as num?)?.toDouble() ?? 0,
      workshop: json['workshop'] as String?,
    );
  }

  final String requestId;
  final String displayName;
  final double quantityPerMachine;
  final String? workshop;

  Map<String, Object?> toJson() => {
    'requestId': requestId,
    'displayName': displayName,
    'quantityPerMachine': quantityPerMachine,
    'workshop': workshop,
  };
}
