import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';
import '../../blocs/orders/order_form_bloc.dart';
import '../../repositories/order_repository.dart';
import '../../repositories/product_repository.dart';
import '../../widgets/forms/address_form.dart';

class OrderFormScreen extends StatelessWidget {
  const OrderFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrderFormBloc(
        productRepository: context.read<ProductRepository>(),
        orderRepository: context.read<OrderRepository>(),
      ),
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
            context.go('/dashboard');
          }
          if (state.status == OrderFormStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.errorMessage}')),
            );
          }
        },
        builder: (context, state) {
          return Stepper(
            currentStep: _currentStep,
            onStepContinue: () {
              if (_currentStep == 0 && state.language == null) return;
              if (_currentStep == 1 && state.itemRequests.isEmpty) return;
              
              if (_currentStep < 2) {
                setState(() => _currentStep++);
              } else {
                // Validate address before submitting
                if (_shippingAddress == null ||
                    _shippingAddress!.fullName.isEmpty ||
                    _shippingAddress!.addressLine1.isEmpty ||
                    _shippingAddress!.city.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in the shipping address')),
                  );
                  return;
                }
                context.read<OrderFormBloc>().add(
                      OrderFormSubmitted(_shippingAddress!),
                    );
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) {
                setState(() => _currentStep--);
              } else {
                Navigator.of(context).pop();
              }
            },
            steps: [
              Step(
                title: const Text('Select Origin'),
                content: _LanguageSelector(state: state),
                isActive: _currentStep >= 0,
              ),
              Step(
                title: const Text('Select Products'),
                content: _ProductSelector(state: state),
                isActive: _currentStep >= 1,
              ),
              Step(
                title: const Text('Review & Address'),
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
}

class _LanguageSelector extends StatelessWidget {
  final OrderFormState state;
  const _LanguageSelector({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: ProductLanguage.values.map((lang) {
        return RadioListTile<ProductLanguage>(
          title: Text(lang.name.toUpperCase()),
          value: lang,
          groupValue: state.language,
          onChanged: (val) {
            if (val != null) {
              context.read<OrderFormBloc>().add(OrderFormLanguageSelected(val));
            }
          },
        );
      }).toList(),
    );
  }
}

class _ProductSelector extends StatelessWidget {
  final OrderFormState state;
  const _ProductSelector({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.status == OrderFormStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        if (state.availableProducts.isEmpty)
          const Text('No products available for this origin.'),
        ...state.availableProducts.map((p) {
          final qty = state.selectedItems[p.id] ?? 0;
          return ListTile(
            title: Text(p.name),
            subtitle: Text('\$${p.basePrice}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: qty > 0
                      ? () => context
                          .read<OrderFormBloc>()
                          .add(OrderFormItemAdded(p, qty - 1))
                      : null,
                ),
                Text('$qty'),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => context
                      .read<OrderFormBloc>()
                      .add(OrderFormItemAdded(p, qty + 1)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _ReviewStep extends StatelessWidget {
  final OrderFormState state;
  final ShippingAddress? initialAddress;
  final ValueChanged<ShippingAddress> onAddressChanged;

  const _ReviewStep({
    required this.state,
    this.initialAddress,
    required this.onAddressChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Origin: ${state.language?.name.toUpperCase()}'),
        const SizedBox(height: 8),
        Text('Items: ${state.itemRequests.length}'),
        const Divider(),
        AddressForm(
          initialAddress: initialAddress,
          onChanged: onAddressChanged,
        ),
        const SizedBox(height: 16),
        if (state.status == OrderFormStatus.loading)
          const LinearProgressIndicator(),
      ],
    );
  }
}
