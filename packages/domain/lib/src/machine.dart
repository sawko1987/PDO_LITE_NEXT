class Machine {
  const Machine({
    required this.id,
    required this.code,
    required this.name,
    this.activeVersionId,
  });

  final String id;
  final String code;
  final String name;
  final String? activeVersionId;
}
