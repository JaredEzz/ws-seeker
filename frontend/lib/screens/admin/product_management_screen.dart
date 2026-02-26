import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';
import '../../app/design_tokens.dart';
import '../../blocs/products/products_bloc.dart';
import '../../repositories/product_repository.dart';
import '../../widgets/navigation/admin_shell.dart';
import 'product_form_dialog.dart';
import 'product_import_dialog.dart';

class ProductManagementScreen extends StatelessWidget {
  const ProductManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProductsBloc(
        productRepository: context.read<ProductRepository>(),
      )..add(const ProductsFetchRequested(language: ProductLanguage.japanese)),
      child: const AdminShell(
        selectedIndex: 1,
        child: _ProductManagementContent(),
      ),
    );
  }
}

class _ProductManagementContent extends StatefulWidget {
  const _ProductManagementContent();

  @override
  State<_ProductManagementContent> createState() => _ProductManagementContentState();
}

class _ProductManagementContentState extends State<_ProductManagementContent> {
  ProductLanguage _selectedLanguage = ProductLanguage.japanese;

  void _onLanguageChanged(ProductLanguage language) {
    setState(() => _selectedLanguage = language);
    context.read<ProductsBloc>().add(ProductsFetchRequested(language: language));
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (_) => const ProductImportDialog(),
    ).then((_) {
      context.read<ProductsBloc>().add(
        ProductsFetchRequested(language: _selectedLanguage),
      );
    });
  }

  void _showCreateDialog() {
    showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => ProductFormDialog(defaultLanguage: _selectedLanguage),
    ).then((data) {
      if (data != null) {
        context.read<ProductsBloc>().add(ProductCreateRequested(data: data));
      }
    });
  }

  void _showEditDialog(Product product) {
    showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => ProductFormDialog(
        product: product,
        defaultLanguage: product.language,
      ),
    ).then((data) {
      if (data != null) {
        context.read<ProductsBloc>().add(
          ProductUpdateRequested(productId: product.id, data: data),
        );
      }
    });
  }

  void _confirmDelete(Product product) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Tokens.destructive),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        context.read<ProductsBloc>().add(
          ProductDeleteRequested(productId: product.id),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Import CSV',
            onPressed: _showImportDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ProductsBloc>().add(
              ProductsFetchRequested(language: _selectedLanguage),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Product'),
      ),
      body: Column(
        children: [
          _buildLanguageSelector(),
          Expanded(
            child: BlocConsumer<ProductsBloc, ProductsState>(
              listener: (context, state) {
                if (state is ProductActionSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
                if (state is ProductsFailure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Tokens.destructive,
                    ),
                  );
                }
              },
              builder: (context, state) => switch (state) {
                ProductsLoading() => const Center(child: CircularProgressIndicator()),
                ProductsLoaded(:final products) => products.isEmpty
                    ? _buildEmptyState()
                    : _buildProductList(products),
                ProductsFailure(:final message) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Tokens.destructive),
                        const SizedBox(height: 16),
                        Text(message, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => context.read<ProductsBloc>().add(
                            ProductsFetchRequested(language: _selectedLanguage),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                _ => const SizedBox.shrink(),
              },
            ),
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
        onSelectionChanged: (v) => _onLanguageChanged(v.first),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 64, color: Tokens.textTertiary),
          const SizedBox(height: 16),
          const Text(
            'No products found in this catalog.',
            style: TextStyle(fontSize: 16, color: Tokens.textTertiary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showImportDialog,
            icon: const Icon(Icons.upload_file),
            label: const Text('Import Products'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(List<Product> products) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _ProductCard(
          product: product,
          onEdit: () => _showEditDialog(product),
          onDelete: () => _confirmDelete(product),
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: Tokens.space8),
      child: Padding(
        padding: const EdgeInsets.all(Tokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (product.sku != null)
                        Text(
                          'SKU: ${product.sku}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Tokens.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                // Badges
                Wrap(
                  spacing: 6,
                  children: [
                    if (product.quoteRequired)
                      _badge('Ask for Quote', Tokens.feedbackWarningBg,
                          Tokens.feedbackWarningText),
                    if (product.category != null)
                      _badge(
                        product.category == 'official' ? 'Official' : 'Fan Art',
                        product.category == 'official'
                            ? Tokens.feedbackInfoBg
                            : const Color(0xFFF3E8FF),
                        product.category == 'official'
                            ? Tokens.feedbackInfoText
                            : const Color(0xFF6B21A8),
                      ),
                  ],
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: Tokens.space8),

            // Price information
            _buildPriceInfo(),

            // Specifications
            if (product.specifications != null) ...[
              const SizedBox(height: 6),
              Text(
                product.specifications!,
                style: const TextStyle(fontSize: 12, color: Tokens.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Notes
            if (product.notes != null) ...[
              const SizedBox(height: 4),
              Text(
                product.notes!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Tokens.feedbackWarningText,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriceInfo() {
    if (product.language == ProductLanguage.japanese) {
      return _buildJpnPrices();
    }
    // CN and KR: show base price
    return Text(
      '\$${product.basePrice.toStringAsFixed(2)}',
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Tokens.textPrimary,
      ),
    );
  }

  Widget _buildJpnPrices() {
    if (product.quoteRequired &&
        product.boxPriceUsd == null &&
        product.casePriceUsd == null) {
      return const Text(
        'Price: Ask for quote',
        style: TextStyle(fontSize: 14, color: Tokens.textSecondary),
      );
    }

    final chips = <Widget>[];

    if (product.boxPriceUsd != null) {
      chips.add(_priceChip('Box', product.boxPriceUsd!,
          tariff: product.boxPriceUsdWithTariff));
    }
    if (product.noShrinkPriceUsd != null) {
      chips.add(_priceChip('No Shrink', product.noShrinkPriceUsd!,
          tariff: product.noShrinkPriceUsdWithTariff));
    }
    if (product.casePriceUsd != null) {
      chips.add(_priceChip('Case', product.casePriceUsd!,
          tariff: product.casePriceUsdWithTariff));
    }

    if (chips.isEmpty && product.basePrice > 0) {
      return Text(
        '\$${product.basePrice.toStringAsFixed(2)}',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      );
    }

    return Wrap(spacing: Tokens.space8, runSpacing: 4, children: chips);
  }

  Widget _priceChip(String label, double price, {double? tariff}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Tokens.stone100,
        borderRadius: BorderRadius.circular(Tokens.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 10, color: Tokens.textSecondary)),
          Text('\$${price.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          if (tariff != null)
            Text('+tariff: \$${tariff.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 10, color: Tokens.textTertiary)),
        ],
      ),
    );
  }

  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w500)),
    );
  }
}
