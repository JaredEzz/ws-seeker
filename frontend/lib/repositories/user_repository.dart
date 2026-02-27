import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:ws_seeker_shared/ws_seeker_shared.dart';

abstract interface class UserRepository {
  Future<AppUser> getProfile();
  Future<AppUser> updateProfile({
    String? discordName,
    String? phone,
    String? preferredPaymentMethod,
    String? wiseEmail,
    String? venmoHandle,
    String? paypalEmail,
    ShippingAddress? savedAddress,
  });
  Future<List<AppUser>> listUsers();
  Future<void> assignAccountManager(String userId, String? managerId);
  Future<({int created, int updated, int skipped})> syncShopifyUsers();
}

class HttpUserRepository implements UserRepository {
  final String _baseUrl;

  HttpUserRepository({String? baseUrl})
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

  @override
  Future<AppUser> getProfile() async {
    final response = await http.get(
      Uri.parse('$_baseUrl${ApiRoutes.userProfile}'),
      headers: await _authHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch profile: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return _userFromMap(data['user'] as Map<String, dynamic>);
  }

  @override
  Future<AppUser> updateProfile({
    String? discordName,
    String? phone,
    String? preferredPaymentMethod,
    String? wiseEmail,
    String? venmoHandle,
    String? paypalEmail,
    ShippingAddress? savedAddress,
  }) async {
    final body = <String, dynamic>{};
    if (discordName != null) body['discordName'] = discordName;
    if (phone != null) body['phone'] = phone;
    if (preferredPaymentMethod != null) {
      body['preferredPaymentMethod'] = preferredPaymentMethod;
    }
    if (wiseEmail != null) body['wiseEmail'] = wiseEmail;
    if (venmoHandle != null) body['venmoHandle'] = venmoHandle;
    if (paypalEmail != null) body['paypalEmail'] = paypalEmail;
    if (savedAddress != null) body['savedAddress'] = savedAddress.toJson();

    final response = await http.patch(
      Uri.parse('$_baseUrl${ApiRoutes.userProfile}'),
      headers: await _authHeaders,
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update profile: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return _userFromMap(data['user'] as Map<String, dynamic>);
  }

  @override
  Future<List<AppUser>> listUsers() async {
    final response = await http.get(
      Uri.parse('$_baseUrl${ApiRoutes.users}'),
      headers: await _authHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to list users: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final usersJson = data['users'] as List<dynamic>;
    return usersJson
        .map((json) => _userFromMap(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> assignAccountManager(String userId, String? managerId) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl${ApiRoutes.users}/$userId/account-manager'),
      headers: await _authHeaders,
      body: jsonEncode({'accountManagerId': managerId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to assign account manager: ${response.body}');
    }
  }

  @override
  Future<({int created, int updated, int skipped})> syncShopifyUsers() async {
    final response = await http.post(
      Uri.parse('$_baseUrl${ApiRoutes.shopifyImportAll}'),
      headers: await _authHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to sync Shopify users: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (
      created: data['created'] as int? ?? 0,
      updated: data['updated'] as int? ?? 0,
      skipped: data['skipped'] as int? ?? 0,
    );
  }

  AppUser _userFromMap(Map<String, dynamic> map) {
    ShippingAddress? savedAddress;
    if (map['savedAddress'] != null) {
      savedAddress = ShippingAddress.fromJson(
        Map<String, dynamic>.from(map['savedAddress'] as Map),
      );
    }

    return AppUser(
      id: map['id'] as String,
      email: map['email'] as String? ?? '',
      role: _parseRole(map['role'] as String?),
      savedAddress: savedAddress,
      discordName: map['discordName'] as String?,
      phone: map['phone'] as String?,
      preferredPaymentMethod: map['preferredPaymentMethod'] as String?,
      wiseEmail: map['wiseEmail'] as String?,
      venmoHandle: map['venmoHandle'] as String?,
      paypalEmail: map['paypalEmail'] as String?,
      accountManagerId: map['accountManagerId'] as String?,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  UserRole _parseRole(String? roleStr) {
    return switch (roleStr) {
      'wholesaler' => UserRole.wholesaler,
      'supplier' => UserRole.supplier,
      'super_user' || 'superUser' => UserRole.superUser,
      _ => UserRole.wholesaler,
    };
  }

  DateTime _parseDateTime(dynamic value) {
    if (value is String) return DateTime.parse(value);
    if (value is Map) {
      final seconds = value['_seconds'] as int? ?? 0;
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    }
    return DateTime.now();
  }
}
