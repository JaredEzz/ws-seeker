/// Currency conversion service
/// 
/// TODO(jules): Implement live currency conversion for Japanese Yen
library;

/// Currency conversion interface
abstract interface class CurrencyConverter {
  /// Convert amount from source currency to USD
  Future<double> convertToUsd(double amount, String sourceCurrency);
  
  /// Get current exchange rate
  Future<double> getExchangeRate(String sourceCurrency, String targetCurrency);
  
  /// Get cached/last known rate (for offline/fallback)
  double getCachedRate(String sourceCurrency, String targetCurrency);
}

/// Placeholder currency converter
/// 
/// TODO(jules): Implement with live exchange rate API
class PlaceholderCurrencyConverter implements CurrencyConverter {
  const PlaceholderCurrencyConverter();

  // Fallback rates (should be updated by Jules with live API)
  static const Map<String, double> _fallbackRatesToUsd = {
    'JPY': 0.0067, // ~150 JPY = 1 USD
    'CNY': 0.14,   // ~7 CNY = 1 USD
    'KRW': 0.00075, // ~1300 KRW = 1 USD
  };

  @override
  Future<double> convertToUsd(double amount, String sourceCurrency) async {
    final rate = await getExchangeRate(sourceCurrency, 'USD');
    return amount * rate;
  }

  @override
  Future<double> getExchangeRate(
    String sourceCurrency,
    String targetCurrency,
  ) async {
    // TODO(jules): Implement live exchange rate fetching
    if (targetCurrency == 'USD') {
      return _fallbackRatesToUsd[sourceCurrency] ?? 1.0;
    }
    return 1.0;
  }

  @override
  double getCachedRate(String sourceCurrency, String targetCurrency) {
    if (targetCurrency == 'USD') {
      return _fallbackRatesToUsd[sourceCurrency] ?? 1.0;
    }
    return 1.0;
  }
}
