import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import 'import_source.dart';
import 'parsed_import_document.dart';

abstract class ImportSourceReader {
  const ImportSourceReader();

  ParsedImportDocument read(ImportSourceFile source);
}

class ExcelImportSourceReader extends ImportSourceReader {
  const ExcelImportSourceReader();

  @override
  ParsedImportDocument read(ImportSourceFile source) {
    final archive = ZipDecoder().decodeBytes(source.bytes);
    final workbookXml = _readArchiveText(archive, 'xl/workbook.xml');
    final workbook = XmlDocument.parse(workbookXml);
    final workbookRelationships = XmlDocument.parse(
      _readArchiveText(archive, 'xl/_rels/workbook.xml.rels'),
    );
    final sharedStrings = _readSharedStrings(archive);
    final firstSheetPath = _resolveFirstSheetPath(
      workbook: workbook,
      relationships: workbookRelationships,
    );
    final sheetXml = _readArchiveText(archive, firstSheetPath);
    final sheet = XmlDocument.parse(sheetXml);
    final rows = _readSpreadsheetRows(
      _findAllByLocalName(sheet, 'row'),
      cellLocalNames: const ['c'],
      cellIndexAttribute: 'r',
      cellValueResolver: (cell) => _resolveExcelCellValue(cell, sharedStrings),
    );

    return _buildParsedImportDocument(rows);
  }

  String _readArchiveText(Archive archive, String path) {
    final file = archive.files.firstWhere(
      (candidate) => _normalizeArchivePath(candidate.name) == path,
      orElse: () => throw FormatException('Missing archive entry: $path'),
    );
    return String.fromCharCodes(file.content);
  }

  List<String> _readSharedStrings(Archive archive) {
    final sharedStringsFile = archive.files.where(
      (file) => _normalizeArchivePath(file.name) == 'xl/sharedStrings.xml',
    );
    if (sharedStringsFile.isEmpty) {
      return const [];
    }

    final document = XmlDocument.parse(
      _readArchiveText(archive, 'xl/sharedStrings.xml'),
    );
    return _findAllByLocalName(document, 'si')
        .map(
          (XmlElement si) =>
              _findAllByLocalName(si, 't').map((node) => node.innerText).join(),
        )
        .toList(growable: false);
  }

  String _resolveFirstSheetPath({
    required XmlDocument workbook,
    required XmlDocument relationships,
  }) {
    final sheet = _findAllByLocalName(workbook, 'sheet').firstOrNull;
    if (sheet == null) {
      throw const FormatException('Workbook does not contain sheets.');
    }

    final relationshipId =
        sheet.getAttribute(
          'id',
          namespace:
              'http://schemas.openxmlformats.org/officeDocument/2006/relationships',
        ) ??
        sheet.getAttribute('r:id');
    if (relationshipId == null) {
      throw const FormatException('Workbook sheet is missing relationship id.');
    }

    final relationship = _findAllByLocalName(relationships, 'Relationship')
        .firstWhere(
          (candidate) => candidate.getAttribute('Id') == relationshipId,
          orElse: () => throw const FormatException(
            'Workbook relationship for first sheet was not found.',
          ),
        );
    final target = relationship.getAttribute('Target');
    if (target == null || target.trim().isEmpty) {
      throw const FormatException('Workbook sheet target is empty.');
    }

    final normalizedTarget = target.startsWith('/')
        ? target.substring(1)
        : 'xl/${target.replaceAll('\\', '/')}';
    return normalizedTarget;
  }

  String _resolveExcelCellValue(XmlElement cell, List<String> sharedStrings) {
    final cellType = cell.getAttribute('t');
    final value = _firstChildByLocalName(cell, 'v')?.innerText ?? '';
    if (cellType == 's') {
      final sharedStringIndex = int.tryParse(value);
      if (sharedStringIndex == null ||
          sharedStringIndex < 0 ||
          sharedStringIndex >= sharedStrings.length) {
        return '';
      }

      return sharedStrings[sharedStringIndex];
    }

    if (cellType == 'inlineStr') {
      return _findAllByLocalName(cell, 't').map((node) => node.innerText).join();
    }

    return value;
  }

  String _normalizeArchivePath(String path) => path.replaceAll('\\', '/');
}

class MxlImportSourceReader extends ImportSourceReader {
  const MxlImportSourceReader();

  @override
  ParsedImportDocument read(ImportSourceFile source) {
    final document = XmlDocument.parse(source.decodeUtf8());
    final worksheet =
        _findAllByLocalName(document, 'Worksheet').firstOrNull ??
        _findAllByLocalName(document, 'worksheet').firstOrNull;
    if (worksheet == null) {
      throw const FormatException('MXL worksheet was not found.');
    }

    final table =
        _findDirectChildrenByLocalName(worksheet, 'Table').firstOrNull ??
        _findDirectChildrenByLocalName(worksheet, 'table').firstOrNull;
    if (table == null) {
      throw const FormatException('MXL table was not found.');
    }

    final rows = _readSpreadsheetRows(
      _findAllByLocalName(table, 'Row'),
      cellLocalNames: const ['Cell'],
      cellIndexAttribute: 'Index',
      cellValueResolver: (cell) =>
          _findAllByLocalName(cell, 'Data').map((node) => node.innerText).join(),
    );

    return _buildParsedImportDocument(rows);
  }
}

ParsedImportDocument _buildParsedImportDocument(List<_SheetRow> rows) {
  if (rows.isEmpty) {
    return const ParsedImportDocument(headers: [], rows: []);
  }

  final headerRow = rows.first;
  final headers = headerRow.values
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
  final dataRows = <ParsedImportRow>[];

  for (final row in rows.skip(1)) {
    if (row.values.every((value) => value.trim().isEmpty)) {
      continue;
    }

    final mappedValues = <String, String>{};
    for (var index = 0; index < headers.length; index++) {
      mappedValues[headers[index]] = index < row.values.length
          ? row.values[index].trim()
          : '';
    }

    dataRows.add(
      ParsedImportRow(rowNumber: row.rowNumber, values: mappedValues),
    );
  }

  String? machineName;
  String? machineCode;
  for (final row in dataRows) {
    final maybeMachineName =
        row.values['machine_name'] ?? row.values['MachineName'];
    final maybeMachineCode =
        row.values['machine_code'] ?? row.values['MachineCode'];
    machineName ??= maybeMachineName?.trim().isEmpty ?? true
        ? null
        : maybeMachineName?.trim();
    machineCode ??= maybeMachineCode?.trim().isEmpty ?? true
        ? null
        : maybeMachineCode?.trim();
  }

  return ParsedImportDocument(
    headers: headers,
    rows: dataRows,
    machineName: machineName,
    machineCode: machineCode,
  );
}

List<_SheetRow> _readSpreadsheetRows(
  Iterable<XmlElement> rowElements, {
  required List<String> cellLocalNames,
  required String cellIndexAttribute,
  required String Function(XmlElement cell) cellValueResolver,
}) {
  final rows = <_SheetRow>[];
  for (final rowElement in rowElements) {
    final rowNumber =
        int.tryParse(rowElement.getAttribute('Index') ?? '') ??
        int.tryParse(rowElement.getAttribute('ss:Index') ?? '') ??
        int.tryParse(rowElement.getAttribute('r') ?? '') ??
        rows.length + 1;
    final values = <String>[];
    var lastColumnIndex = 0;

    for (final cell in _findAllByLocalNames(rowElement, cellLocalNames)) {
      final explicitIndex =
          cell.getAttribute(cellIndexAttribute) ??
          cell.getAttribute('ss:$cellIndexAttribute');
      final currentIndex = explicitIndex != null
          ? _columnIndex(explicitIndex)
          : lastColumnIndex + 1;
      while (values.length < currentIndex - 1) {
        values.add('');
      }

      values.add(cellValueResolver(cell).trim());
      lastColumnIndex = currentIndex;
    }

    if (values.isNotEmpty) {
      rows.add(_SheetRow(rowNumber: rowNumber, values: values));
    }
  }

  return rows;
}

int _columnIndex(String rawIndex) {
  final numeric = int.tryParse(rawIndex);
  if (numeric != null) {
    return numeric;
  }

  final reference = rawIndex.toUpperCase();
  final letters = reference.replaceAll(RegExp(r'[^A-Z]'), '');
  if (letters.isEmpty) {
    return 1;
  }

  var result = 0;
  for (final codeUnit in letters.codeUnits) {
    result = result * 26 + (codeUnit - 64);
  }
  return result;
}

class _SheetRow {
  const _SheetRow({required this.rowNumber, required this.values});

  final int rowNumber;
  final List<String> values;
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

Iterable<XmlElement> _findAllByLocalName(XmlNode node, String localName) {
  return node.descendants.whereType<XmlElement>().where(_localName(localName));
}

Iterable<XmlElement> _findAllByLocalNames(
  XmlNode node,
  List<String> localNames,
) {
  final allowedNames = localNames.toSet();
  return node.descendants.whereType<XmlElement>().where(
    (element) => allowedNames.contains(element.name.local),
  );
}

Iterable<XmlElement> _findDirectChildrenByLocalName(
  XmlNode node,
  String localName,
) {
  return node.children.whereType<XmlElement>().where(_localName(localName));
}

XmlElement? _firstChildByLocalName(XmlNode node, String localName) {
  return _findDirectChildrenByLocalName(node, localName).firstOrNull;
}

bool Function(XmlElement) _localName(String localName) {
  return (element) => element.name.local == localName;
}
