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
import 'package:ws_seeker_backend/services/email_service.dart';
import 'package:ws_seeker_backend/handlers/invoices_handler.dart';
import 'package:ws_seeker_backend/handlers/users_handler.dart';
import 'package:ws_seeker_backend/handlers/audit_handler.dart';
import 'package:ws_seeker_backend/handlers/exchange_rate_handler.dart';
import 'package:ws_seeker_backend/middleware/auth_middleware.dart';
import 'package:ws_seeker_backend/services/audit_service.dart';
import 'package:ws_seeker_backend/services/exchange_rate_service.dart';

void main() async {
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final resendApiKey = Platform.environment['RESEND_API_KEY'] ?? '';
  final fromEmail = Platform.environment['FROM_EMAIL'] ?? 'auth@ws-seeker.com';
  final baseUrl = Platform.environment['BASE_URL'] ?? 'https://ws-seeker.web.app';

  // Initialize Firebase Admin
  // Use service account JSON from env var if available (Cloud Run),
  // otherwise fall back to Application Default Credentials (local dev).
  final serviceAccountJson = Platform.environment['FIREBASE_SERVICE_ACCOUNT_JSON'];
  Credential credential;
  if (serviceAccountJson != null && serviceAccountJson.isNotEmpty) {
    final tmpFile = File('/tmp/firebase-sa.json');
    tmpFile.writeAsStringSync(serviceAccountJson);
    credential = Credential.fromServiceAccount(tmpFile);
  } else {
    credential = Credential.fromApplicationDefaultCredentials();
  }
  final admin = FirebaseAdminApp.initializeApp(
    'ws-seeker',
    credential,
  );
  final firestore = Firestore(admin);

  // Initialize Firebase Auth
  final auth = Auth(admin);

  // Initialize Audit Logging (Postgres via Neon)
  final auditDatabaseUrl = Platform.environment['AUDIT_DATABASE_URL'];
  final auditService = await AuditService.create(auditDatabaseUrl);

  // Initialize Services
  final shopifyService = ShopifyService();
  final userService = UserService(firestore);
  final productService = ProductService(firestore);
  final orderService = OrderService(firestore);
  final commentService = CommentService(firestore);
  final invoiceService = InvoiceService(firestore);
  final emailService = EmailService(
    resendApiKey: resendApiKey,
    fromEmail: fromEmail,
    appUrl: baseUrl,
  );
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
    auth: auth,
  );
  final productHandler = ProductHandler(
    productService: productService,
    auditService: auditService,
  );
  final ordersHandler = OrdersHandler(
    orderService: orderService,
    commentService: commentService,
    emailService: emailService,
    userService: userService,
    auditService: auditService,
  );
  final invoicesHandler = InvoicesHandler(
    invoiceService: invoiceService,
    auditService: auditService,
  );
  final usersHandler = UsersHandler(
    userService: userService,
    auditService: auditService,
  );
  final exchangeRateService = ExchangeRateService();
  final exchangeRateHandler = ExchangeRateHandler(service: exchangeRateService);
  final authHandler = AuthHandler(authService, auditService: auditService);
  final auditHandler = auditService != null
      ? AuditHandler(auditService: auditService)
      : null;

  final router = Router();

  // Health check endpoint
  router.get('/health', (Request request) {
    return Response.ok('OK');
  });

  // Public API Handlers (no auth required)
  router.mount('/api/auth', authHandler.router.call);

  // Protected routes (require auth)
  final authMw = authMiddleware(firestore, projectId: 'ws-seeker');

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

  final protectedUsers = const Pipeline()
      .addMiddleware(authMw)
      .addHandler(usersHandler.router.call);
  router.mount('/api/users', protectedUsers);

  final protectedExchangeRate = const Pipeline()
      .addMiddleware(authMw)
      .addHandler(exchangeRateHandler.router.call);
  router.mount('/api/exchange-rate', protectedExchangeRate);

  if (auditHandler != null) {
    final protectedAuditLogs = const Pipeline()
        .addMiddleware(authMw)
        .addHandler(auditHandler.router.call);
    router.mount('/api/audit-logs', protectedAuditLogs);
  }

  // Apply middleware
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_corsMiddleware())
      .addHandler(router.call);

  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);

  print('Server running on http://${server.address.host}:${server.port}');

  // Graceful shutdown
  ProcessSignal.sigterm.watch().listen((_) async {
    print('SIGTERM received, shutting down...');
    await server.close();
    await auditService?.close();
    exit(0);
  });
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
