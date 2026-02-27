import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;
import 'package:ws_seeker_shared/ws_seeker_shared.dart';
import '../../repositories/invoice_repository.dart';
import '../../widgets/common/theme_toggle_button.dart';
import '../../widgets/navigation/admin_shell.dart';

class InvoiceManagementScreen extends StatefulWidget {
  const InvoiceManagementScreen({super.key});

  @override
  State<InvoiceManagementScreen> createState() =>
      _InvoiceManagementScreenState();
}

class _InvoiceManagementScreenState extends State<InvoiceManagementScreen> {
  late final InvoiceRepository _invoiceRepository;
  List<Invoice> _invoices = [];
  bool _loading = true;
  String? _error;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _invoiceRepository = HttpInvoiceRepository();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final invoices =
          await _invoiceRepository.getInvoices(status: _statusFilter);
      setState(() {
        _invoices = invoices;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _updateStatus(String invoiceId, String status) async {
    try {
      await _invoiceRepository.updateInvoiceStatus(invoiceId, status);
      _loadInvoices();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invoice status updated to $status')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _updateInvoice(
      String invoiceId, Map<String, dynamic> updates) async {
    try {
      await _invoiceRepository.updateInvoice(invoiceId, updates);
      _loadInvoices();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _downloadPdf(Invoice invoice) async {
    try {
      final bytes = await _invoiceRepository.downloadPdf(invoice.id);
      final data = Uint8List.fromList(bytes);
      final blob = web.Blob(
        [data.toJS].toJS,
        web.BlobPropertyBag(type: 'application/pdf'),
      );
      final url = web.URL.createObjectURL(blob);
      final filename =
          'Invoice_${invoice.displayInvoiceNumber ?? invoice.id}.pdf';
      final anchor = web.document.createElement('a') as web.HTMLAnchorElement
        ..href = url
        ..download = filename;
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
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      selectedIndex: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Invoices'),
          actions: [
            const ThemeToggleButton(),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadInvoices,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // Filter bar
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  DropdownButton<String?>(
                    value: _statusFilter,
                    hint: const Text('All Statuses'),
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(
                          value: null, child: Text('All Statuses')),
                      DropdownMenuItem(value: 'draft', child: Text('Draft')),
                      DropdownMenuItem(value: 'sent', child: Text('Sent')),
                      DropdownMenuItem(value: 'paid', child: Text('Paid')),
                      DropdownMenuItem(value: 'void', child: Text('Void')),
                    ],
                    onChanged: (val) {
                      setState(() => _statusFilter = val);
                      _loadInvoices();
                    },
                  ),
                  const SizedBox(width: 16),
                  Text('${_invoices.length} invoices',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text('Error: $_error'))
                      : _invoices.isEmpty
                          ? const Center(child: Text('No invoices found'))
                          : _InvoiceList(
                              invoices: _invoices,
                              onUpdateStatus: _updateStatus,
                              onUpdateInvoice: _updateInvoice,
                              onDownloadPdf: _downloadPdf,
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceList extends StatelessWidget {
  final List<Invoice> invoices;
  final void Function(String invoiceId, String status) onUpdateStatus;
  final Future<void> Function(String invoiceId, Map<String, dynamic> updates)
      onUpdateInvoice;
  final void Function(Invoice invoice) onDownloadPdf;

  const _InvoiceList({
    required this.invoices,
    required this.onUpdateStatus,
    required this.onUpdateInvoice,
    required this.onDownloadPdf,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: invoices.length,
      itemBuilder: (context, index) {
        final invoice = invoices[index];
        return _InvoiceCard(
          invoice: invoice,
          onUpdateStatus: onUpdateStatus,
          onUpdateInvoice: onUpdateInvoice,
          onDownloadPdf: onDownloadPdf,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Editable line item helper
// ---------------------------------------------------------------------------

class _EditableLineItem {
  final TextEditingController descriptionController;
  final TextEditingController quantityController;
  final TextEditingController unitPriceController;

  _EditableLineItem({
    required String description,
    required int quantity,
    required double unitPrice,
  })  : descriptionController = TextEditingController(text: description),
        quantityController = TextEditingController(text: '$quantity'),
        unitPriceController =
            TextEditingController(text: unitPrice.toStringAsFixed(2));

  double get totalPrice {
    final qty = int.tryParse(quantityController.text) ?? 0;
    final price = double.tryParse(unitPriceController.text) ?? 0;
    return qty * price;
  }

  void dispose() {
    descriptionController.dispose();
    quantityController.dispose();
    unitPriceController.dispose();
  }
}

// ---------------------------------------------------------------------------
// Invoice card (supports inline edit mode for draft invoices)
// ---------------------------------------------------------------------------

class _InvoiceCard extends StatefulWidget {
  final Invoice invoice;
  final void Function(String invoiceId, String status) onUpdateStatus;
  final Future<void> Function(String invoiceId, Map<String, dynamic> updates)
      onUpdateInvoice;
  final void Function(Invoice invoice) onDownloadPdf;

  const _InvoiceCard({
    required this.invoice,
    required this.onUpdateStatus,
    required this.onUpdateInvoice,
    required this.onDownloadPdf,
  });

  @override
  State<_InvoiceCard> createState() => _InvoiceCardState();
}

class _InvoiceCardState extends State<_InvoiceCard> {
  bool _editing = false;
  bool _saving = false;

  // Edit-mode state (initialized lazily in _enterEditMode)
  List<_EditableLineItem> _editableItems = [];
  TextEditingController _markupController = TextEditingController();
  TextEditingController _tariffController = TextEditingController();
  TextEditingController _airShippingController = TextEditingController();
  TextEditingController _oceanShippingController = TextEditingController();

  @override
  void dispose() {
    _disposeEditing();
    super.dispose();
  }

  void _disposeEditing() {
    for (final item in _editableItems) {
      item.dispose();
    }
    _markupController.dispose();
    _tariffController.dispose();
    _airShippingController.dispose();
    _oceanShippingController.dispose();
  }

  void _enterEditMode() {
    final inv = widget.invoice;
    setState(() {
      _editing = true;
      _editableItems = inv.lineItems
          .map((item) => _EditableLineItem(
                description: item.description,
                quantity: item.quantity,
                unitPrice: item.unitPrice,
              ))
          .toList();
      _markupController =
          TextEditingController(text: inv.markup.toStringAsFixed(2));
      _tariffController =
          TextEditingController(text: inv.tariff.toStringAsFixed(2));
      _airShippingController = TextEditingController(
          text: (inv.airShippingCost ?? 0).toStringAsFixed(2));
      _oceanShippingController = TextEditingController(
          text: (inv.oceanShippingCost ?? 0).toStringAsFixed(2));
    });
  }

  void _cancelEdit() {
    _disposeEditing();
    _editableItems = [];
    _markupController = TextEditingController();
    _tariffController = TextEditingController();
    _airShippingController = TextEditingController();
    _oceanShippingController = TextEditingController();
    setState(() => _editing = false);
  }

  void _addLineItem() {
    setState(() {
      _editableItems.add(
        _EditableLineItem(description: '', quantity: 1, unitPrice: 0),
      );
    });
  }

  void _removeLineItem(int index) {
    setState(() {
      _editableItems[index].dispose();
      _editableItems.removeAt(index);
    });
  }

  double get _calculatedSubtotal =>
      _editableItems.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get _calculatedTotal =>
      _calculatedSubtotal +
      (double.tryParse(_markupController.text) ?? 0) +
      (double.tryParse(_tariffController.text) ?? 0) +
      (double.tryParse(_airShippingController.text) ?? 0) +
      (double.tryParse(_oceanShippingController.text) ?? 0);

  Future<void> _saveEdit() async {
    if (_editableItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice must have at least one line item')),
      );
      return;
    }

    setState(() => _saving = true);

    final updates = <String, dynamic>{
      'lineItems': _editableItems
          .map((item) => {
                'description': item.descriptionController.text,
                'quantity': int.tryParse(item.quantityController.text) ?? 0,
                'unitPrice':
                    double.tryParse(item.unitPriceController.text) ?? 0,
                'totalPrice': item.totalPrice,
              })
          .toList(),
      'subtotal': _calculatedSubtotal,
      'markup': double.tryParse(_markupController.text) ?? 0,
      'tariff': double.tryParse(_tariffController.text) ?? 0,
      'airShippingCost': double.tryParse(_airShippingController.text) ?? 0,
      'oceanShippingCost': double.tryParse(_oceanShippingController.text) ?? 0,
      'total': _calculatedTotal,
    };

    await widget.onUpdateInvoice(widget.invoice.id, updates);

    if (mounted) {
      _cancelEdit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final invoice = widget.invoice;
    final displayNumber =
        invoice.displayInvoiceNumber ?? invoice.id.substring(0, 8);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Row(
          children: [
            Text(displayNumber,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 12),
            _StatusBadge(status: invoice.status),
          ],
        ),
        subtitle: Text(
          'Order: ${invoice.displayInvoiceNumber != null ? invoice.displayInvoiceNumber!.replaceFirst('INV-', '') : invoice.orderId} '
          '| Total: \$${invoice.total.toStringAsFixed(2)} '
          '| Created: ${_formatDate(invoice.createdAt)}',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CROMA WHOLESALE Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text('CROMA WHOLESALE',
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const Text('527 W State Street, Unit 102'),
                      const Text('Pleasant Grove, UT 84062'),
                      const SizedBox(height: 8),
                      if (invoice.displayInvoiceNumber != null)
                        Text('Invoice #: ${invoice.displayInvoiceNumber}'),
                      if (invoice.dueDate != null)
                        Text('Due Date: ${_formatDate(invoice.dueDate!)}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Line items
                if (_editing) _buildEditableLineItems() else _buildReadOnlyLineItems(theme),

                const SizedBox(height: 16),

                // Totals
                if (_editing) _buildEditableTotals(theme) else _buildReadOnlyTotals(invoice),

                const SizedBox(height: 16),

                // Actions
                if (_editing)
                  _buildEditActions()
                else
                  _buildReadOnlyActions(invoice),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Read-only line items table
  // ---------------------------------------------------------------------------
  Widget _buildReadOnlyLineItems(ThemeData theme) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FixedColumnWidth(60),
        2: FixedColumnWidth(80),
        3: FixedColumnWidth(90),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            border:
                Border(bottom: BorderSide(color: theme.dividerColor)),
          ),
          children: const [
            Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('Description',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Text('Qty',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.right),
            Text('Unit Price',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.right),
            Text('Total',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.right),
          ],
        ),
        ...widget.invoice.lineItems.map((item) => TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(item.description),
                ),
                Text('${item.quantity}', textAlign: TextAlign.right),
                Text('\$${item.unitPrice.toStringAsFixed(2)}',
                    textAlign: TextAlign.right),
                Text('\$${item.totalPrice.toStringAsFixed(2)}',
                    textAlign: TextAlign.right),
              ],
            )),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Editable line items
  // ---------------------------------------------------------------------------
  Widget _buildEditableLineItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        const Row(
          children: [
            Expanded(
                flex: 3,
                child: Text('Description',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: 8),
            SizedBox(
                width: 70,
                child: Text('Qty',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center)),
            SizedBox(width: 8),
            SizedBox(
                width: 90,
                child: Text('Unit Price',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center)),
            SizedBox(width: 8),
            SizedBox(
                width: 80,
                child: Text('Total',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right)),
            SizedBox(width: 40), // delete button space
          ],
        ),
        const Divider(),
        // Rows
        ...List.generate(_editableItems.length, (index) {
          final item = _editableItems[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: item.descriptionController,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 70,
                  child: TextFormField(
                    controller: item.quantityController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontSize: 13),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 90,
                  child: TextFormField(
                    controller: item.unitPriceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    ],
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      border: OutlineInputBorder(),
                      prefixText: '\$',
                    ),
                    style: const TextStyle(fontSize: 13),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '\$${item.totalPrice.toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: IconButton(
                    icon: Icon(Icons.delete_outline,
                        size: 18,
                        color: Theme.of(context).colorScheme.error),
                    onPressed: () => _removeLineItem(index),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Remove line item',
                  ),
                ),
              ],
            ),
          );
        }),
        // Add line item button
        TextButton.icon(
          onPressed: _addLineItem,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Line Item'),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Read-only totals (Task #8: tariff shown separately)
  // ---------------------------------------------------------------------------
  Widget _buildReadOnlyTotals(Invoice invoice) {
    return Column(
      children: [
        _TotalRow(label: 'SUBTOTAL', amount: invoice.subtotal),
        if (invoice.markup > 0)
          _TotalRow(label: 'Markup (13%)', amount: invoice.markup),
        if (invoice.tariff > 0)
          _TotalRow(label: 'Tariff', amount: invoice.tariff),
        if (invoice.airShippingCost != null && invoice.airShippingCost! > 0)
          _TotalRow(label: 'Air Shipping', amount: invoice.airShippingCost!),
        if (invoice.oceanShippingCost != null &&
            invoice.oceanShippingCost! > 0)
          _TotalRow(
              label: 'Ocean Shipping', amount: invoice.oceanShippingCost!),
        const Divider(),
        _TotalRow(
            label: 'BALANCE TOTAL', amount: invoice.total, bold: true),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Editable totals
  // ---------------------------------------------------------------------------
  Widget _buildEditableTotals(ThemeData theme) {
    return Column(
      children: [
        // Subtotal (auto-calculated, read-only)
        _TotalRow(label: 'SUBTOTAL', amount: _calculatedSubtotal),
        const SizedBox(height: 8),
        _editableTotalField('Markup', _markupController),
        const SizedBox(height: 8),
        _editableTotalField('Tariff', _tariffController),
        const SizedBox(height: 8),
        _editableTotalField('Air Shipping', _airShippingController),
        const SizedBox(height: 8),
        _editableTotalField('Ocean Shipping', _oceanShippingController),
        const Divider(),
        _TotalRow(
            label: 'BALANCE TOTAL', amount: _calculatedTotal, bold: true),
      ],
    );
  }

  Widget _editableTotalField(String label, TextEditingController controller) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        SizedBox(
          width: 120,
          child: TextFormField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            textAlign: TextAlign.right,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(),
              prefixText: '\$',
            ),
            style: const TextStyle(fontSize: 14),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Read-only action buttons
  // ---------------------------------------------------------------------------
  Widget _buildReadOnlyActions(Invoice invoice) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (invoice.status == InvoiceStatus.draft)
          OutlinedButton.icon(
            onPressed: _enterEditMode,
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Edit'),
          ),
        OutlinedButton.icon(
          onPressed: () => widget.onDownloadPdf(invoice),
          icon: const Icon(Icons.picture_as_pdf, size: 18),
          label: const Text('Download PDF'),
        ),
        if (invoice.status == InvoiceStatus.draft)
          FilledButton.icon(
            onPressed: () => widget.onUpdateStatus(invoice.id, 'sent'),
            icon: const Icon(Icons.send, size: 18),
            label: const Text('Mark as Sent'),
          ),
        if (invoice.status == InvoiceStatus.sent)
          FilledButton.icon(
            onPressed: () => widget.onUpdateStatus(invoice.id, 'paid'),
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text('Mark as Paid'),
          ),
        if (invoice.status != InvoiceStatus.voided &&
            invoice.status != InvoiceStatus.paid)
          OutlinedButton.icon(
            onPressed: () => widget.onUpdateStatus(invoice.id, 'void'),
            icon: const Icon(Icons.cancel, size: 18),
            label: const Text('Void'),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Edit-mode action buttons
  // ---------------------------------------------------------------------------
  Widget _buildEditActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: _saving ? null : _cancelEdit,
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: _saving ? null : _saveEdit,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save, size: 18),
          label: const Text('Save'),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}

// ---------------------------------------------------------------------------
// Supporting widgets
// ---------------------------------------------------------------------------

class _TotalRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool bold;

  const _TotalRow({
    required this.label,
    required this.amount,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('\$${amount.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final InvoiceStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      InvoiceStatus.draft => ('Draft', Colors.grey),
      InvoiceStatus.sent => ('Sent', Colors.blue),
      InvoiceStatus.paid => ('Paid', Colors.green),
      InvoiceStatus.voided => ('Void', Colors.red),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
