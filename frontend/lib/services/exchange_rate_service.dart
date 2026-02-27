/// Frontend Exchange Rate Service — calls backend exchange rate endpoint
library;

import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:ws_seeker_shared/ws_seeker_shared.dart';

class ExchangeRateResult {
  final double rate;
  final DateTime fetchedAt;
  final String source;

  ExchangeRateResult({
    required this.rate,
    required this.fetchedAt,
    required this.source,
  });
}

class ExchangeRateService {
  final String _baseUrl;

  ExchangeRateService({String? baseUrl})
      : _baseUrl = baseUrl ?? AppConstants.apiBaseUrl;

  Future<Map<String, String>> get _authHeaders async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not authenticated');
    final token = await user.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Fetch JPY→USD exchange rate from the backend.
  Future<ExchangeRateResult> getRate({
    String from = 'JPY',
    String to = 'USD',
  }) async {
    final uri = Uri.parse('$_baseUrl${ApiRoutes.exchangeRate}')
        .replace(queryParameters: {'from': from, 'to': to});

    final response = await http.get(uri, headers: await _authHeaders);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch exchange rate: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return ExchangeRateResult(
      rate: (data['rate'] as num).toDouble(),
      fetchedAt: DateTime.parse(data['fetchedAt'] as String),
      source: data['source'] as String,
    );
  }
}
