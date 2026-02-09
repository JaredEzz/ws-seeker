import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/shopify_service.dart';
import '../services/user_service.dart';

class SyncHandler {
  final ShopifyService _shopifyService;
  final UserService _userService;

  SyncHandler({
    required ShopifyService shopifyService,
    required UserService userService,
  })  : _shopifyService = shopifyService,
        _userService = userService;

  Router get router {
    final router = Router();
    router.post('/shopify', _syncShopify);
    return router;
  }

  Future<Response> _syncShopify(Request request) async {
    // 1. Parse Request
    final body = await request.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;
    
    final userId = data['userId'] as String?;
    final email = data['email'] as String?;

    if (userId == null || email == null) {
      return Response.badRequest(body: 'Missing userId or email');
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
}
