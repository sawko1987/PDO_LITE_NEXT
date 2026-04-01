class UpdateOperationOccurrenceRequestDto {
  const UpdateOperationOccurrenceRequestDto({
    required this.requestId,
    required this.name,
    required this.quantityPerMachine,
    this.workshop,
  });

  factory UpdateOperationOccurrenceRequestDto.fromJson(
    Map<String, Object?> json,
  ) {
    return UpdateOperationOccurrenceRequestDto(
      requestId: json['requestId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      quantityPerMachine: (json['quantityPerMachine'] as num?)?.toDouble() ?? 0,
      workshop: json['workshop'] as String?,
    );
  }

  final String requestId;
  final String name;
  final double quantityPerMachine;
  final String? workshop;

  Map<String, Object?> toJson() => {
    'requestId': requestId,
    'name': name,
    'quantityPerMachine': quantityPerMachine,
    'workshop': workshop,
  };
}
