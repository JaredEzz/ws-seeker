import 'dart:js_interop';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:ws_seeker_frontend/l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_order != null
            ? l10n.orderTitle(_order!.displayOrderNumber ?? _order!.id)
            : l10n.orderDetails),
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
    final l10n = AppLocalizations.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.errorWithMessage(_error!)),
            const SizedBox(height: 16),
            FilledButton(onPressed: _loadOrder, child: Text(l10n.actionRetry)),
          ],
        ),
      );
    }
    if (_order == null) {
      return Center(child: Text(l10n.orderNotFound));
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
          _PricingCard(order: order, isAdmin: isAdmin),
          if (order.status == OrderStatus.submitted ||
              order.status == OrderStatus.awaitingQuote) ...[
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
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: sem.infoText),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 16),
          _ShippingCard(order: order),
          if (order.shippingMethod != null) ...[
            const SizedBox(height: 16),
            _InfoCard(
              titleKey: _InfoCardTitleKey.shippingMethod,
              icon: Icons.local_shipping,
              value: order.shippingMethod!,
            ),
          ],
          if (order.discordName != null) ...[
            const SizedBox(height: 16),
            _InfoCard(
              titleKey: _InfoCardTitleKey.discord,
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
          if (isAdmin) ...[
            const SizedBox(height: 16),
            _AdminEditCard(order: order, onSaved: _loadOrder),
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
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.sectionStatus, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  _OrderStatusChip(status: order.status),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(l10n.sectionOrigin, style: Theme.of(context).textTheme.titleSmall),
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
    final l10n = AppLocalizations.of(context);
    final color = Tokens.statusColor(status);
    final label = localizedStatusLabel(status, l10n);

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
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.sectionItems(order.items.length),
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
                            Text(l10n.itemQtyPrice(item.quantity, item.unitPrice.toStringAsFixed(2)),
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
    final l10n = AppLocalizations.of(context);
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
                        Text(l10n.couldNotLoadImage,
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
  final bool isAdmin;
  const _PricingCard({required this.order, this.isAdmin = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sem = SemanticColors.of(context);
    if (order.quoteRequired) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.sectionPricing, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: sem.warningBg,
                  border: Border.all(color: sem.warningBorder),
                  borderRadius: BorderRadius.circular(Tokens.radiusLg),
                ),
                child: Row(
                  children: [
                    Icon(Icons.request_quote, color: sem.warningIcon),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.quoteNeededTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(color: sem.warningText)),
                          const SizedBox(height: 4),
                          Text(
                            l10n.quoteNeededDescription,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: sem.warningText),
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
            Text(l10n.sectionPricing, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _PricingRow(label: l10n.pricingSubtotal, value: order.subtotal),
            if (order.markup > 0 && isAdmin)
              _PricingRow(label: l10n.pricingMarkup, value: order.markup),
            if (order.estimatedTariff > 0)
              _PricingRow(label: l10n.pricingEstimatedTariff, value: order.estimatedTariff),
            const Divider(),
            _PricingRow(
              label: l10n.pricingTotal,
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
    final l10n = AppLocalizations.of(context);
    final addr = order.shippingAddress;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.shippingAddress, style: Theme.of(context).textTheme.titleMedium),
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
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.sectionTracking, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.local_shipping, size: 20),
                const SizedBox(width: 8),
                Text(l10n.trackingInfo(
                    order.trackingCarrier ?? 'Carrier', order.trackingNumber ?? '')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminEditCard extends StatefulWidget {
  final Order order;
  final VoidCallback onSaved;

  const _AdminEditCard({required this.order, required this.onSaved});

  @override
  State<_AdminEditCard> createState() => _AdminEditCardState();
}

class _AdminEditCardState extends State<_AdminEditCard> {
  bool _editing = false;
  bool _saving = false;
  late TextEditingController _trackingNumberController;
  late TextEditingController _trackingCarrierController;
  late TextEditingController _adminNotesController;
  late OrderStatus _selectedStatus;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _trackingNumberController =
        TextEditingController(text: widget.order.trackingNumber ?? '');
    _trackingCarrierController =
        TextEditingController(text: widget.order.trackingCarrier ?? '');
    _adminNotesController =
        TextEditingController(text: widget.order.adminNotes ?? '');
    _selectedStatus = widget.order.status;
  }

  @override
  void didUpdateWidget(covariant _AdminEditCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.id != widget.order.id) {
      _disposeControllers();
      _initControllers();
    }
  }

  void _disposeControllers() {
    _trackingNumberController.dispose();
    _trackingCarrierController.dispose();
    _adminNotesController.dispose();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final trackingNum = _trackingNumberController.text.trim();
      final trackingCar = _trackingCarrierController.text.trim();
      final notes = _adminNotesController.text.trim();

      await context.read<OrderRepository>().updateOrder(
            widget.order.id,
            UpdateOrderRequest(
              status: _selectedStatus != widget.order.status
                  ? _selectedStatus
                  : null,
              trackingNumber:
                  trackingNum != (widget.order.trackingNumber ?? '')
                      ? trackingNum
                      : null,
              trackingCarrier:
                  trackingCar != (widget.order.trackingCarrier ?? '')
                      ? trackingCar
                      : null,
              adminNotes: notes != (widget.order.adminNotes ?? '')
                  ? notes
                  : null,
            ),
          );

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.orderUpdated)),
        );
        setState(() => _editing = false);
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToUpdateOrder(e.toString()))),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (!_editing) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(l10n.editOrderFields,
                        style: theme.textTheme.titleMedium),
                  ),
                  FilledButton.icon(
                    onPressed: () => setState(() => _editing = true),
                    icon: const Icon(Icons.edit, size: 18),
                    label: Text(l10n.editOrder),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _readOnlyRow(l10n.columnStatus,
                  localizedStatusLabel(widget.order.status, l10n)),
              _readOnlyRow(l10n.trackingCarrierLabel,
                  widget.order.trackingCarrier ?? '-'),
              _readOnlyRow(l10n.trackingNumberLabel,
                  widget.order.trackingNumber ?? '-'),
              _readOnlyRow(
                  l10n.adminNotesLabel, widget.order.adminNotes ?? '-'),
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
            Text(l10n.editOrderFields, style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            DropdownButtonFormField<OrderStatus>(
              value: _selectedStatus,
              decoration: InputDecoration(
                labelText: l10n.columnStatus,
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              items: OrderStatus.values
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Tokens.statusColor(s),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(localizedStatusLabel(s, l10n)),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedStatus = val);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _trackingCarrierController,
              decoration: InputDecoration(
                labelText: l10n.trackingCarrierLabel,
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _trackingNumberController,
              decoration: InputDecoration(
                labelText: l10n.trackingNumberLabel,
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _adminNotesController,
              decoration: InputDecoration(
                labelText: l10n.adminNotesLabel,
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : Text(l10n.saveChanges),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _saving
                      ? null
                      : () {
                          _disposeControllers();
                          _initControllers();
                          setState(() => _editing = false);
                        },
                  child: Text(l10n.cancelEdit),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _readOnlyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          Expanded(child: Text(value)),
        ],
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
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.invoiceGenerated)),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToGenerateInvoice(e.toString()))),
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
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToDownloadPdf(e.toString()))),
        );
      }
    }
    if (mounted) setState(() => _downloadingPdf = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasInvoice = widget.order.invoiceId != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.sectionInvoice, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (hasInvoice) ...[
              Row(
                children: [
                  const Icon(Icons.receipt_long, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(l10n.invoiceHashId(widget.order.invoiceId!)),
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
                    label: Text(l10n.downloadPdf),
                  ),
                ],
              ),
            ] else if (widget.isAdmin) ...[
              FilledButton.icon(
                onPressed: _generating ? null : _generateInvoice,
                icon: _generating
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.receipt),
                label: Text(_generating ? l10n.generating : l10n.generateInvoice),
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
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.removeProofTitle),
        content: Text(l10n.removeProofContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.actionRemove),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _removing = true);
    try {
      await widget.onRemoved();
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.proofRemoved)),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToRemove(e.toString()))),
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
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.paymentProofUploaded)),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToUpload(e.toString()))),
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
    final l10n = AppLocalizations.of(context);
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
                      Text(l10n.couldNotLoadImage,
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
                Text(l10n.pdfDocument,
                    style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(l10n.tapToView,
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
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hasProof = widget.order.proofOfPaymentUrl != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.proofOfPayment, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            if (hasProof) ...[
              Row(
                children: [
                  Icon(Icons.check_circle,
                      color: SemanticColors.of(context).successIcon, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.paymentProofSubmitted,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: SemanticColors.of(context).successIcon),
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
                    label: Text(l10n.openDownload),
                  ),
                  OutlinedButton.icon(
                    onPressed: _uploading ? null : _pickAndUpload,
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: Text(l10n.uploadNew),
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
                    label: Text(l10n.actionRemove,
                        style: TextStyle(color: theme.colorScheme.error)),
                  ),
                ],
              ),
            ] else ...[
              Text(
                l10n.uploadPaymentProof,
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
                      l10n.uploadingFile(_uploadedFileName ?? 'file'),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ] else
                FilledButton.icon(
                  onPressed: _pickAndUpload,
                  icon: const Icon(Icons.upload_file),
                  label: Text(l10n.uploadScreenshot),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _InfoCardTitleKey { shippingMethod, discord, adminNotes }

class _InfoCard extends StatelessWidget {
  final _InfoCardTitleKey titleKey;
  final IconData icon;
  final String value;

  const _InfoCard({
    required this.titleKey,
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = switch (titleKey) {
      _InfoCardTitleKey.shippingMethod => l10n.shippingMethod,
      _InfoCardTitleKey.discord => l10n.sectionDiscord,
      _InfoCardTitleKey.adminNotes => l10n.adminNotes,
    };
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
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: const Icon(Icons.history, size: 20),
        title: Text(l10n.activityLog, style: theme.textTheme.titleMedium),
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
              child: Text(l10n.errorWithMessage(_error!),
                  style: TextStyle(color: theme.colorScheme.error)),
            )
          else if (_logs != null && _logs!.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.noActivityRecorded),
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
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final detailStr = _formatDetails(l10n, log.action, log.details);

    final proofUrl = log.details?['proofOfPaymentUrl'] as String?;

    return ListTile(
      dense: true,
      leading: _actionIcon(context, log.action),
      title: Text(_actionLabel(l10n, log.action),
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(log.userEmail, style: theme.textTheme.bodySmall),
          if (detailStr.isNotEmpty)
            Text(
              detailStr,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: SemanticColors.of(context).textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          if (proofUrl != null)
            GestureDetector(
              onTap: () => web.window.open(proofUrl, '_blank'),
              child: Text(
                l10n.viewFile,
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

  static String _actionLabel(AppLocalizations l10n, String action) {
    return switch (action) {
      'order.created' => l10n.actionOrderCreated,
      'order.updated' => l10n.actionOrderUpdated,
      'order.deleted' => l10n.actionOrderDeleted,
      'comment.created' => l10n.actionCommentAdded,
      'invoice.generated' => l10n.actionInvoiceGenerated,
      'invoice.statusUpdated' => l10n.actionInvoiceStatusUpdated,
      _ => action,
    };
  }

  static String _formatDetails(AppLocalizations l10n, String action, Map<String, dynamic>? details) {
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
          parts.add(l10n.trackingLog(entry.value.toString()));
        case 'proofOfPaymentUploaded':
          parts.add(l10n.proofOfPaymentUploadedLog);
        case 'proofOfPaymentRemoved':
          parts.add(l10n.proofOfPaymentRemovedLog);
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

  Widget _actionIcon(BuildContext context, String action) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (icon, color) = switch (action) {
      'order.created' => (Icons.add_circle_outline, isDark ? Colors.blue.shade300 : Colors.blue),
      'order.updated' => (Icons.edit_outlined, isDark ? Colors.orange.shade300 : Colors.orange),
      'order.deleted' => (Icons.delete_outline, isDark ? Colors.red.shade300 : Colors.red),
      'comment.created' => (Icons.comment_outlined, isDark ? Colors.indigo.shade300 : Colors.indigo),
      'invoice.generated' => (Icons.description_outlined, isDark ? Colors.green.shade300 : Colors.green),
      _ => (Icons.info_outline, isDark ? Colors.grey.shade300 : Colors.grey),
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
