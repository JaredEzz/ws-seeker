import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';
import '../../app/design_tokens.dart';
import '../../repositories/order_repository.dart';
import '../../widgets/orders/comment_section.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Order? _order;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final order = await context.read<OrderRepository>().getOrderById(widget.orderId);
      setState(() {
        _order = order;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_order != null ? 'Order ${_order!.id}' : 'Order Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrder,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error: $_error'),
            const SizedBox(height: 16),
            FilledButton(onPressed: _loadOrder, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_order == null) {
      return const Center(child: Text('Order not found'));
    }

    final order = _order!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusCard(order: order),
          const SizedBox(height: 16),
          _ItemsCard(order: order),
          const SizedBox(height: 16),
          _PricingCard(order: order),
          const SizedBox(height: 16),
          _ShippingCard(order: order),
          if (order.trackingNumber != null) ...[
            const SizedBox(height: 16),
            _TrackingCard(order: order),
          ],
          if (order.invoiceUrl != null) ...[
            const SizedBox(height: 16),
            _InvoiceCard(order: order),
          ],
          const SizedBox(height: 16),
          CommentSection(orderId: order.id),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final Order order;
  const _StatusCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  _OrderStatusChip(status: order.status),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Origin', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Chip(
                  label: Text(order.language.name.toUpperCase()),
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderStatusChip extends StatelessWidget {
  final OrderStatus status;
  const _OrderStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = Tokens.statusColor(status);
    final label = Tokens.statusLabel(status);

    return Chip(
      avatar: Icon(Icons.circle, size: 12, color: color),
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.1),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  final Order order;
  const _ItemsCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Items (${order.items.length})',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.productName,
                                style: Theme.of(context).textTheme.bodyMedium),
                            Text('Qty: ${item.quantity} x \$${item.unitPrice.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      Text('\$${item.totalPrice.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              )),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  final Order order;
  const _PricingCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pricing', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _PricingRow(label: 'Subtotal', value: order.subtotal),
            if (order.markup > 0)
              _PricingRow(label: 'Markup (13%)', value: order.markup),
            if (order.estimatedTariff > 0)
              _PricingRow(label: 'Estimated Tariff', value: order.estimatedTariff),
            const Divider(),
            _PricingRow(
              label: 'Total',
              value: order.totalAmount,
              bold: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _PricingRow extends StatelessWidget {
  final String label;
  final double value;
  final bool bold;

  const _PricingRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('\$${value.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}

class _ShippingCard extends StatelessWidget {
  final Order order;
  const _ShippingCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final addr = order.shippingAddress;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Shipping Address', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(addr.fullName),
            Text(addr.addressLine1),
            if (addr.addressLine2 != null) Text(addr.addressLine2!),
            Text('${addr.city}, ${addr.state} ${addr.postalCode}'),
            Text(addr.country),
            if (addr.phone != null) Text(addr.phone!),
          ],
        ),
      ),
    );
  }
}

class _TrackingCard extends StatelessWidget {
  final Order order;
  const _TrackingCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tracking', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.local_shipping, size: 20),
                const SizedBox(width: 8),
                Text('${order.trackingCarrier ?? "Carrier"}: ${order.trackingNumber}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final Order order;
  const _InvoiceCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invoice', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.receipt_long, size: 20),
                const SizedBox(width: 8),
                Text('Invoice #${order.invoiceId}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
