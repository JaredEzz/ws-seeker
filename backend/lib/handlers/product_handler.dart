/// Product API Handler
library;

import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';

import '../middleware/auth_middleware.dart';
import '../services/product_service.dart';

class ProductHandler {
  final ProductService _productService;

  ProductHandler({required ProductService productService})
      : _productService = productService;

  Router get router {
    final router = Router();

    // GET /api/products?language=japanese
    router.get('/', _getProducts);

    // POST /api/products - Create single product
    router.post('/', _createProduct);

    // POST /api/products/import - Bulk import products
    router.post('/import', _importProducts);

    // PUT /api/products/<id> - Update product
    router.put('/<id>', _updateProduct);

    // DELETE /api/products/<id> - Soft delete product
    router.delete('/<id>', _deleteProduct);

    return router;
  }

  /// GET /api/products?language=japanese
  Future<Response> _getProducts(Request request) async {
    final languageParam = request.url.queryParameters['language'];

    if (languageParam == null) {
      return Response(400,
          body: jsonEncode({'error': 'language query parameter is required'}),
          headers: {'Content-Type': 'application/json'});
    }

    final language = _parseLanguage(languageParam);
    if (language == null) {
      return Response(400,
          body: jsonEncode({'error': 'Invalid language: $languageParam'}),
          headers: {'Content-Type': 'application/json'});
    }

    try {
      final products = await _productService.getProducts(language);
      return Response.ok(
        jsonEncode({'products': products}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch products: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// Check if user has admin role (super_user or supplier)
  Response? _requireAdmin(Request request) {
    final role = request.context[AuthContext.userRole] as UserRole?;
    if (role != UserRole.superUser && role != UserRole.supplier) {
      return Response(403,
          body: jsonEncode({'error': 'Admin access required'}),
          headers: {'Content-Type': 'application/json'});
    }
    return null;
  }

  /// POST /api/products
  /// Body: { name, language, basePrice, description?, imageUrl?, sku? }
  Future<Response> _createProduct(Request request) async {
    final denied = _requireAdmin(request);
    if (denied != null) return denied;
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final name = data['name'] as String?;
      final languageStr = data['language'] as String?;
      final basePrice = (data['basePrice'] as num?)?.toDouble();

      if (name == null || languageStr == null || basePrice == null) {
        return Response(400,
            body: jsonEncode(
                {'error': 'name, language, and basePrice are required'}),
            headers: {'Content-Type': 'application/json'});
      }

      final language = _parseLanguage(languageStr);
      if (language == null) {
        return Response(400,
            body: jsonEncode({'error': 'Invalid language: $languageStr'}),
            headers: {'Content-Type': 'application/json'});
      }

      final productId = await _productService.createProduct(
        name: name,
        language: language,
        basePrice: basePrice,
        description: data['description'] as String?,
        imageUrl: data['imageUrl'] as String?,
        sku: data['sku'] as String?,
      );

      return Response(201,
          body: jsonEncode({'id': productId, 'message': 'Product created'}),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to create product: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// POST /api/products/import
  /// Body: { products: [{ name, language, price, description?, sku? }, ...] }
  Future<Response> _importProducts(Request request) async {
    final denied = _requireAdmin(request);
    if (denied != null) return denied;
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final productsData = data['products'] as List<dynamic>?;
      if (productsData == null || productsData.isEmpty) {
        return Response(400,
            body: jsonEncode({'error': 'products array is required'}),
            headers: {'Content-Type': 'application/json'});
      }

      final rows = productsData.map((p) {
        final item = p as Map<String, dynamic>;
        return ProductImportRow(
          name: item['name'] as String,
          language: item['language'] as String,
          price: (item['price'] as num).toDouble(),
          description: item['description'] as String?,
          sku: item['sku'] as String?,
        );
      }).toList();

      final result = await _productService.importProducts(rows);

      return Response.ok(
        jsonEncode(result.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to import products: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// PUT /api/products/<id>
  Future<Response> _updateProduct(Request request, String id) async {
    final denied = _requireAdmin(request);
    if (denied != null) return denied;
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      await _productService.updateProduct(
        id,
        name: data['name'] as String?,
        basePrice: (data['basePrice'] as num?)?.toDouble(),
        description: data['description'] as String?,
        imageUrl: data['imageUrl'] as String?,
        sku: data['sku'] as String?,
        isActive: data['isActive'] as bool?,
      );

      return Response.ok(
        jsonEncode({'message': 'Product updated'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to update product: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// DELETE /api/products/<id>
  Future<Response> _deleteProduct(Request request, String id) async {
    final denied = _requireAdmin(request);
    if (denied != null) return denied;
    try {
      await _productService.deleteProduct(id);
      return Response.ok(
        jsonEncode({'message': 'Product deleted'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to delete product: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
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
