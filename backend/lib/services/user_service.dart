import 'package:dart_firebase_admin/firestore.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';

class UserService {
  final Firestore _firestore;

  UserService(this._firestore);

  Future<void> updateUserFromShopify({
    required String userId,
    required UserRole role,
    required ShippingAddress address,
  }) async {
    final userRef = _firestore.collection('users').doc(userId);
    
    // We update role and address.
    // Note: We intentionally don't overwrite other fields like email/createdAt
    await userRef.set({
      'role': role.name, // Enum to string
      'savedAddress': address.toJson(),
      'shopifySyncAt': FieldValue.serverTimestamp,
    }, SetOptions(merge: true));
  }
}
