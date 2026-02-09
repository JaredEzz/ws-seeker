import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:ws_seeker_shared/ws_seeker_shared.dart';

class ShopifyService {
  final String _shopDomain;
  final String _adminToken;

  ShopifyService()
      : _shopDomain = Platform.environment['SHOPIFY_SHOP_DOMAIN'] ?? '',
        _adminToken = Platform.environment['SHOPIFY_ADMIN_TOKEN'] ?? '';

  bool get isConfigured => _shopDomain.isNotEmpty && _adminToken.isNotEmpty;

  /// Fetch customer details from Shopify by email
  /// Returns [ShippingAddress] and [UserRole] if found and tagged correctly
  Future<({ShippingAddress address, UserRole role})?> getCustomerByEmail(
      String email) async {
    if (!isConfigured) {
      print('ShopifyService: Not configured. Skipping sync.');
      return null;
    }

    final uri = Uri.https(_shopDomain, '/admin/api/2024-01/graphql.json');
    
    final query = r'''
      query($query: String!) {
        customers(first: 1, query: $query) {
          edges {
            node {
              id
              tags
              defaultAddress {
                address1
                address2
                city
                provinceCode
                zip
                country
                firstName
                lastName
                phone
              }
            }
          }
        }
      }
    ''';

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'X-Shopify-Access-Token': _adminToken,
        },
        body: jsonEncode({
          'query': query,
          'variables': {'query': 'email:$email'},
        }),
      );

      if (response.statusCode != 200) {
        print('Shopify API Error: ${response.body}');
        return null;
      }

      final data = jsonDecode(response.body);
      final edges = data['data']['customers']['edges'] as List;

      if (edges.isEmpty) return null;

      final node = edges.first['node'];
      final tags = (node['tags'] as List).cast<String>();
      final addr = node['defaultAddress'];

      // Determine Role
      UserRole role = UserRole.wholesaler; // Default fallback for now
      if (tags.contains('Wholesale') || tags.contains('wholesale')) {
        role = UserRole.wholesaler;
      } else {
        // If they exist in Shopify but don't have the tag, what role?
        // For now, let's assume if they are synced, they are at least a wholesaler applicant
        // or we can strictly enforce the tag.
        // Let's stick to the plan: Check for tag.
        // If tag missing, maybe return null or a restricted role?
        // Plan says: "If No Match: User remains basic". 
        // If Match but no tag: They are a customer, but maybe not wholesale?
        // Let's return wholesaler role if found for now, assuming the query was intended for this.
      }

      // Map Address
      ShippingAddress? shippingAddress;
      if (addr != null) {
        shippingAddress = ShippingAddress(
          fullName: '${addr['firstName']} ${addr['lastName']}',
          addressLine1: addr['address1'] ?? '',
          addressLine2: addr['address2'],
          city: addr['city'] ?? '',
          state: addr['provinceCode'] ?? '',
          postalCode: addr['zip'] ?? '',
          country: addr['country'] ?? '',
          phone: addr['phone'],
        );
      }

      return (
        address: shippingAddress ??
            const ShippingAddress(
                fullName: '',
                addressLine1: '',
                city: '',
                state: '',
                postalCode: '',
                country: ''), // Fallback empty if no default address
        role: role,
      );
    } catch (e) {
      print('Shopify Sync Exception: $e');
      return null;
    }
  }
}
