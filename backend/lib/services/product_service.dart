/// Product Service for Firestore operations
library;

import 'package:dart_firebase_admin/firestore.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';

import '../utils/firestore_helpers.dart';

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
  /// - Fall back to name+language dedup for products without SKU
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

        // Try dedup by SKU first, then fall back to name+language
        QuerySnapshot<Map<String, dynamic>>? existingQuery;
        if (row.sku != null && row.sku!.isNotEmpty) {
          existingQuery = await _productsRef
              .where('sku', WhereFilter.equal, row.sku)
              .where('language', WhereFilter.equal, language.name)
              .get();
        }
        if (existingQuery == null || existingQuery.docs.isEmpty) {
          existingQuery = await _productsRef
              .where('name', WhereFilter.equal, row.name)
              .where('language', WhereFilter.equal, language.name)
              .get();
        }

        final extFields = _extendedFieldsFromRow(row);

        if (existingQuery.docs.isNotEmpty) {
          final docId = existingQuery.docs.first.id;
          await _productsRef.doc(docId).update({
            'name': row.name,
            'basePrice': row.price,
            'description': row.description,
            ...extFields,
            'updatedAt': FieldValue.serverTimestamp,
          });
          updated++;
        } else {
          await _productsRef.add({
            'name': row.name,
            'language': language.name,
            'basePrice': row.price,
            'description': row.description,
            'sku': row.sku,
            'isActive': true,
            ...extFields,
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
      final data = sanitizeDoc(doc.data());
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
    double? boxPriceJpy,
    double? noShrinkPriceJpy,
    double? casePriceJpy,
    double? boxPriceUsd,
    double? boxPriceUsdWithTariff,
    double? noShrinkPriceUsd,
    double? noShrinkPriceUsdWithTariff,
    double? casePriceUsd,
    double? casePriceUsdWithTariff,
    String? category,
    String? specifications,
    String? notes,
    bool quoteRequired = false,
    double? exchangeRateUsed,
  }) async {
    final docRef = await _productsRef.add({
      'name': name,
      'language': language.name,
      'basePrice': basePrice,
      'description': description,
      'imageUrl': imageUrl,
      'sku': sku,
      'isActive': true,
      if (boxPriceJpy != null) 'boxPriceJpy': boxPriceJpy,
      if (noShrinkPriceJpy != null) 'noShrinkPriceJpy': noShrinkPriceJpy,
      if (casePriceJpy != null) 'casePriceJpy': casePriceJpy,
      if (boxPriceUsd != null) 'boxPriceUsd': boxPriceUsd,
      if (boxPriceUsdWithTariff != null) 'boxPriceUsdWithTariff': boxPriceUsdWithTariff,
      if (noShrinkPriceUsd != null) 'noShrinkPriceUsd': noShrinkPriceUsd,
      if (noShrinkPriceUsdWithTariff != null) 'noShrinkPriceUsdWithTariff': noShrinkPriceUsdWithTariff,
      if (casePriceUsd != null) 'casePriceUsd': casePriceUsd,
      if (casePriceUsdWithTariff != null) 'casePriceUsdWithTariff': casePriceUsdWithTariff,
      if (exchangeRateUsed != null) 'exchangeRateUsed': exchangeRateUsed,
      if (category != null) 'category': category,
      if (specifications != null) 'specifications': specifications,
      if (notes != null) 'notes': notes,
      'quoteRequired': quoteRequired,
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
    double? boxPriceJpy,
    double? noShrinkPriceJpy,
    double? casePriceJpy,
    double? boxPriceUsd,
    double? boxPriceUsdWithTariff,
    double? noShrinkPriceUsd,
    double? noShrinkPriceUsdWithTariff,
    double? casePriceUsd,
    double? casePriceUsdWithTariff,
    String? category,
    String? specifications,
    String? notes,
    bool? quoteRequired,
    double? exchangeRateUsed,
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
    if (boxPriceJpy != null) updates['boxPriceJpy'] = boxPriceJpy;
    if (noShrinkPriceJpy != null) updates['noShrinkPriceJpy'] = noShrinkPriceJpy;
    if (casePriceJpy != null) updates['casePriceJpy'] = casePriceJpy;
    if (boxPriceUsd != null) updates['boxPriceUsd'] = boxPriceUsd;
    if (boxPriceUsdWithTariff != null) updates['boxPriceUsdWithTariff'] = boxPriceUsdWithTariff;
    if (noShrinkPriceUsd != null) updates['noShrinkPriceUsd'] = noShrinkPriceUsd;
    if (noShrinkPriceUsdWithTariff != null) updates['noShrinkPriceUsdWithTariff'] = noShrinkPriceUsdWithTariff;
    if (casePriceUsd != null) updates['casePriceUsd'] = casePriceUsd;
    if (casePriceUsdWithTariff != null) updates['casePriceUsdWithTariff'] = casePriceUsdWithTariff;
    if (exchangeRateUsed != null) updates['exchangeRateUsed'] = exchangeRateUsed;
    if (category != null) updates['category'] = category;
    if (specifications != null) updates['specifications'] = specifications;
    if (notes != null) updates['notes'] = notes;
    if (quoteRequired != null) updates['quoteRequired'] = quoteRequired;

    await _productsRef.doc(productId).update(updates);
  }

  /// Delete (soft-delete) a product
  Future<void> deleteProduct(String productId) async {
    await _productsRef.doc(productId).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp,
    });
  }

  /// Build a map of extended fields from an import row
  Map<String, dynamic> _extendedFieldsFromRow(ProductImportRow row) {
    return {
      if (row.boxPriceJpy != null) 'boxPriceJpy': row.boxPriceJpy,
      if (row.noShrinkPriceJpy != null) 'noShrinkPriceJpy': row.noShrinkPriceJpy,
      if (row.casePriceJpy != null) 'casePriceJpy': row.casePriceJpy,
      if (row.boxPriceUsd != null) 'boxPriceUsd': row.boxPriceUsd,
      if (row.boxPriceUsdWithTariff != null) 'boxPriceUsdWithTariff': row.boxPriceUsdWithTariff,
      if (row.noShrinkPriceUsd != null) 'noShrinkPriceUsd': row.noShrinkPriceUsd,
      if (row.noShrinkPriceUsdWithTariff != null) 'noShrinkPriceUsdWithTariff': row.noShrinkPriceUsdWithTariff,
      if (row.casePriceUsd != null) 'casePriceUsd': row.casePriceUsd,
      if (row.casePriceUsdWithTariff != null) 'casePriceUsdWithTariff': row.casePriceUsdWithTariff,
      if (row.category != null) 'category': row.category,
      if (row.specifications != null) 'specifications': row.specifications,
      if (row.notes != null) 'notes': row.notes,
      if (row.imageUrl != null) 'imageUrl': row.imageUrl,
      'quoteRequired': row.quoteRequired,
    };
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
