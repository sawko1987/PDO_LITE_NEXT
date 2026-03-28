import 'catalog_item_kind.dart';

class CatalogItem {
  const CatalogItem({
    required this.id,
    required this.code,
    required this.name,
    required this.kind,
    this.description,
    this.isActive = true,
  });

  final String id;
  final String code;
  final String name;
  final CatalogItemKind kind;
  final String? description;
  final bool isActive;
}
