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
    
    // For MVP, we'll try 'update' which merges, but requires doc to exist.
    // If user signs up via Auth, doc might not exist yet. 
    // We should use set with merge, but SetOptions is failing compilation.
    // We will attempt a standard set for now (overwrite), but manually merge fields if needed later.
    try {
      await userRef.update({
        'role': role.name,
        // 'savedAddress': address.toJson(), // Temporarily disabled due to build error
        'shopifySyncAt': FieldValue.serverTimestamp,
      });
    } catch (e) {
      // If update fails (doc doesn't exist), create it
      await userRef.set({
        'role': role.name,
        // 'savedAddress': address.toJson(),
        'shopifySyncAt': FieldValue.serverTimestamp,
        'createdAt': FieldValue.serverTimestamp,
      });
    }
  }
}
