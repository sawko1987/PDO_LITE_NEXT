import 'package:archive/archive.dart';

import 'import_source.dart';

class ImportFormatDetector {
  const ImportFormatDetector();

  ImportFormatDetection detect(ImportSourceFile source) {
    if (_looksLikeXlsx(source)) {
      return const ImportFormatDetection(
        format: ImportSourceFormat.excel,
        reason: 'zip_spreadsheet_signature',
      );
    }

    final text = source.decodeUtf8().trimLeft();
    if (_looksLikeMxl(text, source.extension)) {
      return const ImportFormatDetection(
        format: ImportSourceFormat.mxl,
        reason: 'xml_workbook_signature',
      );
    }

    return ImportFormatDetection(
      format: ImportSourceFormat.unsupported,
      reason: source.extension.isEmpty
          ? 'missing_extension_or_signature'
          : 'unsupported_extension_${source.extension}',
    );
  }

  bool _looksLikeXlsx(ImportSourceFile source) {
    if (source.bytes.length < 4) {
      return false;
    }

    final hasZipHeader =
        source.bytes[0] == 0x50 &&
        source.bytes[1] == 0x4B &&
        source.bytes[2] == 0x03 &&
        source.bytes[3] == 0x04;
    if (!hasZipHeader) {
      return false;
    }

    try {
      final archive = ZipDecoder().decodeBytes(source.bytes);
      return archive.files.any(
        (file) => _normalizeArchivePath(file.name) == 'xl/workbook.xml',
      );
    } catch (_) {
      return false;
    }
  }

  bool _looksLikeMxl(String text, String extension) {
    final normalized = text.toLowerCase();
    final looksLikeSpreadsheetMl =
        normalized.contains('<workbook') &&
        normalized.contains('<worksheet') &&
        normalized.contains('<table');
    if (looksLikeSpreadsheetMl) {
      return true;
    }

    return extension == 'mxl' && normalized.startsWith('<?xml');
  }

  String _normalizeArchivePath(String path) => path.replaceAll('\\', '/');
}
