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

    // Japanese multi-price fields (JPY)
    double? boxPriceJpy,
    double? noShrinkPriceJpy,
    double? casePriceJpy,

    // Japanese multi-price fields (USD)
    double? boxPriceUsd,
    double? boxPriceUsdWithTariff,
    double? noShrinkPriceUsd,
    double? noShrinkPriceUsdWithTariff,
    double? casePriceUsd,
    double? casePriceUsdWithTariff,

    // Exchange rate used for JPY → USD conversion (for auditability)
    double? exchangeRateUsed,

    // Chinese category: "official" or "fan_art"
    String? category,

    // Pack hierarchy, e.g. "1 Case = 20 Boxes"
    String? specifications,

    // Availability remarks
    String? notes,

    // True when price is "ask" (quote required)
    @Default(false) bool quoteRequired,
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

    // Japanese multi-price fields (JPY)
    double? boxPriceJpy,
    double? noShrinkPriceJpy,
    double? casePriceJpy,

    // Japanese multi-price fields (USD)
    double? boxPriceUsd,
    double? boxPriceUsdWithTariff,
    double? noShrinkPriceUsd,
    double? noShrinkPriceUsdWithTariff,
    double? casePriceUsd,
    double? casePriceUsdWithTariff,

    // Chinese category: "official" or "fan_art"
    String? category,

    // Pack hierarchy
    String? specifications,

    // Availability remarks
    String? notes,

    // Product image URL
    String? imageUrl,

    // True when price is "ask"
    @Default(false) bool quoteRequired,
  }) = _ProductImportRow;

  factory ProductImportRow.fromJson(Map<String, dynamic> json) =>
      _$ProductImportRowFromJson(json);
}
