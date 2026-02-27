import 'dart:convert';
import 'package:dart_firebase_admin/auth.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';
import '../middleware/auth_middleware.dart';
import '../services/shopify_service.dart';
import '../services/user_service.dart';

class SyncHandler {
  final ShopifyService _shopifyService;
  final UserService _userService;
  final Auth? _auth;

  SyncHandler({
    required ShopifyService shopifyService,
    required UserService userService,
    Auth? auth,
  })  : _shopifyService = shopifyService,
        _userService = userService,
        _auth = auth;

  Router get router {
    final router = Router();
    router.post('/shopify', _syncShopify);
    router.post('/shopify/import-all', _importAllShopify);
    return router;
  }

  Future<Response> _syncShopify(Request request) async {
    // Read userId and email from auth context (set by auth middleware)
    final userId = request.context[AuthContext.userId] as String?;
    final email = request.context[AuthContext.userEmail] as String?;

    if (userId == null || email == null || email.isEmpty) {
      return Response.badRequest(body: 'Missing userId or email in auth context');
    }

    // 2. Call Shopify
    if (!_shopifyService.isConfigured) {
      return Response.internalServerError(body: 'Shopify Sync not configured');
    }

    final result = await _shopifyService.getCustomerByEmail(email);

    if (result == null) {
      return Response.ok(jsonEncode({'synced': false, 'reason': 'Not found in Shopify'}));
    }

    // 3. Update Firestore
    await _userService.updateUserFromShopify(
      userId: userId,
      role: result.role,
      address: result.address,
    );

    return Response.ok(jsonEncode({
      'synced': true,
      'role': result.role.name,
    }));
  }

  /// POST /api/sync/shopify/import-all (superUser only)
  /// Imports all Shopify wholesale segment members into Firebase Auth + Firestore.
  Future<Response> _importAllShopify(Request request) async {
    final role = request.context[AuthContext.userRole] as UserRole?;
    if (role != UserRole.superUser) {
      return Response(403,
          body: jsonEncode({'error': 'Only super users can import users'}),
          headers: {'Content-Type': 'application/json'});
    }

    if (!_shopifyService.isConfigured) {
      return Response.internalServerError(
          body: jsonEncode({'error': 'Shopify not configured'}),
          headers: {'Content-Type': 'application/json'});
    }

    final auth = _auth;
    if (auth == null) {
      return Response.internalServerError(
          body: jsonEncode({'error': 'Firebase Auth not available'}),
          headers: {'Content-Type': 'application/json'});
    }

    try {
      final members =
          await _shopifyService.getAllSegmentMembers('Wholesale Members');

      var created = 0;
      var updated = 0;
      var skipped = 0;

      for (final member in members) {
        try {
          // Get or create Firebase Auth user
          String firebaseUid;
          try {
            final userRecord = await auth.getUserByEmail(member.email);
            firebaseUid = userRecord.uid;
          } catch (_) {
            // User doesn't exist in Firebase Auth — create
            final newUser = await auth.createUser(
              CreateRequest(email: member.email),
            );
            firebaseUid = newUser.uid;
          }

          // Upsert Firestore doc
          final result = await _userService.upsertFromShopifyImport(
            firestoreUserId: firebaseUid,
            email: member.email,
            address: member.address,
          );

          if (result == 'created') {
            created++;
          } else {
            updated++;
          }
        } catch (e) {
          print('Shopify import skipped ${member.email}: $e');
          skipped++;
        }
      }

      return Response.ok(jsonEncode({
        'created': created,
        'updated': updated,
        'skipped': skipped,
        'total': members.length,
      }), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': 'Shopify import failed: $e'}),
          headers: {'Content-Type': 'application/json'});
    }
  }
}
