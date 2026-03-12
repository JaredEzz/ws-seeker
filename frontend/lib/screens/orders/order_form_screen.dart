import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ws_seeker_frontend/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/orders/order_form_bloc.dart';
import '../../blocs/orders/orders_bloc.dart';
import '../../repositories/order_repository.dart';
import '../../repositories/product_repository.dart';
import '../../app/design_tokens.dart';
import '../../widgets/common/theme_toggle_button.dart';
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
  final _reviewFormKey = GlobalKey<FormState>();
  final _addressFormKey = GlobalKey<FormState>();
  final _bottomAnchorKey = GlobalKey();
  bool _showTypeErrors = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.placeWholesaleOrder),
        actions: const [ThemeToggleButton()],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: _currentStep == 1
          ? FloatingActionButton.extended(
              onPressed: _scrollToBottom,
              icon: const Icon(Icons.keyboard_double_arrow_down),
              label: Text(l10n.jumpToBottom),
            )
          : null,
      body: BlocConsumer<OrderFormBloc, OrderFormState>(
        listener: (context, state) {
          if (state.status == OrderFormStatus.success) {
            final l10n = AppLocalizations.of(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.orderPlacedSuccess)),
            );
            context.read<OrdersBloc>().add(const OrdersFetchRequested());
            context.go('/dashboard');
          }
          if (state.status == OrderFormStatus.failure) {
            final l10n = AppLocalizations.of(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.errorWithMessage(state.errorMessage ?? ''))),
            );
          }
          // Initialize address from profile once
          if (!_addressInitialized && state.prefillAddress != null) {
            _shippingAddress = state.prefillAddress;
            _addressInitialized = true;
          }
        },
        builder: (context, state) {
          final l10n = AppLocalizations.of(context);
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
              final l10n = AppLocalizations.of(context);
              final isLastStep = _currentStep == 2;
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    FilledButton(
                      onPressed: state.status == OrderFormStatus.loading
                          ? null
                          : details.onStepContinue,
                      child: Text(isLastStep ? l10n.placeOrderButton : l10n.actionContinue),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: details.onStepCancel,
                      child: Text(_currentStep == 0 ? l10n.actionCancel : l10n.actionBack),
                    ),
                  ],
                ),
              );
            },
            steps: [
              Step(
                title: Text(l10n.stepSelectOrigin),
                content: _LanguageSelector(state: state),
                isActive: _currentStep >= 0,
                state: state.language != null
                    ? StepState.complete
                    : StepState.indexed,
              ),
              Step(
                title: Text(l10n.stepSelectProducts),
                content: Column(
                  children: [
                    _ProductSelector(
                      state: state,
                      showTypeErrors: _showTypeErrors,
                    ),
                    SizedBox(key: _bottomAnchorKey, height: 1),
                  ],
                ),
                isActive: _currentStep >= 1,
                state: state.itemRequests.isNotEmpty
                    ? StepState.complete
                    : StepState.indexed,
              ),
              Step(
                title: Text(l10n.stepReviewSubmit),
                content: _ReviewStep(
                  state: state,
                  initialAddress: _shippingAddress,
                  onAddressChanged: (addr) => _shippingAddress = addr,
                  reviewFormKey: _reviewFormKey,
                  addressFormKey: _addressFormKey,
                ),
                isActive: _currentStep >= 2,
              ),
            ],
          );
        },
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final anchorContext = _bottomAnchorKey.currentContext;
      if (anchorContext != null) {
        Scrollable.ensureVisible(
          anchorContext,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onStepContinue(BuildContext context, OrderFormState state) {
    final l10n = AppLocalizations.of(context);
    if (_currentStep == 0 && state.language == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseSelectOrigin)),
      );
      return;
    }
    if (_currentStep == 1) {
      if (state.itemRequests.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.pleaseSelectProduct)),
        );
        return;
      }
      // Validate product types are selected (JPN/CN)
      final missingTypes = state.selectedItems.entries
          .where((e) => e.value > 0)
          .where((e) {
        final product = state.availableProducts
            .where((p) => p.id == e.key)
            .firstOrNull;
        return product != null &&
            OrderFormState.availableTypesFor(product).isNotEmpty &&
            !state.selectedProductTypes.containsKey(e.key);
      }).toList();

      if (missingTypes.isNotEmpty) {
        setState(() => _showTypeErrors = true);
        final firstProduct = state.availableProducts
            .where((p) => p.id == missingTypes.first.key)
            .first;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l10n.pleaseSelectProductType(firstProduct.name))),
        );
        return;
      }
      setState(() => _showTypeErrors = false);
    }

    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      // Validate review fields and address
      final reviewValid = _reviewFormKey.currentState?.validate() ?? false;
      final addressValid = _addressFormKey.currentState?.validate() ?? false;

      if (!reviewValid || !addressValid) return;

      // JPN: check wise email exists on profile
      if (state.language == ProductLanguage.japanese &&
          (state.wiseEmail == null || state.wiseEmail!.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.pleaseSetWiseEmail)),
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
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.whichRegion),
        const SizedBox(height: 8),
        ...ProductLanguage.values.map((lang) {
          final displayName = switch (lang) {
            ProductLanguage.japanese => l10n.originJapanese,
            ProductLanguage.chinese => l10n.originChinese,
            ProductLanguage.korean => l10n.originKorean,
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
  final bool showTypeErrors;
  const _ProductSelector({required this.state, this.showTypeErrors = false});

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

  void _showProductImageDialog(BuildContext context, String imageUrl, String productName) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      productName,
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (ctx, _, __) => Container(
                    height: 150,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(AppLocalizations.of(ctx).couldNotLoadImage),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
    final l10n = AppLocalizations.of(context);
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.noProductsForOrigin),
          ),
        if (state.availableProducts.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${l10n.productsSelected(selectedCount)}'
              '${state.estimatedSubtotal > 0 ? ' — ${l10n.estimatedSubtotal(state.estimatedSubtotal.toStringAsFixed(2))}' : ''}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n.searchProducts,
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.noProductsMatchSearch),
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
                      leading: p.imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                p.imageUrl!,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: Icon(Icons.broken_image, size: 20),
                                ),
                              ),
                            )
                          : null,
                      title: Row(
                        children: [
                          Flexible(child: Text(p.name)),
                          if (p.imageUrl != null) ...[
                            const SizedBox(width: 4),
                            InkWell(
                              borderRadius: BorderRadius.circular(4),
                              onTap: () => _showProductImageDialog(context, p.imageUrl!, p.name),
                              child: const Icon(Icons.image, size: 18),
                            ),
                          ],
                          if (p.quoteRequired) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: SemanticColors.of(context).warningBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                l10n.quoteRequired,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: SemanticColors.of(context).warningText,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        '${p.quoteRequired ? l10n.priceTbd : '\$${displayPrice.toStringAsFixed(2)}'}'
                        '${p.sku != null ? ' — ${p.sku}' : ''}',
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
                    // Product type selector (JPN: Box/No Shrink/Case, CN: Loose Box/Sealed Case)
                    if (availableTypes.isNotEmpty && qty > 0) ...[
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 16, right: 16, bottom: 8),
                        child: DropdownButtonFormField<String>(
                          value: selectedType,
                          decoration: InputDecoration(
                            labelText: l10n.productTypeLabel,
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            isDense: true,
                            errorText: widget.showTypeErrors &&
                                    selectedType == null
                                ? l10n.productTypeRequired
                                : null,
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
  final GlobalKey<FormState> reviewFormKey;
  final GlobalKey<FormState> addressFormKey;

  const _ReviewStep({
    required this.state,
    this.initialAddress,
    required this.onAddressChanged,
    required this.reviewFormKey,
    required this.addressFormKey,
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
    final l10n = AppLocalizations.of(context);
    final state = widget.state;
    final theme = Theme.of(context);
    final shippingMethods =
        OrderFormState.shippingMethodsFor(state.language);
    final paymentMethods =
        OrderFormState.paymentMethodsFor(state.language);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Order Summary
        Text(l10n.orderSummary, style: theme.textTheme.titleMedium),
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
                    Text(l10n.originColon, style: theme.textTheme.bodyMedium),
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
                  final isCn = product.language == ProductLanguage.chinese;
                  final typeLabel = typeKey != null
                      ? ' (${switch (typeKey) {
                          'box' => isCn ? l10n.productTypeLooseBox : l10n.productTypeBox,
                          'no_shrink' => l10n.productTypeNoShrink,
                          'case' => isCn ? l10n.productTypeSealedCase : l10n.productTypeCase,
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
                    Text(l10n.subtotalColon,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text(
                      '\$${state.estimatedSubtotal.toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Builder(builder: (context) {
          final l10n = AppLocalizations.of(context);
          final sem = SemanticColors.of(context);
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: sem.infoBg,
              border: Border.all(color: sem.infoBorder),
              borderRadius: BorderRadius.circular(Tokens.radiusLg),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: sem.infoIcon, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.priceEstimateNotice,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: sem.infoText),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),

        // Validated fields (discord, shipping, payment)
        Form(
          key: widget.reviewFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Discord Name (required)
              Text(l10n.contactInfo, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _discordController,
                decoration: InputDecoration(
                  labelText: l10n.discordNameRequired,
                  border: const OutlineInputBorder(),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? l10n.discordNameValidation
                        : null,
                onChanged: (val) {
                  context
                      .read<OrderFormBloc>()
                      .add(OrderFormDiscordNameChanged(val));
                },
              ),
              const SizedBox(height: 16),

              // Payment Method (required)
              Text(l10n.paymentMethodRequired, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              if (state.language == ProductLanguage.japanese) ...[
                // JPN: Wise only, auto-selected
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.payment),
                    title: Text(l10n.paymentWise),
                    subtitle: state.wiseEmail != null &&
                            state.wiseEmail!.isNotEmpty
                        ? Text(l10n.wiseEmailInfo(state.wiseEmail!))
                        : Text(
                            l10n.setWiseEmail,
                            style:
                                TextStyle(color: theme.colorScheme.error),
                          ),
                  ),
                ),
              ] else if (paymentMethods.isNotEmpty) ...[
                // CN/KR: Dropdown
                DropdownButtonFormField<String>(
                  value: state.paymentMethod,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  hint: Text(l10n.selectPaymentMethod),
                  validator: (value) =>
                      (value == null || value.isEmpty)
                          ? l10n.paymentMethodValidation
                          : null,
                  items: paymentMethods
                      .map(
                          (m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (val) {
                    context
                        .read<OrderFormBloc>()
                        .add(OrderFormPaymentMethodChanged(val));
                  },
                ),
              ],
              const SizedBox(height: 16),

              // Shipping Method (required for JPN and CN)
              if (shippingMethods.isNotEmpty) ...[
                Text(l10n.shippingMethodRequired,
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: state.shippingMethod,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  hint: Text(l10n.selectShippingMethod),
                  validator: (value) =>
                      (value == null || value.isEmpty)
                          ? l10n.shippingMethodValidation
                          : null,
                  items: shippingMethods
                      .map(
                          (m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (val) {
                    context
                        .read<OrderFormBloc>()
                        .add(OrderFormShippingMethodChanged(val));
                  },
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),

        // Shipping Address (own Form)
        AddressForm(
          formKey: widget.addressFormKey,
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
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final (title, instructions) = switch (language!) {
      ProductLanguage.japanese => (
          l10n.paymentViaWise,
          l10n.paymentViaWiseInstructions,
        ),
      ProductLanguage.chinese || ProductLanguage.korean => (
          l10n.paymentOptions,
          l10n.paymentOptionsInstructions,
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
