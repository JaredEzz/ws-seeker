/// Price calculation service
///
/// Implements pricing rules:
/// - CN/KR: 13% markup on subtotal, tariff baked into shipping
/// - JPN: No markup, tariff included in USD-with-tariff prices,
///         JPY→USD conversion for products without USD prices
library;

import '../models/order.dart';
import '../models/product.dart';
import 'currency_converter.dart';

/// Calculated pricing breakdown for an order
class OrderPricing {
  const OrderPricing({
    required this.subtotal,
    required this.markup,
    required this.estimatedTariff,
    required this.total,
  });

  final double subtotal;
  final double markup;
  final double estimatedTariff;
  final double total;
}

/// Price calculation interface
abstract interface class PriceCalculator {
  /// Calculate subtotal from order items
  double calculateSubtotal(List<OrderItem> items);

  /// Apply markup based on product language/origin
  double applyMarkup(double subtotal, ProductLanguage language);

  /// Calculate complete pricing breakdown
  OrderPricing calculateFinalPrice({
    required List<OrderItem> items,
    required ProductLanguage language,
  });

  /// Resolve unit price for a product with optional type selection.
  ///
  /// For JPN products with a productType, uses the type-specific USD price.
  /// Falls back to JPY→USD conversion if no USD price is available.
  double resolveProductPrice(
    Product product, {
    String? productType,
  });
}

/// Default price calculator implementation
///
/// Implements:
/// - 13% markup for Chinese/Korean products
/// - JPY→USD conversion with configurable rate
/// - Tariff extraction from USD-with-tariff prices
class DefaultPriceCalculator implements PriceCalculator {
  const DefaultPriceCalculator({
    this.chineseKoreanMarkupRate = 0.13,
    CurrencyConverter? currencyConverter,
  }) : _currencyConverter = currencyConverter;

  /// 13% markup for Chinese/Korean products
  final double chineseKoreanMarkupRate;

  final CurrencyConverter? _currencyConverter;

  CurrencyConverter get _converter =>
      _currencyConverter ?? ConfigurableCurrencyConverter();

  @override
  double calculateSubtotal(List<OrderItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  @override
  double applyMarkup(double subtotal, ProductLanguage language) {
    return switch (language) {
      ProductLanguage.chinese => subtotal * (1 + chineseKoreanMarkupRate),
      ProductLanguage.korean => subtotal * (1 + chineseKoreanMarkupRate),
      ProductLanguage.japanese => subtotal, // No markup for JPN
    };
  }

  @override
  OrderPricing calculateFinalPrice({
    required List<OrderItem> items,
    required ProductLanguage language,
  }) {
    final subtotal = calculateSubtotal(items);
    final withMarkup = applyMarkup(subtotal, language);
    final markupAmount = withMarkup - subtotal;

    // JPN tariff is already included in the unit prices (UsdWithTariff)
    // CN/KR tariff is baked into shipping, not a separate line item
    const estimatedTariff = 0.0;

    return OrderPricing(
      subtotal: subtotal,
      markup: markupAmount,
      estimatedTariff: estimatedTariff,
      total: withMarkup + estimatedTariff,
    );
  }

  @override
  double resolveProductPrice(
    Product product, {
    String? productType,
  }) {
    // For JPN products with a type selector
    if (product.language == ProductLanguage.japanese && productType != null) {
      final (usdPrice, usdWithTariffPrice, jpyPrice) = switch (productType) {
        'box' => (
            product.boxPriceUsd,
            product.boxPriceUsdWithTariff,
            product.boxPriceJpy
          ),
        'no_shrink' => (
            product.noShrinkPriceUsd,
            product.noShrinkPriceUsdWithTariff,
            product.noShrinkPriceJpy
          ),
        'case' => (
            product.casePriceUsd,
            product.casePriceUsdWithTariff,
            product.casePriceJpy
          ),
        _ => (null, null, null),
      };

      // Prefer USD with tariff, then USD, then convert from JPY
      if (usdWithTariffPrice != null) return usdWithTariffPrice;
      if (usdPrice != null) return usdPrice;
      if (jpyPrice != null) return _converter.convertToUsd(jpyPrice, 'JPY');
    }

    // For JPN products without a type, try to convert basePrice from JPY
    if (product.language == ProductLanguage.japanese &&
        product.basePrice > 100) {
      // Heuristic: if basePrice > 100, it's likely in JPY (USD prices rarely > $100)
      // This is a fallback; properly tagged products use the type-specific prices
      return _converter.convertToUsd(product.basePrice, 'JPY');
    }

    return product.basePrice;
  }
}
