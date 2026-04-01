class DeleteOperationOccurrenceRequestDto {
  const DeleteOperationOccurrenceRequestDto({required this.requestId});

  factory DeleteOperationOccurrenceRequestDto.fromJson(
    Map<String, Object?> json,
  ) {
    return DeleteOperationOccurrenceRequestDto(
      requestId: json['requestId'] as String? ?? '',
    );
  }

  final String requestId;

  Map<String, Object?> toJson() => {'requestId': requestId};
}
