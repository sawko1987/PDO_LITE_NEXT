import 'dart:convert';
import 'dart:typed_data';

enum ImportSourceFormat { excel, mxl, unsupported }

class ImportSourceFile {
  ImportSourceFile({required this.fileName, required List<int> bytes})
    : bytes = Uint8List.fromList(bytes);

  final String fileName;
  final Uint8List bytes;

  String get extension {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == fileName.length - 1) {
      return '';
    }

    return fileName.substring(dotIndex + 1).toLowerCase();
  }

  String decodeUtf8() => utf8.decode(bytes, allowMalformed: true);
}

class ImportFormatDetection {
  const ImportFormatDetection({required this.format, required this.reason});

  final ImportSourceFormat format;
  final String reason;
}

class ImportSourceInfo {
  const ImportSourceInfo({
    required this.fileName,
    required this.format,
    required this.detectionReason,
    required this.rowCount,
    required this.canConfirm,
  });

  final String fileName;
  final ImportSourceFormat format;
  final String detectionReason;
  final int rowCount;
  final bool canConfirm;
}
