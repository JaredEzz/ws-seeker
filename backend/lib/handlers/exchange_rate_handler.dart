/// Exchange Rate API Handler
library;

import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../services/exchange_rate_service.dart';

class ExchangeRateHandler {
  final ExchangeRateService _service;

  ExchangeRateHandler({required ExchangeRateService service})
      : _service = service;

  Router get router {
    final router = Router();
    router.get('/', _getRate);
    return router;
  }

  /// GET /api/exchange-rate?from=JPY&to=USD
  Future<Response> _getRate(Request request) async {
    final from = request.url.queryParameters['from'] ?? 'JPY';
    final to = request.url.queryParameters['to'] ?? 'USD';

    try {
      final result = await _service.getRate(from: from, to: to);
      return Response.ok(
        jsonEncode(result.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch exchange rate: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
