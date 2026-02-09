/// WS-Seeker Backend Server
/// 
/// Entry point for Cloud Run deployment
library;

import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import 'package:dart_firebase_admin/dart_firebase_admin.dart';
import 'package:dart_firebase_admin/firestore.dart';
import 'package:ws_seeker_backend/handlers/auth_handler.dart';
import 'package:ws_seeker_backend/handlers/sync_handler.dart';
import 'package:ws_seeker_backend/handlers/product_handler.dart';
import 'package:ws_seeker_backend/services/shopify_service.dart';
import 'package:ws_seeker_backend/services/user_service.dart';
import 'package:ws_seeker_backend/services/product_service.dart';
import 'package:ws_seeker_backend/services/auth_service.dart';

void main() async {
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final resendApiKey = Platform.environment['RESEND_API_KEY'] ?? '';
  final fromEmail = Platform.environment['FROM_EMAIL'] ?? 'auth@ws-seeker.com';
  final baseUrl = Platform.environment['BASE_URL'] ?? 'https://ws-seeker.web.app';

  // Initialize Firebase Admin
  // Note: Ensure GOOGLE_APPLICATION_CREDENTIALS is set in dev/prod
  final admin = FirebaseAdminApp.initializeApp(
    'ws-seeker',
    Credential.fromApplicationDefaultCredentials(),
  );
  final firestore = Firestore(admin);

  // Initialize Services
  final shopifyService = ShopifyService();
  final userService = UserService(firestore);
  final productService = ProductService(firestore);
  final authService = AuthService(
    admin,
    firestore,
    resendApiKey: resendApiKey,
    fromEmail: fromEmail,
    baseUrl: baseUrl,
  );

  // Initialize Handlers
  final syncHandler = SyncHandler(
    shopifyService: shopifyService, 
    userService: userService,
  );
  final productHandler = ProductHandler(productService: productService);
  final authHandler = AuthHandler(authService);

  final router = Router();

  // Health check endpoint
  router.get('/health', (Request request) {
    return Response.ok('OK');
  });

  // Mount API Handlers
  router.mount('/api/auth', authHandler.router.call);
  router.mount('/api/sync', syncHandler.router.call);
  router.mount('/api/products', productHandler.router.call);

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
