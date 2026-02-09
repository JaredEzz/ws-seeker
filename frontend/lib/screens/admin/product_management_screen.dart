import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/product_repository.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  ProductLanguage _selectedLanguage = ProductLanguage.japanese;
  List<Product> _products = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final repo = context.read<ProductRepository>();
      final products = await repo.getProducts(_selectedLanguage);
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading products: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Implementation for manual product creation
        },
        label: const Text('Add Product'),
        icon: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buildLanguageSelector(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildProductList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SegmentedButton<ProductLanguage>(
        segments: const [
          ButtonSegment(value: ProductLanguage.japanese, label: Text('Japanese')),
          ButtonSegment(value: ProductLanguage.chinese, label: Text('Chinese')),
          ButtonSegment(value: ProductLanguage.korean, label: Text('Korean')),
        ],
        selected: {_selectedLanguage},
        onSelectionChanged: (value) {
          setState(() {
            _selectedLanguage = value.first;
          });
          _loadProducts();
        },
      ),
    );
  }

  Widget _buildProductList() {
    if (_products.isEmpty) {
      return const Center(child: Text('No products found in this catalog.'));
    }

    return ListView.builder(
      itemCount: _products.count,
      itemBuilder: (context, index) {
        final product = _products[index];
        return ListTile(
          title: Text(product.name),
          subtitle: Text('SKU: ${product.sku ?? "N/A"} | Price: \$${product.basePrice.toStringAsFixed(2)}'),
          trailing: IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Implementation for manual edit
            },
          ),
        );
      },
    );
  }
}
