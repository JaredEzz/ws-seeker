import 'package:ws_seeker_shared/ws_seeker_shared.dart';

abstract interface class ProductRepository {
  Future<List<Product>> getProducts(ProductLanguage language);
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
