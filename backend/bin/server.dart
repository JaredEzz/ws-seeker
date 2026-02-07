/// Chroma Wholesale Backend Server
/// 
/// Entry point for Cloud Run deployment
library;

import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

void main() async {
  final port = int.parse(Platform.environment['PORT'] ?? '8080');

  final router = Router();

  // Health check endpoint
  router.get('/health', (Request request) {
    return Response.ok('OK');
  });

  // TODO: Mount handlers here
  // router.mount('/auth', authHandler.router.call);
  // router.mount('/api/orders', ordersHandler.router.call);
  // router.mount('/api/products', productsHandler.router.call);

  // Apply middleware
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_corsMiddleware())
      .addHandler(router.call);

  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  
  print('Server running on http://${server.address.host}:${server.port}');
}

/// CORS middleware for development
Middleware _corsMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: _corsHeaders);
      }

      final response = await innerHandler(request);
      return response.change(headers: _corsHeaders);
    };
  };
}

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
};
