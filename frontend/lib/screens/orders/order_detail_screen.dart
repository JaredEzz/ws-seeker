import 'dart:js_interop';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';
import '../../app/design_tokens.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../repositories/audit_log_repository.dart';
import '../../repositories/invoice_repository.dart';
import '../../repositories/order_repository.dart';
import '../../services/storage_service.dart';
import '../../widgets/common/theme_toggle_button.dart';
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
        title: Text(_order != null
            ? 'Order ${_order!.displayOrderNumber ?? _order!.id}'
            : 'Order Details'),
        actions: [
          const ThemeToggleButton(),
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
    final userRole = authState is AuthAuthenticated ? authState.user.role : null;
    final isAdmin = userRole == UserRole.superUser || userRole == UserRole.supplier;

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
            onRemoved: () async {
              await context.read<OrderRepository>().updateOrder(
                    order.id,
                    const UpdateOrderRequest(proofOfPaymentUrl: ''),
                  );
              _loadOrder();
            },
          ),
          if (order.trackingNumber != null) ...[
            const SizedBox(height: 16),
            _TrackingCard(order: order),
          ],
          if (isAdmin || order.invoiceId != null) ...[
            const SizedBox(height: 16),
            _InvoiceCard(order: order, isAdmin: isAdmin, onChanged: _loadOrder),
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
          if (userRole == UserRole.superUser) ...[
            const SizedBox(height: 16),
            _ActivityLogSection(orderId: order.id),
          ],
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
                            Row(
                              children: [
                                Flexible(
                                  child: Text(item.productName,
                                      style: Theme.of(context).textTheme.bodyMedium),
                                ),
                                if (item.imageUrl != null) ...[
                                  const SizedBox(width: 4),
                                  InkWell(
                                    borderRadius: BorderRadius.circular(4),
                                    onTap: () => _showProductImageDialog(context, item.imageUrl!, item.productName),
                                    child: const Icon(Icons.image, size: 18),
                                  ),
                                ],
                              ],
                            ),
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

  static void _showProductImageDialog(BuildContext context, String imageUrl, String productName) {
    showDialog(
      context: context,
      builder: (_) => _ProductImageDialog(imageUrl: imageUrl, productName: productName),
    );
  }
}

class _ProductImageDialog extends StatelessWidget {
  final String imageUrl;
  final String productName;
  const _ProductImageDialog({required this.imageUrl, required this.productName});

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
                  return SizedBox(
                    height: 200,
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
                    height: 150,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.broken_image,
                            color: Theme.of(context).colorScheme.onErrorContainer),
                        const SizedBox(height: 4),
                        Text('Could not load image',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onErrorContainer)),
                      ],
                    ),
                  );
                },
              ),
            ),
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

class _InvoiceCard extends StatefulWidget {
  final Order order;
  final bool isAdmin;
  final VoidCallback onChanged;

  const _InvoiceCard({
    required this.order,
    required this.isAdmin,
    required this.onChanged,
  });

  @override
  State<_InvoiceCard> createState() => _InvoiceCardState();
}

class _InvoiceCardState extends State<_InvoiceCard> {
  bool _generating = false;
  bool _downloadingPdf = false;

  Future<void> _generateInvoice() async {
    setState(() => _generating = true);
    try {
      await context.read<InvoiceRepository>().generateInvoice(widget.order.id);
      widget.onChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice generated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate invoice: $e')),
        );
      }
    }
    if (mounted) setState(() => _generating = false);
  }

  Future<void> _downloadPdf() async {
    setState(() => _downloadingPdf = true);
    try {
      final bytes = await context
          .read<InvoiceRepository>()
          .downloadPdf(widget.order.invoiceId!);
      final data = Uint8List.fromList(bytes);
      final blob = web.Blob(
        [data.toJS].toJS,
        web.BlobPropertyBag(type: 'application/pdf'),
      );
      final url = web.URL.createObjectURL(blob);
      final anchor = web.document.createElement('a') as web.HTMLAnchorElement
        ..href = url
        ..download = 'Invoice_${widget.order.invoiceId}.pdf';
      web.document.body!.appendChild(anchor);
      anchor.click();
      anchor.remove();
      web.URL.revokeObjectURL(url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download PDF: $e')),
        );
      }
    }
    if (mounted) setState(() => _downloadingPdf = false);
  }

  @override
  Widget build(BuildContext context) {
    final hasInvoice = widget.order.invoiceId != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invoice', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (hasInvoice) ...[
              Row(
                children: [
                  const Icon(Icons.receipt_long, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Invoice #${widget.order.invoiceId}'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _downloadingPdf ? null : _downloadPdf,
                    icon: _downloadingPdf
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.picture_as_pdf, size: 18),
                    label: const Text('Download PDF'),
                  ),
                ],
              ),
            ] else if (widget.isAdmin) ...[
              FilledButton.icon(
                onPressed: _generating ? null : _generateInvoice,
                icon: _generating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.receipt),
                label: Text(_generating ? 'Generating...' : 'Generate Invoice'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProofOfPaymentCard extends StatefulWidget {
  final Order order;
  final Future<void> Function(String url) onUploaded;
  final Future<void> Function() onRemoved;

  const _ProofOfPaymentCard({
    required this.order,
    required this.onUploaded,
    required this.onRemoved,
  });

  @override
  State<_ProofOfPaymentCard> createState() => _ProofOfPaymentCardState();
}

class _ProofOfPaymentCardState extends State<_ProofOfPaymentCard> {
  bool _uploading = false;
  bool _removing = false;
  String? _uploadedFileName;

  Future<void> _confirmRemove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Proof of Payment?'),
        content: const Text(
          'The uploaded file will be preserved in the activity log '
          'and can still be accessed from there.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _removing = true);
    try {
      await widget.onRemoved();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proof of payment removed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove: $e')),
        );
      }
    }
    if (mounted) setState(() => _removing = false);
  }

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
                  OutlinedButton.icon(
                    onPressed: _removing ? null : _confirmRemove,
                    icon: _removing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.delete_outline,
                            size: 18, color: theme.colorScheme.error),
                    label: Text('Remove',
                        style: TextStyle(color: theme.colorScheme.error)),
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

class _ActivityLogSection extends StatefulWidget {
  final String orderId;
  const _ActivityLogSection({required this.orderId});

  @override
  State<_ActivityLogSection> createState() => _ActivityLogSectionState();
}

class _ActivityLogSectionState extends State<_ActivityLogSection> {
  bool _loading = false;
  List<AuditLog>? _logs;
  String? _error;

  Future<void> _loadLogs() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = context.read<AuditLogRepository>();
      final page = await repo.getAuditLogs(AuditLogQuery(
        resourceId: widget.orderId,
        limit: 100,
      ));
      setState(() {
        _logs = page.logs;
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
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: const Icon(Icons.history, size: 20),
        title: Text('Activity Log', style: theme.textTheme.titleMedium),
        initiallyExpanded: false,
        onExpansionChanged: (expanded) {
          if (expanded && _logs == null && !_loading) {
            _loadLogs();
          }
        },
        children: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: $_error',
                  style: TextStyle(color: theme.colorScheme.error)),
            )
          else if (_logs != null && _logs!.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No activity recorded.'),
            )
          else if (_logs != null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _logs!.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 56),
                itemBuilder: (context, index) {
                  final log = _logs![index];
                  return _ActivityLogEntry(log: log);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ActivityLogEntry extends StatelessWidget {
  final AuditLog log;
  const _ActivityLogEntry({required this.log});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detailStr = _formatDetails(log.action, log.details);

    final proofUrl = log.details?['proofOfPaymentUrl'] as String?;

    return ListTile(
      dense: true,
      leading: _actionIcon(log.action),
      title: Text(_actionLabel(log.action),
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(log.userEmail, style: theme.textTheme.bodySmall),
          if (detailStr.isNotEmpty)
            Text(
              detailStr,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          if (proofUrl != null)
            GestureDetector(
              onTap: () => web.window.open(proofUrl, '_blank'),
              child: Text(
                'View file',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
        ],
      ),
      trailing: Text(
        _formatTimestamp(log.createdAt),
        style: theme.textTheme.bodySmall,
      ),
      isThreeLine: detailStr.isNotEmpty || proofUrl != null,
    );
  }

  static String _actionLabel(String action) {
    return switch (action) {
      'order.created' => 'Order Created',
      'order.updated' => 'Order Updated',
      'order.deleted' => 'Order Deleted',
      'comment.created' => 'Comment Added',
      'invoice.generated' => 'Invoice Generated',
      'invoice.statusUpdated' => 'Invoice Status Updated',
      _ => action,
    };
  }

  static const _statusLabels = {
    'submitted': 'Submitted',
    'awaitingQuote': 'Awaiting Quote',
    'invoiced': 'Invoice Sent',
    'paymentPending': 'Payment Pending',
    'paymentReceived': 'Payment Received',
    'shipped': 'Shipped',
    'delivered': 'Delivered',
    'cancelled': 'Cancelled',
  };

  static String _formatDetails(String action, Map<String, dynamic>? details) {
    if (details == null || details.isEmpty) return '';

    final parts = <String>[];
    for (final entry in details.entries) {
      switch (entry.key) {
        case 'statusChange':
          final raw = entry.value.toString();
          final arrow = raw.split(' -> ');
          if (arrow.length == 2) {
            final from = _statusLabels[arrow[0]] ?? arrow[0];
            final to = _statusLabels[arrow[1]] ?? arrow[1];
            parts.add('$from \u2192 $to');
          } else {
            parts.add(raw);
          }
        case 'trackingNumber':
          parts.add('Tracking: ${entry.value}');
        case 'proofOfPaymentUploaded':
          parts.add('Proof of payment uploaded');
        case 'proofOfPaymentRemoved':
          parts.add('Proof of payment removed');
        case 'proofOfPaymentUrl':
          // Handled separately as a clickable link
          break;
        case 'language':
          parts.add(entry.value.toString().toUpperCase());
        case 'itemCount':
          parts.add('${entry.value} item${entry.value == 1 ? '' : 's'}');
        case 'commentId':
        case 'displayOrderNumber':
          break;
        default:
          parts.add('${entry.key}: ${entry.value}');
      }
    }
    return parts.join(' \u00b7 ');
  }

  Widget _actionIcon(String action) {
    final (icon, color) = switch (action) {
      'order.created' => (Icons.add_circle_outline, Colors.blue),
      'order.updated' => (Icons.edit_outlined, Colors.orange),
      'order.deleted' => (Icons.delete_outline, Colors.red),
      'comment.created' => (Icons.comment_outlined, Colors.indigo),
      'invoice.generated' => (Icons.description_outlined, Colors.green),
      _ => (Icons.info_outline, Colors.grey),
    };

    return CircleAvatar(
      radius: 16,
      backgroundColor: color.withValues(alpha: 0.12),
      child: Icon(icon, color: color, size: 16),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final m = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour < 12 ? 'AM' : 'PM';
    return '${local.month}/${local.day} $h:$m $ampm';
  }
}
