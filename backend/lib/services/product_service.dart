/// Product Service for Firestore operations
library;

import 'package:dart_firebase_admin/firestore.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';

class ProductService {
  final Firestore _firestore;

  ProductService(this._firestore);

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _firestore.collection('products');

  /// Import products from a list of ProductImportRow
  /// 
  /// This will:
  /// - Create new products if SKU doesn't exist
  /// - Update existing products if SKU exists
  /// - Return a summary of operations
  Future<ProductImportResult> importProducts(List<ProductImportRow> rows) async {
    int created = 0;
    int updated = 0;
    int failed = 0;
    final errors = <String>[];

    for (final row in rows) {
      try {
        final language = _parseLanguage(row.language);
        if (language == null) {
          errors.add('Invalid language "${row.language}" for product "${row.name}"');
          failed++;
          continue;
        }

        // Check if product with same SKU and language exists
        final existingQuery = row.sku != null
            ? await _productsRef
                .where('sku', WhereFilter.equal, row.sku)
                .where('language', WhereFilter.equal, language.name)
                .get()
            : null;

        if (existingQuery != null && existingQuery.docs.isNotEmpty) {
          // Update existing product
          final docId = existingQuery.docs.first.id;
          await _productsRef.doc(docId).update({
            'name': row.name,
            'basePrice': row.price,
            'description': row.description,
            'updatedAt': FieldValue.serverTimestamp,
          });
          updated++;
        } else {
          // Create new product
          await _productsRef.add({
            'name': row.name,
            'language': language.name,
            'basePrice': row.price,
            'description': row.description,
            'sku': row.sku,
            'isActive': true,
            'updatedAt': FieldValue.serverTimestamp,
          });
          created++;
        }
      } catch (e) {
        errors.add('Error processing "${row.name}": $e');
        failed++;
      }
    }

    return ProductImportResult(
      created: created,
      updated: updated,
      failed: failed,
      errors: errors,
    );
  }

  /// Get all products for a language
  Future<List<Map<String, dynamic>>> getProducts(ProductLanguage language) async {
    final snapshot = await _productsRef
        .where('language', WhereFilter.equal, language.name)
        .where('isActive', WhereFilter.equal, true)
        .orderBy('name')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// Create a single product
  Future<String> createProduct({
    required String name,
    required ProductLanguage language,
    required double basePrice,
    String? description,
    String? imageUrl,
    String? sku,
  }) async {
    final docRef = await _productsRef.add({
      'name': name,
      'language': language.name,
      'basePrice': basePrice,
      'description': description,
      'imageUrl': imageUrl,
      'sku': sku,
      'isActive': true,
      'updatedAt': FieldValue.serverTimestamp,
    });
    return docRef.id;
  }

  /// Update a product
  Future<void> updateProduct(
    String productId, {
    String? name,
    double? basePrice,
    String? description,
    String? imageUrl,
    String? sku,
    bool? isActive,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp,
    };

    if (name != null) updates['name'] = name;
    if (basePrice != null) updates['basePrice'] = basePrice;
    if (description != null) updates['description'] = description;
    if (imageUrl != null) updates['imageUrl'] = imageUrl;
    if (sku != null) updates['sku'] = sku;
    if (isActive != null) updates['isActive'] = isActive;

    await _productsRef.doc(productId).update(updates);
  }

  /// Delete (soft-delete) a product
  Future<void> deleteProduct(String productId) async {
    await _productsRef.doc(productId).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp,
    });
  }

  ProductLanguage? _parseLanguage(String language) {
    final normalized = language.toLowerCase().trim();
    return switch (normalized) {
      'japanese' || 'jp' || 'jpn' || 'japan' => ProductLanguage.japanese,
      'chinese' || 'cn' || 'chn' || 'china' => ProductLanguage.chinese,
      'korean' || 'kr' || 'kor' || 'korea' => ProductLanguage.korean,
      _ => null,
    };
  }
}

/// Result of a product import operation
class ProductImportResult {
  final int created;
  final int updated;
  final int failed;
  final List<String> errors;

  ProductImportResult({
    required this.created,
    required this.updated,
    required this.failed,
    required this.errors,
  });

  Map<String, dynamic> toJson() => {
        'created': created,
        'updated': updated,
        'failed': failed,
        'errors': errors,
      };
}
