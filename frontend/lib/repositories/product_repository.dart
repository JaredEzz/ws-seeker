import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';

abstract interface class ProductRepository {
  Future<List<Product>> getProducts(ProductLanguage language);
}

/// Firestore implementation of ProductRepository
/// 
/// Firestore structure:
/// products/
/// └── {productId}/
///     ├── name: string
///     ├── language: 'japanese' | 'chinese' | 'korean'
///     ├── basePrice: number
///     ├── description: string?
///     ├── imageUrl: string?
///     ├── sku: string?
///     ├── isActive: boolean
///     └── updatedAt: timestamp
class FirestoreProductRepository implements ProductRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _firestore.collection('products');

  @override
  Future<List<Product>> getProducts(ProductLanguage language) async {
    final snapshot = await _productsRef
        .where('language', isEqualTo: language.name)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Product(
        id: doc.id,
        name: data['name'] as String,
        language: ProductLanguage.values.firstWhere(
          (l) => l.name == data['language'],
        ),
        basePrice: (data['basePrice'] as num).toDouble(),
        description: data['description'] as String?,
        imageUrl: data['imageUrl'] as String?,
        sku: data['sku'] as String?,
        isActive: data['isActive'] as bool? ?? true,
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      );
    }).toList();
  }
}

class MockProductRepository implements ProductRepository {
  @override
  Future<List<Product>> getProducts(ProductLanguage language) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return List.generate(10, (index) => Product(
      id: 'p-$language-$index',
      name: '${language.name.toUpperCase()} Product $index',
      language: language,
      basePrice: 10.0 + index,
      description: 'Mock description for product $index',
      updatedAt: DateTime.now(),
    ));
  }
}
