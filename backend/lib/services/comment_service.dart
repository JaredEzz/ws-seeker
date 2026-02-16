/// Comment Service for Firestore subcollection operations
library;

import 'package:dart_firebase_admin/firestore.dart';

class CommentService {
  final Firestore _firestore;

  CommentService(this._firestore);

  /// Get the comments subcollection reference for an order
  CollectionReference<Map<String, dynamic>> _commentsRef(String orderId) =>
      _firestore.collection('orders').doc(orderId).collection('comments');

  /// Add a comment to an order's subcollection
  Future<Map<String, dynamic>> addComment({
    required String orderId,
    required String userId,
    required String userName,
    required String content,
    bool isInternal = false,
  }) async {
    if (content.trim().isEmpty) {
      throw ArgumentError('Comment content cannot be empty');
    }

    // Verify order exists
    final orderDoc = await _firestore.collection('orders').doc(orderId).get();
    if (!orderDoc.exists) {
      throw ArgumentError('Order not found: $orderId');
    }

    final now = DateTime.now().toUtc();
    final commentData = {
      'orderId': orderId,
      'userId': userId,
      'userName': userName,
      'content': content.trim(),
      'isInternal': isInternal,
      'createdAt': FieldValue.serverTimestamp,
    };

    final docRef = await _commentsRef(orderId).add(commentData);

    return {
      'id': docRef.id,
      ...commentData,
      'createdAt': now.toIso8601String(),
    };
  }

  /// Get all comments for an order, ordered by creation time
  Future<List<Map<String, dynamic>>> getComments(String orderId) async {
    final snapshot = await _commentsRef(orderId)
        .orderBy('createdAt')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }
}
