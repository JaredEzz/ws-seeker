import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';

import '../../blocs/audit_logs/audit_logs_bloc.dart';
import '../../repositories/audit_log_repository.dart';
import '../../widgets/common/theme_toggle_button.dart';
import '../../widgets/navigation/admin_shell.dart';

class AuditLogsScreen extends StatelessWidget {
  const AuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuditLogsBloc(
        repository: context.read<AuditLogRepository>(),
      )..add(const AuditLogsFetchRequested(query: AuditLogQuery())),
      child: const AdminShell(
        selectedIndex: 5,
        child: _AuditLogsContent(),
      ),
    );
  }
}

class _AuditLogsContent extends StatefulWidget {
  const _AuditLogsContent();

  @override
  State<_AuditLogsContent> createState() => _AuditLogsContentState();
}

class _AuditLogsContentState extends State<_AuditLogsContent> {
  final _searchController = TextEditingController();
  String? _actionFilter;
  String? _resourceTypeFilter;
  DateTimeRange? _dateRange;

  static const _actionOptions = [
    'order.created',
    'order.updated',
    'product.created',
    'product.updated',
    'product.deleted',
    'product.imported',
    'invoice.generated',
    'invoice.statusUpdated',
    'user.profileUpdated',
    'comment.created',
    'auth.login',
  ];

  static const _resourceTypes = [
    'order',
    'product',
    'invoice',
    'user',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    context.read<AuditLogsBloc>().add(AuditLogsFetchRequested(
          query: AuditLogQuery(
            action: _actionFilter,
            resourceType: _resourceTypeFilter,
            search: _searchController.text.isNotEmpty
                ? _searchController.text
                : null,
            startDate: _dateRange?.start,
            endDate: _dateRange?.end,
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Logs'),
        actions: [
          const ThemeToggleButton(),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _applyFilters,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(context),
          const Divider(height: 1),
          Expanded(
            child: BlocBuilder<AuditLogsBloc, AuditLogsState>(
              builder: (context, state) => switch (state) {
                AuditLogsInitial() => const SizedBox.shrink(),
                AuditLogsLoading() =>
                  const Center(child: CircularProgressIndicator()),
                AuditLogsFailure(:final message) =>
                  Center(child: Text('Error: $message')),
                AuditLogsLoaded(
                  :final logs,
                  :final total,
                  :final isLoadingMore
                ) =>
                  logs.isEmpty
                      ? const Center(child: Text('No audit logs found.'))
                      : _buildLogsList(context, logs, total, isLoadingMore),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 220,
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search...',
                prefixIcon: Icon(Icons.search, size: 20),
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              onSubmitted: (_) => _applyFilters(),
            ),
          ),
          DropdownButton<String?>(
            value: _actionFilter,
            hint: const Text('All Actions'),
            underline: const SizedBox.shrink(),
            items: [
              const DropdownMenuItem(value: null, child: Text('All Actions')),
              ..._actionOptions
                  .map((a) => DropdownMenuItem(value: a, child: Text(a))),
            ],
            onChanged: (value) {
              setState(() => _actionFilter = value);
              _applyFilters();
            },
          ),
          DropdownButton<String?>(
            value: _resourceTypeFilter,
            hint: const Text('All Resources'),
            underline: const SizedBox.shrink(),
            items: [
              const DropdownMenuItem(
                  value: null, child: Text('All Resources')),
              ..._resourceTypes.map((r) => DropdownMenuItem(
                    value: r,
                    child: Text(r[0].toUpperCase() + r.substring(1)),
                  )),
            ],
            onChanged: (value) {
              setState(() => _resourceTypeFilter = value);
              _applyFilters();
            },
          ),
          TextButton.icon(
            icon: const Icon(Icons.date_range, size: 18),
            label: Text(_dateRange != null
                ? '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}'
                : 'Date Range'),
            onPressed: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
                initialDateRange: _dateRange,
              );
              if (range != null) {
                setState(() => _dateRange = range);
                _applyFilters();
              }
            },
          ),
          if (_dateRange != null)
            IconButton(
              icon: const Icon(Icons.clear, size: 18),
              tooltip: 'Clear date range',
              onPressed: () {
                setState(() => _dateRange = null);
                _applyFilters();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLogsList(
    BuildContext context,
    List<AuditLog> logs,
    int total,
    bool isLoadingMore,
  ) {
    final hasMore = logs.length < total;
    return ListView.builder(
      itemCount: logs.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == logs.length) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: isLoadingMore
                  ? const CircularProgressIndicator()
                  : OutlinedButton(
                      onPressed: () {
                        context
                            .read<AuditLogsBloc>()
                            .add(const AuditLogsNextPageRequested());
                      },
                      child: Text('Load More (${logs.length}/$total)'),
                    ),
            ),
          );
        }

        final log = logs[index];
        return _AuditLogTile(log: log);
      },
    );
  }

  String _formatDate(DateTime dt) => '${dt.month}/${dt.day}/${dt.year}';
}

class _AuditLogTile extends StatelessWidget {
  final AuditLog log;
  const _AuditLogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detailStr = _formatDetails(log.action, log.details);

    final resourceLabel = _resourceLabel(log);

    return ListTile(
      leading: _actionIcon(context, log.action),
      title: Text(_actionLabel(log.action),
          style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('by ${log.userEmail}${resourceLabel.isNotEmpty ? ' · $resourceLabel' : ''}'),
          if (detailStr.isNotEmpty)
            Text(
              detailStr,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      trailing: Text(
        _formatTimestamp(log.createdAt),
        style: theme.textTheme.bodySmall,
      ),
      isThreeLine: detailStr.isNotEmpty,
    );
  }

  /// Derive a user-friendly resource label (e.g. "CN1") from audit details.
  static String _resourceLabel(AuditLog log) {
    // Order actions: backend stores displayOrderNumber in details
    final displayNum = log.details?['displayOrderNumber'];
    if (displayNum != null) return displayNum.toString();

    // Product actions: use product name if available
    final productName = log.details?['productName'] ?? log.details?['name'];
    if (productName != null) return productName.toString();

    return '';
  }

  static String _actionLabel(String action) {
    return switch (action) {
      'order.created' => 'Order Created',
      'order.updated' => 'Order Updated',
      'order.deleted' => 'Order Deleted',
      'comment.created' => 'Comment Added',
      'product.created' => 'Product Created',
      'product.updated' => 'Product Updated',
      'product.deleted' => 'Product Deleted',
      'product.imported' => 'Products Imported',
      'invoice.generated' => 'Invoice Generated',
      'invoice.statusUpdated' => 'Invoice Status Updated',
      'user.profileUpdated' => 'Profile Updated',
      'auth.login' => 'User Logged In',
      _ => action,
    };
  }

  static const _statusLabels = {
    'submitted': 'Submitted',
    'awaiting_quote': 'Awaiting Quote',
    'invoiced': 'Invoice Sent',
    'payment_pending': 'Payment Pending',
    'payment_received': 'Payment Received',
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
            parts.add('$from → $to');
          } else {
            parts.add(raw);
          }
        case 'language':
          parts.add(entry.value.toString().toUpperCase());
        case 'itemCount':
          parts.add('${entry.value} item${entry.value == 1 ? '' : 's'}');
        case 'productCount':
          parts.add('${entry.value} product${entry.value == 1 ? '' : 's'}');
        case 'commentId':
        case 'displayOrderNumber':
        case 'productName':
        case 'name':
          break; // shown in resource label or not useful
        default:
          parts.add('${entry.key}: ${entry.value}');
      }
    }
    return parts.join(' · ');
  }

  Widget _actionIcon(BuildContext context, String action) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (icon, color) = switch (action.split('.').first) {
      'order' => (Icons.receipt_long, isDark ? Colors.blue.shade300 : Colors.blue),
      'product' => (Icons.inventory_2, isDark ? Colors.green.shade300 : Colors.green),
      'invoice' => (Icons.description, isDark ? Colors.orange.shade300 : Colors.orange),
      'user' => (Icons.person, isDark ? Colors.purple.shade300 : Colors.purple),
      'auth' => (Icons.login, isDark ? Colors.teal.shade300 : Colors.teal),
      'comment' => (Icons.comment, isDark ? Colors.indigo.shade300 : Colors.indigo),
      _ => (Icons.info, isDark ? Colors.grey.shade300 : Colors.grey),
    };

    return CircleAvatar(
      backgroundColor: color.withValues(alpha: isDark ? 0.2 : 0.12),
      child: Icon(icon, color: color, size: 20),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
