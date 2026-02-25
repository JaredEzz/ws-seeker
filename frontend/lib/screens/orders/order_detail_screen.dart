import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';
import '../../app/design_tokens.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../repositories/order_repository.dart';
import '../../services/storage_service.dart';
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
    final authState = context.read<AuthBloc>().state;
    final isAdmin = authState is AuthAuthenticated &&
        (authState.user.role == UserRole.superUser ||
            authState.user.role == UserRole.supplier);

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
          if (order.shippingMethod != null) ...[
            const SizedBox(height: 16),
            _InfoCard(
              title: 'Shipping Method',
              icon: Icons.local_shipping,
              value: order.shippingMethod!,
            ),
          ],
          if (order.discordName != null) ...[
            const SizedBox(height: 16),
            _InfoCard(
              title: 'Discord',
              icon: Icons.chat,
              value: order.discordName!,
            ),
          ],
          const SizedBox(height: 16),
          _ProofOfPaymentCard(
            order: order,
            onUploaded: (url) async {
              await context.read<OrderRepository>().updateOrder(
                    order.id,
                    UpdateOrderRequest(proofOfPaymentUrl: url),
                  );
              _loadOrder();
            },
          ),
          if (order.trackingNumber != null) ...[
            const SizedBox(height: 16),
            _TrackingCard(order: order),
          ],
          if (order.invoiceId != null) ...[
            const SizedBox(height: 16),
            _InvoiceCard(order: order),
          ],
          if (isAdmin && order.adminNotes != null) ...[
            const SizedBox(height: 16),
            _InfoCard(
              title: 'Admin Notes',
              icon: Icons.note,
              value: order.adminNotes!,
            ),
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
    if (order.quoteRequired) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pricing', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Tokens.feedbackWarningBg,
                  border: Border.all(color: Tokens.feedbackWarningBorder),
                  borderRadius: BorderRadius.circular(Tokens.radiusLg),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.request_quote,
                        color: Tokens.feedbackWarningIcon),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Quote Needed',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(color: Tokens.feedbackWarningText)),
                          const SizedBox(height: 4),
                          Text(
                            'This order contains products that require a supplier quote. '
                            'Pricing will be confirmed once the quote is provided.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Tokens.feedbackWarningText),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

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

class _ProofOfPaymentCard extends StatefulWidget {
  final Order order;
  final Future<void> Function(String url) onUploaded;

  const _ProofOfPaymentCard({
    required this.order,
    required this.onUploaded,
  });

  @override
  State<_ProofOfPaymentCard> createState() => _ProofOfPaymentCardState();
}

class _ProofOfPaymentCardState extends State<_ProofOfPaymentCard> {
  bool _uploading = false;
  String? _uploadedFileName;

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'gif', 'webp', 'pdf'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() {
      _uploading = true;
      _uploadedFileName = file.name;
    });

    try {
      final storageService = StorageService();
      final downloadUrl = await storageService.uploadProofOfPayment(
        orderId: widget.order.id,
        filename: file.name,
        bytes: file.bytes!,
      );
      await widget.onUploaded(downloadUrl);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment proof uploaded')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
    if (mounted) setState(() => _uploading = false);
  }

  bool _isImageUrl(String url) {
    // Firebase Storage URLs encode the filename in the path, e.g.:
    // /v0/b/bucket/o/proof_of_payment%2ForderId%2Fphoto.jpg?alt=media&token=...
    // Decode the URL to extract the actual filename extension.
    final decoded = Uri.decodeFull(url).toLowerCase();
    final path = Uri.tryParse(decoded)?.path ?? decoded;
    return path.endsWith('.png') ||
        path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.gif') ||
        path.endsWith('.webp');
  }

  Widget _buildProofViewer(ThemeData theme, String url) {
    if (_isImageUrl(url)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return SizedBox(
                height: 150,
                child: Center(
                  child: CircularProgressIndicator(
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stack) {
              return Container(
                height: 100,
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.broken_image,
                          color: theme.colorScheme.onErrorContainer),
                      const SizedBox(height: 4),
                      Text('Could not load image',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onErrorContainer)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    // PDF or other file type — show an icon card
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.picture_as_pdf,
              size: 40, color: theme.colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PDF Document',
                    style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text('Tap "Open / Download" to view',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasProof = widget.order.proofOfPaymentUrl != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Proof of Payment', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            if (hasProof) ...[
              Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Payment proof submitted',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.green),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Inline viewer for images, icon for PDFs
              _buildProofViewer(theme, widget.order.proofOfPaymentUrl!),
              const SizedBox(height: 12),
              // Action buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      web.window.open(widget.order.proofOfPaymentUrl!, '_blank');
                    },
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Open / Download'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _uploading ? null : _pickAndUpload,
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: const Text('Upload New'),
                  ),
                ],
              ),
            ] else ...[
              Text(
                'Upload a screenshot of your payment confirmation.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              if (_uploading) ...[
                Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Uploading ${_uploadedFileName ?? "file"}...',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ] else
                FilledButton.icon(
                  onPressed: _pickAndUpload,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Screenshot'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String value;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(value),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
