import 'package:dart_firebase_admin/firestore.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';

import '../utils/firestore_helpers.dart';

class UserService {
  final Firestore _firestore;

  UserService(this._firestore);

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  /// Get a user by ID
  Future<Map<String, dynamic>?> getUser(String userId) async {
    final doc = await _usersRef.doc(userId).get();
    if (!doc.exists) return null;
    final data = sanitizeDoc(doc.data()!);
    data['id'] = doc.id;
    return data;
  }

  /// Update user profile fields (discordName, phone, etc.)
  Future<void> updateProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    final allowed = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp,
    };

    // Only allow specific profile fields
    const allowedFields = [
      'discordName',
      'phone',
      'preferredPaymentMethod',
      'wiseEmail',
      'venmoHandle',
      'paypalEmail',
      'savedAddress',
    ];

    for (final field in allowedFields) {
      if (updates.containsKey(field)) {
        allowed[field] = updates[field];
      }
    }

    try {
      await _usersRef.doc(userId).update(allowed);
    } catch (e) {
      // If doc doesn't exist yet, create it
      allowed['createdAt'] = FieldValue.serverTimestamp;
      await _usersRef.doc(userId).set(allowed);
    }
  }

  /// List all users, optionally filtered by role.
  Future<List<Map<String, dynamic>>> listUsers({UserRole? roleFilter}) async {
    Query<Map<String, dynamic>> query = _usersRef;

    if (roleFilter != null) {
      query = query.where('role', WhereFilter.equal, roleFilter.name);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = sanitizeDoc(doc.data());
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// Assign (or clear) an account manager for a user.
  Future<void> assignAccountManager(
    String userId,
    String? accountManagerId,
  ) async {
    await _usersRef.doc(userId).update({
      'accountManagerId': accountManagerId ?? FieldValue.delete,
      'updatedAt': FieldValue.serverTimestamp,
    });
  }

  /// Create or update a user doc from Shopify import.
  /// Returns 'created' or 'updated'.
  Future<String> upsertFromShopifyImport({
    required String firestoreUserId,
    required String email,
    ShippingAddress? address,
  }) async {
    final docRef = _usersRef.doc(firestoreUserId);
    final doc = await docRef.get();

    if (doc.exists) {
      final updates = <String, dynamic>{
        'shopifySyncAt': FieldValue.serverTimestamp,
        'updatedAt': FieldValue.serverTimestamp,
      };
      if (address != null) {
        updates['savedAddress'] = address.toJson();
      }
      await docRef.update(updates);
      return 'updated';
    } else {
      await docRef.set({
        'email': email,
        'role': UserRole.wholesaler.name,
        if (address != null) 'savedAddress': address.toJson(),
        'shopifySyncAt': FieldValue.serverTimestamp,
        'createdAt': FieldValue.serverTimestamp,
        'updatedAt': FieldValue.serverTimestamp,
      });
      return 'created';
    }
  }

  Future<void> updateUserFromShopify({
    required String userId,
    required UserRole role,
    required ShippingAddress address,
  }) async {
    final userRef = _usersRef.doc(userId);

    try {
      await userRef.update({
        'role': role.name,
        'savedAddress': address.toJson(),
        'shopifySyncAt': FieldValue.serverTimestamp,
      });
    } catch (e) {
      // If update fails (doc doesn't exist), create it
      await userRef.set({
        'role': role.name,
        'savedAddress': address.toJson(),
        'shopifySyncAt': FieldValue.serverTimestamp,
        'createdAt': FieldValue.serverTimestamp,
      });
    }
  }
}
