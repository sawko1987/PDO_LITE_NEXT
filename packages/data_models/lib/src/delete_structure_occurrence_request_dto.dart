class DeleteStructureOccurrenceRequestDto {
  const DeleteStructureOccurrenceRequestDto({required this.requestId});

  factory DeleteStructureOccurrenceRequestDto.fromJson(
    Map<String, Object?> json,
  ) {
    return DeleteStructureOccurrenceRequestDto(
      requestId: json['requestId'] as String? ?? '',
    );
  }

  final String requestId;

  Map<String, Object?> toJson() => {'requestId': requestId};
}
