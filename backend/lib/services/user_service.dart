import 'package:dart_firebase_admin/firestore.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';

class UserService {
  final Firestore _firestore;

  UserService(this._firestore);

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  /// Get a user by ID
  Future<Map<String, dynamic>?> getUser(String userId) async {
    final doc = await _usersRef.doc(userId).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
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
