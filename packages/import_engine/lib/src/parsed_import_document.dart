class ParsedImportDocument {
  const ParsedImportDocument({
    required this.headers,
    required this.rows,
    this.machineName,
    this.machineCode,
  });

  final List<String> headers;
  final List<ParsedImportRow> rows;
  final String? machineName;
  final String? machineCode;
}

class ParsedImportRow {
  const ParsedImportRow({required this.rowNumber, required this.values});

  final int rowNumber;
  final Map<String, String> values;
}
