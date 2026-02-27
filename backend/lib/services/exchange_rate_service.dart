/// Exchange Rate Service — fetches live JPY→USD rates from Frankfurter API
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

class ExchangeRateResult {
  final double rate;
  final DateTime fetchedAt;
  final String source;

  ExchangeRateResult({
    required this.rate,
    required this.fetchedAt,
    required this.source,
  });

  Map<String, dynamic> toJson() => {
        'rate': rate,
        'fetchedAt': fetchedAt.toIso8601String(),
        'source': source,
      };
}

class ExchangeRateService {
  static const _fallbackRate = 0.0067;
  static const _cacheDuration = Duration(hours: 1);

  ExchangeRateResult? _cached;

  /// Fetch JPY→USD exchange rate with 1-hour cache.
  Future<ExchangeRateResult> getRate({
    String from = 'JPY',
    String to = 'USD',
  }) async {
    // Return cached result if still fresh
    if (_cached != null &&
        DateTime.now().difference(_cached!.fetchedAt) < _cacheDuration) {
      return _cached!;
    }

    try {
      final uri = Uri.parse(
        'https://api.frankfurter.app/latest?from=$from&to=$to',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rates = data['rates'] as Map<String, dynamic>;
        final rate = (rates[to] as num).toDouble();

        _cached = ExchangeRateResult(
          rate: rate,
          fetchedAt: DateTime.now(),
          source: 'frankfurter',
        );
        return _cached!;
      }
    } catch (_) {
      // Fall through to fallback
    }

    // Fallback rate
    return ExchangeRateResult(
      rate: _fallbackRate,
      fetchedAt: DateTime.now(),
      source: 'fallback',
    );
  }
}
