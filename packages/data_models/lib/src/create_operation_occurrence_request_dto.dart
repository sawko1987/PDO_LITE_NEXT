class CreateOperationOccurrenceRequestDto {
  const CreateOperationOccurrenceRequestDto({
    required this.requestId,
    required this.structureOccurrenceId,
    required this.name,
    required this.quantityPerMachine,
    this.workshop,
  });

  factory CreateOperationOccurrenceRequestDto.fromJson(
    Map<String, Object?> json,
  ) {
    return CreateOperationOccurrenceRequestDto(
      requestId: json['requestId'] as String? ?? '',
      structureOccurrenceId: json['structureOccurrenceId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      quantityPerMachine: (json['quantityPerMachine'] as num?)?.toDouble() ?? 0,
      workshop: json['workshop'] as String?,
    );
  }

  final String requestId;
  final String structureOccurrenceId;
  final String name;
  final double quantityPerMachine;
  final String? workshop;

  Map<String, Object?> toJson() => {
    'requestId': requestId,
    'structureOccurrenceId': structureOccurrenceId,
    'name': name,
    'quantityPerMachine': quantityPerMachine,
    'workshop': workshop,
  };
}
