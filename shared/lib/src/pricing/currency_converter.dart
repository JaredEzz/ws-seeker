/// Currency conversion service
///
/// Provides JPY→USD conversion with configurable rates.
/// Uses a fallback rate when no live rate is available.
library;

/// Currency conversion interface
abstract interface class CurrencyConverter {
  /// Convert amount from source currency to USD
  double convertToUsd(double amount, String sourceCurrency);

  /// Get current exchange rate to USD
  double getRate(String sourceCurrency);

  /// Update the exchange rate for a currency
  void setRate(String sourceCurrency, double rateToUsd);
}

/// Configurable currency converter with fallback rates.
///
/// Rates can be updated at runtime (e.g., from an admin setting
/// or periodic API fetch). Falls back to reasonable defaults.
class ConfigurableCurrencyConverter implements CurrencyConverter {
  ConfigurableCurrencyConverter({
    Map<String, double>? initialRates,
  }) : _rates = Map.from(initialRates ?? _defaultRates);

  /// Default fallback rates (1 unit → USD)
  static const _defaultRates = {
    'JPY': 0.0067, // ~150 JPY = 1 USD
    'CNY': 0.14, // ~7 CNY = 1 USD
    'KRW': 0.00075, // ~1330 KRW = 1 USD
  };

  final Map<String, double> _rates;

  @override
  double convertToUsd(double amount, String sourceCurrency) {
    if (sourceCurrency == 'USD') return amount;
    return amount * getRate(sourceCurrency);
  }

  @override
  double getRate(String sourceCurrency) {
    return _rates[sourceCurrency.toUpperCase()] ?? 1.0;
  }

  @override
  void setRate(String sourceCurrency, double rateToUsd) {
    _rates[sourceCurrency.toUpperCase()] = rateToUsd;
  }
}
