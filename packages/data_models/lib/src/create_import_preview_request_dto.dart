class CreateImportPreviewRequestDto {
  const CreateImportPreviewRequestDto({
    required this.requestId,
    required this.fileName,
    required this.fileContentBase64,
  });

  factory CreateImportPreviewRequestDto.fromJson(Map<String, Object?> json) {
    return CreateImportPreviewRequestDto(
      requestId: json['requestId'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
      fileContentBase64: json['fileContentBase64'] as String? ?? '',
    );
  }

  final String requestId;
  final String fileName;
  final String fileContentBase64;

  Map<String, Object?> toJson() => {
    'requestId': requestId,
    'fileName': fileName,
    'fileContentBase64': fileContentBase64,
  };
}
