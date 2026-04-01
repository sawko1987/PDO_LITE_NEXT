class CreateStructureOccurrenceRequestDto {
  const CreateStructureOccurrenceRequestDto({
    required this.requestId,
    required this.displayName,
    required this.quantityPerMachine,
    this.parentOccurrenceId,
    this.workshop,
  });

  factory CreateStructureOccurrenceRequestDto.fromJson(
    Map<String, Object?> json,
  ) {
    return CreateStructureOccurrenceRequestDto(
      requestId: json['requestId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      quantityPerMachine: (json['quantityPerMachine'] as num?)?.toDouble() ?? 0,
      parentOccurrenceId: json['parentOccurrenceId'] as String?,
      workshop: json['workshop'] as String?,
    );
  }

  final String requestId;
  final String displayName;
  final double quantityPerMachine;
  final String? parentOccurrenceId;
  final String? workshop;

  Map<String, Object?> toJson() => {
    'requestId': requestId,
    'displayName': displayName,
    'quantityPerMachine': quantityPerMachine,
    'parentOccurrenceId': parentOccurrenceId,
    'workshop': workshop,
  };
}
