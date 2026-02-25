import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';
import '../../app/design_tokens.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/orders/orders_bloc.dart';
import '../../repositories/order_repository.dart';
import '../../widgets/navigation/admin_shell.dart';

class OrderManagementScreen extends StatelessWidget {
  const OrderManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrdersBloc(
        orderRepository: context.read<OrderRepository>(),
      )..add(const OrdersFetchRequested()),
      child: const AdminShell(
        selectedIndex: 0,
        child: _OrderManagementContent(),
      ),
    );
  }
}

class _OrderManagementContent extends StatefulWidget {
  const _OrderManagementContent();

  @override
  State<_OrderManagementContent> createState() =>
      _OrderManagementContentState();
}

class _OrderManagementContentState extends State<_OrderManagementContent> {
  ProductLanguage? _languageFilter;
  OrderStatus? _statusFilter;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              context
                  .read<OrdersBloc>()
                  .add(const OrdersFetchRequested());
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          _FilterBar(
            languageFilter: _languageFilter,
            statusFilter: _statusFilter,
            searchQuery: _searchQuery,
            onLanguageChanged: (lang) =>
                setState(() => _languageFilter = lang),
            onStatusChanged: (status) =>
                setState(() => _statusFilter = status),
            onSearchChanged: (query) =>
                setState(() => _searchQuery = query),
          ),
          const Divider(height: 1),
          // Orders table
          Expanded(
            child: BlocBuilder<OrdersBloc, OrdersState>(
              builder: (context, state) {
                if (state is OrdersLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is OrdersFailure) {
                  return Center(child: Text('Error: ${state.message}'));
                }
                if (state is OrdersLoaded) {
                  final filtered = _applyFilters(state.orders);
                  if (filtered.isEmpty) {
                    return const Center(child: Text('No orders match filters'));
                  }
                  return _OrdersTable(
                    orders: filtered,
                    currentUserRole: user?.role,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Order> _applyFilters(List<Order> orders) {
    var result = orders;
    if (_languageFilter != null) {
      result = result.where((o) => o.language == _languageFilter).toList();
    }
    if (_statusFilter != null) {
      result = result.where((o) => o.status == _statusFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((o) {
        return o.id.toLowerCase().contains(q) ||
            (o.displayOrderNumber?.toLowerCase().contains(q) ?? false) ||
            (o.discordName?.toLowerCase().contains(q) ?? false) ||
            o.shippingAddress.fullName.toLowerCase().contains(q) ||
            o.items.any(
                (item) => item.productName.toLowerCase().contains(q));
      }).toList();
    }
    return result;
  }
}

class _FilterBar extends StatelessWidget {
  final ProductLanguage? languageFilter;
  final OrderStatus? statusFilter;
  final String searchQuery;
  final ValueChanged<ProductLanguage?> onLanguageChanged;
  final ValueChanged<OrderStatus?> onStatusChanged;
  final ValueChanged<String> onSearchChanged;

  const _FilterBar({
    required this.languageFilter,
    required this.statusFilter,
    required this.searchQuery,
    required this.onLanguageChanged,
    required this.onStatusChanged,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 200,
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search orders...',
                prefixIcon: Icon(Icons.search, size: 20),
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              onChanged: onSearchChanged,
            ),
          ),
          DropdownButton<ProductLanguage?>(
            value: languageFilter,
            hint: const Text('All Languages'),
            underline: const SizedBox.shrink(),
            items: [
              const DropdownMenuItem(value: null, child: Text('All Languages')),
              ...ProductLanguage.values.map(
                (l) => DropdownMenuItem(
                  value: l,
                  child: Text(l.name.toUpperCase()),
                ),
              ),
            ],
            onChanged: onLanguageChanged,
          ),
          DropdownButton<OrderStatus?>(
            value: statusFilter,
            hint: const Text('All Statuses'),
            underline: const SizedBox.shrink(),
            items: [
              const DropdownMenuItem(value: null, child: Text('All Statuses')),
              ...OrderStatus.values.map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(Tokens.statusLabel(s)),
                ),
              ),
            ],
            onChanged: onStatusChanged,
          ),
        ],
      ),
    );
  }
}

class _OrdersTable extends StatelessWidget {
  final List<Order> orders;
  final UserRole? currentUserRole;

  const _OrdersTable({
    required this.orders,
    this.currentUserRole,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columnSpacing: 16,
          headingRowColor: WidgetStateProperty.all(
            theme.colorScheme.surfaceContainerHighest,
          ),
          columns: const [
            DataColumn(label: Text('Order #')),
            DataColumn(label: Text('Language')),
            DataColumn(label: Text('Customer')),
            DataColumn(label: Text('Discord')),
            DataColumn(label: Text('Items')),
            DataColumn(label: Text('Total'), numeric: true),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Shipping')),
            DataColumn(label: Text('Tracking')),
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Actions')),
          ],
          rows: orders.map((order) => _buildRow(context, order)).toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(BuildContext context, Order order) {
    final displayId = order.displayOrderNumber ??
        order.id.substring(0, order.id.length.clamp(0, 8));

    return DataRow(
      cells: [
        DataCell(
          Text(displayId, style: const TextStyle(fontWeight: FontWeight.w500)),
          onTap: () => context.push('/orders/${order.id}'),
        ),
        DataCell(_LanguageBadge(language: order.language)),
        DataCell(Text(order.shippingAddress.fullName)),
        DataCell(Text(order.discordName ?? '-')),
        DataCell(Text('${order.items.length}')),
        DataCell(Text('\$${order.totalAmount.toStringAsFixed(2)}')),
        DataCell(_StatusChip(
          order: order,
          onStatusChanged: currentUserRole == UserRole.wholesaler
              ? null
              : (newStatus) {
                  context.read<OrdersBloc>().add(
                        OrderStatusUpdateRequested(
                          orderId: order.id,
                          status: newStatus,
                        ),
                      );
                },
        )),
        DataCell(Text(order.shippingMethod ?? '-')),
        DataCell(
          order.trackingNumber != null
              ? Text(order.trackingNumber!)
              : const Text('-'),
        ),
        DataCell(Text(_formatDate(order.createdAt))),
        DataCell(_ActionButtons(order: order)),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}

class _LanguageBadge extends StatelessWidget {
  final ProductLanguage language;
  const _LanguageBadge({required this.language});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (language) {
      ProductLanguage.japanese => ('JPN', Colors.red.shade100),
      ProductLanguage.chinese => ('CN', Colors.amber.shade100),
      ProductLanguage.korean => ('KR', Colors.blue.shade100),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final Order order;
  final ValueChanged<OrderStatus>? onStatusChanged;

  const _StatusChip({required this.order, this.onStatusChanged});

  @override
  Widget build(BuildContext context) {
    if (onStatusChanged == null) {
      // Read-only chip
      return Chip(
        label: Text(Tokens.statusLabel(order.status),
            style: const TextStyle(fontSize: 12)),
        backgroundColor: Tokens.statusColor(order.status).withValues(alpha: 0.15),
        side: BorderSide.none,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      );
    }

    // Admin: dropdown to change status
    return PopupMenuButton<OrderStatus>(
      tooltip: 'Change status',
      child: Chip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(Tokens.statusLabel(order.status),
                style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 16),
          ],
        ),
        backgroundColor:
            Tokens.statusColor(order.status).withValues(alpha: 0.15),
        side: BorderSide.none,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
      itemBuilder: (context) {
        // Show next valid statuses
        return _nextStatuses(order.status)
            .map((s) => PopupMenuItem(
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
                      Text(Tokens.statusLabel(s)),
                    ],
                  ),
                ))
            .toList();
      },
      onSelected: onStatusChanged,
    );
  }

  List<OrderStatus> _nextStatuses(OrderStatus current) {
    if (current == OrderStatus.delivered ||
        current == OrderStatus.cancelled) {
      return [];
    }

    const progression = [
      OrderStatus.submitted,
      OrderStatus.awaitingQuote,
      OrderStatus.invoiced,
      OrderStatus.paymentPending,
      OrderStatus.paymentReceived,
      OrderStatus.shipped,
      OrderStatus.delivered,
    ];

    final currentIdx = progression.indexOf(current);
    final forward = currentIdx >= 0
        ? progression.sublist(currentIdx + 1)
        : <OrderStatus>[];

    return [...forward, OrderStatus.cancelled];
  }
}

class _ActionButtons extends StatelessWidget {
  final Order order;
  const _ActionButtons({required this.order});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.visibility, size: 18),
          tooltip: 'View details',
          visualDensity: VisualDensity.compact,
          onPressed: () => context.push('/orders/${order.id}'),
        ),
      ],
    );
  }
}
