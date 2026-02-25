import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/orders/order_form_bloc.dart';
import '../../blocs/orders/orders_bloc.dart';
import '../../repositories/order_repository.dart';
import '../../repositories/product_repository.dart';
import '../../widgets/forms/address_form.dart';

class OrderFormScreen extends StatelessWidget {
  const OrderFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = OrderFormBloc(
          productRepository: context.read<ProductRepository>(),
          orderRepository: context.read<OrderRepository>(),
        );
        // Pre-fill from user profile
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticated) {
          bloc.add(OrderFormProfileLoaded(authState.user));
        }
        return bloc;
      },
      child: const _OrderFormContent(),
    );
  }
}

class _OrderFormContent extends StatefulWidget {
  const _OrderFormContent();

  @override
  State<_OrderFormContent> createState() => _OrderFormContentState();
}

class _OrderFormContentState extends State<_OrderFormContent> {
  int _currentStep = 0;
  ShippingAddress? _shippingAddress;
  bool _addressInitialized = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Place Wholesale Order')),
      body: BlocConsumer<OrderFormBloc, OrderFormState>(
        listener: (context, state) {
          if (state.status == OrderFormStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Order placed successfully!')),
            );
            context.read<OrdersBloc>().add(const OrdersFetchRequested());
            context.go('/dashboard');
          }
          if (state.status == OrderFormStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.errorMessage}')),
            );
          }
          // Initialize address from profile once
          if (!_addressInitialized && state.prefillAddress != null) {
            _shippingAddress = state.prefillAddress;
            _addressInitialized = true;
          }
        },
        builder: (context, state) {
          return Stepper(
            currentStep: _currentStep,
            onStepContinue: () => _onStepContinue(context, state),
            onStepCancel: () {
              if (_currentStep > 0) {
                setState(() => _currentStep--);
              } else {
                Navigator.of(context).pop();
              }
            },
            controlsBuilder: (context, details) {
              final isLastStep = _currentStep == 2;
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    FilledButton(
                      onPressed: state.status == OrderFormStatus.loading
                          ? null
                          : details.onStepContinue,
                      child: Text(isLastStep ? 'Place Order' : 'Continue'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: details.onStepCancel,
                      child: Text(_currentStep == 0 ? 'Cancel' : 'Back'),
                    ),
                  ],
                ),
              );
            },
            steps: [
              Step(
                title: const Text('Select Origin'),
                content: _LanguageSelector(state: state),
                isActive: _currentStep >= 0,
                state: state.language != null
                    ? StepState.complete
                    : StepState.indexed,
              ),
              Step(
                title: const Text('Select Products'),
                content: _ProductSelector(state: state),
                isActive: _currentStep >= 1,
                state: state.itemRequests.isNotEmpty
                    ? StepState.complete
                    : StepState.indexed,
              ),
              Step(
                title: const Text('Review & Submit'),
                content: _ReviewStep(
                  state: state,
                  initialAddress: _shippingAddress,
                  onAddressChanged: (addr) => _shippingAddress = addr,
                ),
                isActive: _currentStep >= 2,
              ),
            ],
          );
        },
      ),
    );
  }

  void _onStepContinue(BuildContext context, OrderFormState state) {
    if (_currentStep == 0 && state.language == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an origin')),
      );
      return;
    }
    if (_currentStep == 1 && state.itemRequests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one product')),
      );
      return;
    }

    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      // Validate address before submitting
      if (_shippingAddress == null ||
          _shippingAddress!.fullName.isEmpty ||
          _shippingAddress!.addressLine1.isEmpty ||
          _shippingAddress!.city.isEmpty ||
          (_shippingAddress!.phone == null ||
              _shippingAddress!.phone!.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please fill in all required address fields')),
        );
        return;
      }
      context.read<OrderFormBloc>().add(
            OrderFormSubmitted(_shippingAddress!),
          );
    }
  }
}

class _LanguageSelector extends StatelessWidget {
  final OrderFormState state;
  const _LanguageSelector({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Which region are you ordering from?'),
        const SizedBox(height: 8),
        ...ProductLanguage.values.map((lang) {
          final displayName = switch (lang) {
            ProductLanguage.japanese => 'Japanese (JPN)',
            ProductLanguage.chinese => 'Chinese (CN)',
            ProductLanguage.korean => 'Korean (KR)',
          };
          return RadioListTile<ProductLanguage>(
            title: Text(displayName),
            value: lang,
            groupValue: state.language,
            onChanged: (val) {
              if (val != null) {
                context
                    .read<OrderFormBloc>()
                    .add(OrderFormLanguageSelected(val));
              }
            },
          );
        }),
      ],
    );
  }
}

class _ProductSelector extends StatefulWidget {
  final OrderFormState state;
  const _ProductSelector({required this.state});

  @override
  State<_ProductSelector> createState() => _ProductSelectorState();
}

class _ProductSelectorState extends State<_ProductSelector> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> get _filteredProducts {
    if (_searchQuery.isEmpty) return widget.state.availableProducts;
    final q = _searchQuery.toLowerCase();
    return widget.state.availableProducts.where((p) {
      return p.name.toLowerCase().contains(q) ||
          (p.sku?.toLowerCase().contains(q) ?? false) ||
          (p.category?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    if (state.status == OrderFormStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final selectedCount =
        state.selectedItems.values.where((q) => q > 0).length;
    final filtered = _filteredProducts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.availableProducts.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No products available for this origin.'),
          ),
        if (state.availableProducts.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '$selectedCount product${selectedCount == 1 ? '' : 's'} selected'
              '${state.estimatedSubtotal > 0 ? ' — Subtotal: \$${state.estimatedSubtotal.toStringAsFixed(2)}' : ''}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
          const SizedBox(height: 8),
          if (filtered.isEmpty && _searchQuery.isNotEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No products match your search.'),
            ),
          ...filtered.map((p) {
            final qty = state.selectedItems[p.id] ?? 0;
            final availableTypes = OrderFormState.availableTypesFor(p);
            final selectedType = state.selectedProductTypes[p.id];
            final displayPrice = OrderFormState.resolvePrice(p, selectedType);

            return Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    ListTile(
                      title: Text(p.name),
                      subtitle: Text(
                        '\$${displayPrice.toStringAsFixed(2)}'
                        '${p.sku != null ? ' — ${p.sku}' : ''}'
                        '${p.quoteRequired ? ' (Quote Required)' : ''}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: qty > 0
                                ? () => context
                                    .read<OrderFormBloc>()
                                    .add(OrderFormItemAdded(p, qty - 1))
                                : null,
                          ),
                          SizedBox(
                            width: 40,
                            child: Text(
                              '$qty',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => context
                                .read<OrderFormBloc>()
                                .add(OrderFormItemAdded(p, qty + 1)),
                          ),
                        ],
                      ),
                    ),
                    // JPN product type selector
                    if (availableTypes.isNotEmpty && qty > 0)
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 16, right: 16, bottom: 8),
                        child: DropdownButtonFormField<String>(
                          value: selectedType,
                          decoration: const InputDecoration(
                            labelText: 'Product Type',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            isDense: true,
                          ),
                          items: availableTypes
                              .map((t) => DropdownMenuItem(
                                    value: t.$1,
                                    child: Text(t.$2),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            context.read<OrderFormBloc>().add(
                                  OrderFormProductTypeChanged(p.id, val),
                                );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _ReviewStep extends StatefulWidget {
  final OrderFormState state;
  final ShippingAddress? initialAddress;
  final ValueChanged<ShippingAddress> onAddressChanged;

  const _ReviewStep({
    required this.state,
    this.initialAddress,
    required this.onAddressChanged,
  });

  @override
  State<_ReviewStep> createState() => _ReviewStepState();
}

class _ReviewStepState extends State<_ReviewStep> {
  late TextEditingController _discordController;

  @override
  void initState() {
    super.initState();
    _discordController =
        TextEditingController(text: widget.state.discordName ?? '');
  }

  @override
  void dispose() {
    _discordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final theme = Theme.of(context);
    final shippingMethods =
        OrderFormState.shippingMethodsFor(state.language);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Order Summary
        Text('Order Summary', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Origin:', style: theme.textTheme.bodyMedium),
                    Text(
                      state.language?.name.toUpperCase() ?? '',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(),
                ...state.selectedItems.entries
                    .where((e) => e.value > 0)
                    .map((entry) {
                  final product = state.availableProducts
                      .where((p) => p.id == entry.key)
                      .firstOrNull;
                  if (product == null) return const SizedBox.shrink();
                  final typeKey = state.selectedProductTypes[entry.key];
                  final unitPrice =
                      OrderFormState.resolvePrice(product, typeKey);
                  final lineTotal = unitPrice * entry.value;
                  final typeLabel = typeKey != null
                      ? ' (${switch (typeKey) {
                          'box' => 'Box',
                          'no_shrink' => 'No Shrink',
                          'case' => 'Case',
                          _ => typeKey,
                        }})'
                      : '';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${product.name}$typeLabel x${entry.value}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        Text(
                          '\$${lineTotal.toStringAsFixed(2)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Subtotal:',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text(
                      '\$${state.estimatedSubtotal.toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (state.language != ProductLanguage.japanese) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Markup (13%):',
                          style: theme.textTheme.bodySmall),
                      Text(
                        '\$${(state.estimatedSubtotal * 0.13).toStringAsFixed(2)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Discord Name
        Text('Contact Info', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        TextFormField(
          controller: _discordController,
          decoration: const InputDecoration(
            labelText: 'Discord Name',
            border: OutlineInputBorder(),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          onChanged: (val) {
            context
                .read<OrderFormBloc>()
                .add(OrderFormDiscordNameChanged(val));
          },
        ),
        const SizedBox(height: 16),

        // Shipping Method (language-dependent)
        if (shippingMethods.isNotEmpty) ...[
          Text('Shipping Method', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: state.shippingMethod,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            hint: const Text('Select shipping method'),
            items: shippingMethods
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (val) {
              context
                  .read<OrderFormBloc>()
                  .add(OrderFormShippingMethodChanged(val));
            },
          ),
          const SizedBox(height: 16),
        ],

        // Shipping Address
        AddressForm(
          initialAddress: widget.initialAddress,
          onChanged: widget.onAddressChanged,
        ),
        const SizedBox(height: 16),

        // Payment Instructions (informational)
        _PaymentInfo(language: state.language),

        const SizedBox(height: 16),
        if (state.status == OrderFormStatus.loading)
          const LinearProgressIndicator(),
      ],
    );
  }
}

class _PaymentInfo extends StatelessWidget {
  final ProductLanguage? language;
  const _PaymentInfo({this.language});

  @override
  Widget build(BuildContext context) {
    if (language == null) return const SizedBox.shrink();
    final theme = Theme.of(context);

    final (title, instructions) = switch (language!) {
      ProductLanguage.japanese => (
          'Payment via Wise',
          'After your order is invoiced, send payment via Wise to the email provided in your invoice.',
        ),
      ProductLanguage.chinese || ProductLanguage.korean => (
          'Payment Options',
          'After your order is invoiced, you can pay via:\n'
              '  Venmo: @cromatcg\n'
              '  PayPal: @Croma01\n'
              '  ACH: Croma Collectibles\n'
              '    Acct: 400116376098\n'
              '    Routing: 124303243',
        ),
    };

    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline,
                    size: 18, color: theme.colorScheme.onSecondaryContainer),
                const SizedBox(width: 8),
                Text(title,
                    style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer)),
              ],
            ),
            const SizedBox(height: 8),
            Text(instructions,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer)),
          ],
        ),
      ),
    );
  }
}
