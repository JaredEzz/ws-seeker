/// Product model
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'order.dart';

part 'product.freezed.dart';
part 'product.g.dart';

/// Represents a product available for wholesale ordering
@freezed
class Product with _$Product {
  const factory Product({
    required String id,
    required String name,
    required ProductLanguage language,
    required double basePrice,
    String? description,
    String? imageUrl,
    String? sku,
    @Default(true) bool isActive,
    required DateTime updatedAt,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
}

/// Product data from Excel import
/// Used for ingesting product updates
@freezed
class ProductImportRow with _$ProductImportRow {
  const factory ProductImportRow({
    required String name,
    required String language,
    required double price,
    String? description,
    String? sku,
  }) = _ProductImportRow;

  factory ProductImportRow.fromJson(Map<String, dynamic> json) =>
      _$ProductImportRowFromJson(json);
}
