import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ws_seeker_frontend/l10n/app_localizations.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';

import '../../app/design_tokens.dart';
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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.auditLogs),
        actions: [
          const ThemeToggleButton(),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.actionRefresh,
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
                      ? Center(child: Text(l10n.noAuditLogsFound))
                      : _buildLogsList(context, logs, total, isLoadingMore),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
              decoration: InputDecoration(
                hintText: l10n.searchPlaceholder,
                prefixIcon: const Icon(Icons.search, size: 20),
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              onSubmitted: (_) => _applyFilters(),
            ),
          ),
          DropdownButton<String?>(
            value: _actionFilter,
            hint: Text(l10n.allActions),
            underline: const SizedBox.shrink(),
            items: [
              DropdownMenuItem(value: null, child: Text(l10n.allActions)),
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
            hint: Text(l10n.allResources),
            underline: const SizedBox.shrink(),
            items: [
              DropdownMenuItem(
                  value: null, child: Text(l10n.allResources)),
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
                : l10n.dateRange),
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
              tooltip: l10n.clearDateRange,
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
    final l10n = AppLocalizations.of(context);
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
                      child: Text(l10n.loadMore(logs.length, total)),
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
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final detailStr = _formatDetails(l10n, log.action, log.details);

    final resourceLabel = _resourceLabel(log);

    return ListTile(
      leading: _actionIcon(context, log.action),
      title: Text(_actionLabel(l10n, log.action),
          style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('by ${log.userEmail}${resourceLabel.isNotEmpty ? ' · $resourceLabel' : ''}'),
          if (detailStr.isNotEmpty)
            Text(
              detailStr,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: SemanticColors.of(context).textSecondary),
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

  static String _actionLabel(AppLocalizations l10n, String action) {
    return switch (action) {
      'order.created' => l10n.actionOrderCreated,
      'order.updated' => l10n.actionOrderUpdated,
      'order.deleted' => l10n.actionOrderDeleted,
      'comment.created' => l10n.actionCommentAdded,
      'product.created' => l10n.actionProductCreated,
      'product.updated' => l10n.actionProductUpdated,
      'product.deleted' => l10n.actionProductDeleted,
      'product.imported' => l10n.actionProductsImported,
      'invoice.generated' => l10n.actionInvoiceGenerated,
      'invoice.statusUpdated' => l10n.actionInvoiceStatusUpdated,
      'user.profileUpdated' => l10n.actionProfileUpdated,
      'auth.login' => l10n.actionUserLoggedIn,
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
            final from = _localizedStatusLabel(l10n, arrow[0]);
            final to = _localizedStatusLabel(l10n, arrow[1]);
            parts.add('$from \u2192 $to');
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
    return parts.join(' \u00b7 ');
  }

  static String _localizedStatusLabel(AppLocalizations l10n, String status) {
    return switch (status) {
      'submitted' => l10n.statusSubmitted,
      'awaiting_quote' => l10n.statusAwaitingQuote,
      'invoiced' => l10n.statusInvoiceSent,
      'payment_pending' => l10n.statusPaymentPending,
      'payment_received' => l10n.statusPaymentReceived,
      'shipped' => l10n.statusShipped,
      'delivered' => l10n.statusDelivered,
      'cancelled' => l10n.statusCancelled,
      _ => status,
    };
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
