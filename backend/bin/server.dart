/// WS-Seeker Backend Server
/// 
/// Entry point for Cloud Run deployment
library;

import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import 'package:dart_firebase_admin/dart_firebase_admin.dart';
import 'package:dart_firebase_admin/auth.dart';
import 'package:dart_firebase_admin/firestore.dart';
import 'package:ws_seeker_backend/handlers/auth_handler.dart';
import 'package:ws_seeker_backend/handlers/sync_handler.dart';
import 'package:ws_seeker_backend/handlers/product_handler.dart';
import 'package:ws_seeker_backend/handlers/orders_handler.dart';
import 'package:ws_seeker_backend/services/shopify_service.dart';
import 'package:ws_seeker_backend/services/user_service.dart';
import 'package:ws_seeker_backend/services/product_service.dart';
import 'package:ws_seeker_backend/services/auth_service.dart';
import 'package:ws_seeker_backend/services/order_service.dart';
import 'package:ws_seeker_backend/services/comment_service.dart';
import 'package:ws_seeker_backend/services/invoice_service.dart';
import 'package:ws_seeker_backend/handlers/invoices_handler.dart';
import 'package:ws_seeker_backend/middleware/auth_middleware.dart';

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

  // Initialize Firebase Auth
  final auth = Auth(admin);

  // Initialize Services
  final shopifyService = ShopifyService();
  final userService = UserService(firestore);
  final productService = ProductService(firestore);
  final orderService = OrderService(firestore);
  final commentService = CommentService(firestore);
  final invoiceService = InvoiceService(firestore);
  final authService = AuthService(
    admin,
    firestore,
    resendApiKey: resendApiKey,
    fromEmail: fromEmail,
    baseUrl: baseUrl,
    shopifyService: shopifyService,
    userService: userService,
  );

  // Initialize Handlers
  final syncHandler = SyncHandler(
    shopifyService: shopifyService, 
    userService: userService,
  );
  final productHandler = ProductHandler(productService: productService);
  final ordersHandler = OrdersHandler(
    orderService: orderService,
    commentService: commentService,
  );
  final invoicesHandler = InvoicesHandler(invoiceService: invoiceService);
  final authHandler = AuthHandler(authService);

  final router = Router();

  // Health check endpoint
  router.get('/health', (Request request) {
    return Response.ok('OK');
  });

  // Public API Handlers (no auth required)
  router.mount('/api/auth', authHandler.router.call);

  // Protected routes (require auth)
  final authMw = authMiddleware(auth, firestore);

  final protectedSync = const Pipeline()
      .addMiddleware(authMw)
      .addHandler(syncHandler.router.call);
  router.mount('/api/sync', protectedSync);

  final protectedProducts = const Pipeline()
      .addMiddleware(authMw)
      .addHandler(productHandler.router.call);
  router.mount('/api/products', protectedProducts);
  final protectedOrders = const Pipeline()
      .addMiddleware(authMw)
      .addHandler(ordersHandler.router.call);
  router.mount('/api/orders', protectedOrders);

  final protectedInvoices = const Pipeline()
      .addMiddleware(authMw)
      .addHandler(invoicesHandler.router.call);
  router.mount('/api/invoices', protectedInvoices);


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
