import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:ws_seeker_shared/ws_seeker_shared.dart';

abstract interface class ProductRepository {
  Future<List<Product>> getProducts(ProductLanguage language);
  Future<Product> createProduct(Map<String, dynamic> data);
  Future<void> updateProduct(String id, Map<String, dynamic> data);
  Future<void> deleteProduct(String id);
  Future<Map<String, dynamic>> importProducts(List<ProductImportRow> rows);
}

/// HTTP-based product repository that calls the backend API
class HttpProductRepository implements ProductRepository {
  final String _baseUrl;

  HttpProductRepository({String? baseUrl})
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
  Future<List<Product>> getProducts(ProductLanguage language) async {
    final uri = Uri.parse('$_baseUrl${ApiRoutes.products}')
        .replace(queryParameters: {'language': language.name});

    final response = await http.get(uri, headers: await _authHeaders);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch products: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final productsJson = data['products'] as List<dynamic>;

    return productsJson
        .map((json) => _productFromMap(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Product> createProduct(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl${ApiRoutes.products}'),
      headers: await _authHeaders,
      body: jsonEncode(data),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create product: ${response.body}');
    }

    final result = jsonDecode(response.body) as Map<String, dynamic>;
    // Backend returns {id, message} — build a Product from the input + id
    return Product(
      id: result['id'] as String,
      name: data['name'] as String,
      language: ProductLanguage.values.firstWhere(
        (l) => l.name == data['language'],
      ),
      basePrice: (data['basePrice'] as num).toDouble(),
      description: data['description'] as String?,
      imageUrl: data['imageUrl'] as String?,
      sku: data['sku'] as String?,
      boxPriceJpy: (data['boxPriceJpy'] as num?)?.toDouble(),
      noShrinkPriceJpy: (data['noShrinkPriceJpy'] as num?)?.toDouble(),
      casePriceJpy: (data['casePriceJpy'] as num?)?.toDouble(),
      boxPriceUsd: (data['boxPriceUsd'] as num?)?.toDouble(),
      boxPriceUsdWithTariff: (data['boxPriceUsdWithTariff'] as num?)?.toDouble(),
      noShrinkPriceUsd: (data['noShrinkPriceUsd'] as num?)?.toDouble(),
      noShrinkPriceUsdWithTariff: (data['noShrinkPriceUsdWithTariff'] as num?)?.toDouble(),
      casePriceUsd: (data['casePriceUsd'] as num?)?.toDouble(),
      casePriceUsdWithTariff: (data['casePriceUsdWithTariff'] as num?)?.toDouble(),
      category: data['category'] as String?,
      specifications: data['specifications'] as String?,
      notes: data['notes'] as String?,
      quoteRequired: data['quoteRequired'] as bool? ?? false,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$_baseUrl${ApiRoutes.products}/$id'),
      headers: await _authHeaders,
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update product: ${response.body}');
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl${ApiRoutes.products}/$id'),
      headers: await _authHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete product: ${response.body}');
    }
  }

  @override
  Future<Map<String, dynamic>> importProducts(List<ProductImportRow> rows) async {
    final response = await http.post(
      Uri.parse('$_baseUrl${ApiRoutes.products}/import'),
      headers: await _authHeaders,
      body: jsonEncode({
        'products': rows.map((p) => p.toJson()).toList(),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to import products: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Product _productFromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      language: ProductLanguage.values.firstWhere(
        (l) => l.name == map['language'],
      ),
      basePrice: (map['basePrice'] as num).toDouble(),
      description: map['description'] as String?,
      imageUrl: map['imageUrl'] as String?,
      sku: map['sku'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      boxPriceJpy: (map['boxPriceJpy'] as num?)?.toDouble(),
      noShrinkPriceJpy: (map['noShrinkPriceJpy'] as num?)?.toDouble(),
      casePriceJpy: (map['casePriceJpy'] as num?)?.toDouble(),
      boxPriceUsd: (map['boxPriceUsd'] as num?)?.toDouble(),
      boxPriceUsdWithTariff: (map['boxPriceUsdWithTariff'] as num?)?.toDouble(),
      noShrinkPriceUsd: (map['noShrinkPriceUsd'] as num?)?.toDouble(),
      noShrinkPriceUsdWithTariff: (map['noShrinkPriceUsdWithTariff'] as num?)?.toDouble(),
      casePriceUsd: (map['casePriceUsd'] as num?)?.toDouble(),
      casePriceUsdWithTariff: (map['casePriceUsdWithTariff'] as num?)?.toDouble(),
      category: map['category'] as String?,
      specifications: map['specifications'] as String?,
      notes: map['notes'] as String?,
      quoteRequired: map['quoteRequired'] as bool? ?? false,
      updatedAt: _parseDateTime(map['updatedAt']),
    );
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

  @override
  Future<Product> createProduct(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return Product(
      id: 'p-new-${DateTime.now().millisecondsSinceEpoch}',
      name: data['name'] as String,
      language: ProductLanguage.values.firstWhere(
        (l) => l.name == data['language'],
      ),
      basePrice: (data['basePrice'] as num).toDouble(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> deleteProduct(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<Map<String, dynamic>> importProducts(List<ProductImportRow> rows) async {
    await Future.delayed(const Duration(seconds: 1));
    return {'created': rows.length, 'updated': 0, 'failed': 0, 'errors': []};
  }
}
