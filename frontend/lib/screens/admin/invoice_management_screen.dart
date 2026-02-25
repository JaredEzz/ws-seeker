import 'package:flutter/material.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';
import '../../repositories/invoice_repository.dart';
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

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      selectedIndex: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Invoices'),
          actions: [
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
                      DropdownMenuItem(value: null, child: Text('All Statuses')),
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

  const _InvoiceList({
    required this.invoices,
    required this.onUpdateStatus,
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
        );
      },
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final void Function(String invoiceId, String status) onUpdateStatus;

  const _InvoiceCard({
    required this.invoice,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          'Order: ${invoice.orderId.substring(0, 8)}... '
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

                // Line items table
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(3),
                    1: FixedColumnWidth(60),
                    2: FixedColumnWidth(80),
                    3: FixedColumnWidth(90),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(color: theme.dividerColor)),
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
                    ...invoice.lineItems.map((item) => TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(item.description),
                            ),
                            Text('${item.quantity}',
                                textAlign: TextAlign.right),
                            Text('\$${item.unitPrice.toStringAsFixed(2)}',
                                textAlign: TextAlign.right),
                            Text('\$${item.totalPrice.toStringAsFixed(2)}',
                                textAlign: TextAlign.right),
                          ],
                        )),
                  ],
                ),
                const SizedBox(height: 16),

                // Totals
                _TotalRow(label: 'SUBTOTAL', amount: invoice.subtotal),
                if (invoice.markup > 0)
                  _TotalRow(label: 'Markup (13%)', amount: invoice.markup),
                if (invoice.airShippingCost != null &&
                    invoice.airShippingCost! > 0)
                  _TotalRow(
                      label: 'AIR SHIPPING + Tariffs',
                      amount: invoice.airShippingCost!),
                if (invoice.tariff > 0 &&
                    invoice.airShippingCost == null &&
                    invoice.oceanShippingCost == null)
                  _TotalRow(label: 'Tariffs', amount: invoice.tariff),
                if (invoice.oceanShippingCost != null &&
                    invoice.oceanShippingCost! > 0)
                  _TotalRow(
                      label: 'OCEAN SHIPPING + Tariffs',
                      amount: invoice.oceanShippingCost!),
                const Divider(),
                _TotalRow(
                    label: 'BALANCE TOTAL',
                    amount: invoice.total,
                    bold: true),
                const SizedBox(height: 16),

                // Actions
                Wrap(
                  spacing: 8,
                  children: [
                    if (invoice.status == InvoiceStatus.draft)
                      FilledButton.icon(
                        onPressed: () =>
                            onUpdateStatus(invoice.id, 'sent'),
                        icon: const Icon(Icons.send, size: 18),
                        label: const Text('Mark as Sent'),
                      ),
                    if (invoice.status == InvoiceStatus.sent)
                      FilledButton.icon(
                        onPressed: () =>
                            onUpdateStatus(invoice.id, 'paid'),
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text('Mark as Paid'),
                      ),
                    if (invoice.status != InvoiceStatus.voided &&
                        invoice.status != InvoiceStatus.paid)
                      OutlinedButton.icon(
                        onPressed: () =>
                            onUpdateStatus(invoice.id, 'void'),
                        icon: const Icon(Icons.cancel, size: 18),
                        label: const Text('Void'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}

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
