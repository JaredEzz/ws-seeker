import 'package:flutter/gestures.dart';
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
  int? _sortColumnIndex;
  bool _sortAscending = true;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters =>
      _languageFilter != null ||
      _statusFilter != null ||
      _searchQuery.isNotEmpty;

  void _clearAllFilters() {
    setState(() {
      _languageFilter = null;
      _statusFilter = null;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    return BlocListener<OrdersBloc, OrdersState>(
      listener: (context, state) {
        if (state is OrderActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is OrdersFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Tokens.destructive,
            ),
          );
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(user?.role == UserRole.supplier
            ? 'Japanese Orders'
            : 'Order Management'),
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
            searchController: _searchController,
            showLanguageFilter: user?.role != UserRole.supplier,
            hasActiveFilters: _hasActiveFilters,
            onLanguageChanged: (lang) =>
                setState(() => _languageFilter = lang),
            onStatusChanged: (status) =>
                setState(() => _statusFilter = status),
            onSearchChanged: (query) =>
                setState(() => _searchQuery = query),
            onClearAll: _clearAllFilters,
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
                  var filtered = _applyFilters(state.orders);
                  filtered = _sortOrders(filtered);
                  if (filtered.isEmpty) {
                    return const Center(child: Text('No orders match filters'));
                  }
                  return _OrdersTable(
                    orders: filtered,
                    currentUserRole: user?.role,
                    sortColumnIndex: _sortColumnIndex,
                    sortAscending: _sortAscending,
                    onSort: (colIdx, asc) {
                      setState(() {
                        _sortColumnIndex = colIdx;
                        _sortAscending = asc;
                      });
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
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

  List<Order> _sortOrders(List<Order> orders) {
    if (_sortColumnIndex == null) return orders;

    final sorted = List<Order>.of(orders);
    Comparable Function(Order) keyOf;

    switch (_sortColumnIndex!) {
      case 0:
        keyOf = (o) => o.displayOrderNumber ?? o.id;
      case 1:
        keyOf = (o) => o.language.name;
      case 2:
        keyOf = (o) => o.shippingAddress.fullName;
      case 3:
        keyOf = (o) => o.discordName ?? '';
      case 4:
        keyOf = (o) => o.items.length;
      case 5:
        keyOf = (o) => o.totalAmount;
      case 6:
        keyOf = (o) => o.status.index;
      case 7:
        keyOf = (o) => o.shippingMethod ?? '';
      case 8:
        keyOf = (o) => o.trackingNumber ?? '';
      case 9:
        keyOf = (o) => o.createdAt;
      case 10:
        keyOf = (o) => o.updatedAt;
      default:
        return orders;
    }

    sorted.sort((a, b) {
      final cmp = keyOf(a).compareTo(keyOf(b));
      return _sortAscending ? cmp : -cmp;
    });
    return sorted;
  }
}

class _FilterBar extends StatelessWidget {
  final ProductLanguage? languageFilter;
  final OrderStatus? statusFilter;
  final TextEditingController searchController;
  final bool showLanguageFilter;
  final bool hasActiveFilters;
  final ValueChanged<ProductLanguage?> onLanguageChanged;
  final ValueChanged<OrderStatus?> onStatusChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearAll;

  const _FilterBar({
    required this.languageFilter,
    required this.statusFilter,
    required this.searchController,
    this.showLanguageFilter = true,
    required this.hasActiveFilters,
    required this.onLanguageChanged,
    required this.onStatusChanged,
    required this.onSearchChanged,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search row
          Row(
            children: [
              SizedBox(
                width: 240,
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search orders...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            tooltip: 'Clear search',
                            onPressed: () {
                              searchController.clear();
                              onSearchChanged('');
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  onChanged: onSearchChanged,
                ),
              ),
              if (hasActiveFilters) ...[
                const SizedBox(width: 12),
                TextButton.icon(
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Clear filters'),
                  onPressed: onClearAll,
                ),
              ],
            ],
          ),
          if (showLanguageFilter) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Language:', style: TextStyle(fontSize: 12)),
                ...ProductLanguage.values.map(
                  (lang) => FilterChip(
                    label: Text(lang.name.toUpperCase()),
                    selected: languageFilter == lang,
                    onSelected: (selected) =>
                        onLanguageChanged(selected ? lang : null),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Status:', style: TextStyle(fontSize: 12)),
              ...OrderStatus.values.map(
                (status) => FilterChip(
                  label: Text(Tokens.statusLabel(status)),
                  selected: statusFilter == status,
                  selectedColor:
                      Tokens.statusColor(status).withValues(alpha: 0.25),
                  onSelected: (selected) =>
                      onStatusChanged(selected ? status : null),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrdersTable extends StatefulWidget {
  final List<Order> orders;
  final UserRole? currentUserRole;
  final int? sortColumnIndex;
  final bool sortAscending;
  final void Function(int columnIndex, bool ascending) onSort;

  const _OrdersTable({
    required this.orders,
    this.currentUserRole,
    required this.sortColumnIndex,
    required this.sortAscending,
    required this.onSort,
  });

  @override
  State<_OrdersTable> createState() => _OrdersTableState();
}

class _OrdersTableState extends State<_OrdersTable> {
  final _horizontalController = ScrollController();
  final _verticalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    DataColumn sortableColumn(String label, {bool numeric = false}) {
      return DataColumn(
        label: Text(label),
        numeric: numeric,
        onSort: widget.onSort,
      );
    }

    final stripe = theme.colorScheme.surfaceContainerLow;

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        },
      ),
      child: Scrollbar(
        controller: _verticalController,
        thumbVisibility: true,
        child: Scrollbar(
          controller: _horizontalController,
          thumbVisibility: true,
          notificationPredicate: (notification) => notification.depth == 1,
          child: SingleChildScrollView(
            controller: _verticalController,
            child: SingleChildScrollView(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                sortColumnIndex: widget.sortColumnIndex,
                sortAscending: widget.sortAscending,
                headingRowColor: WidgetStateProperty.all(
                  theme.colorScheme.surfaceContainerHighest,
                ),
                dataRowColor:
                    WidgetStateProperty.resolveWith((states) => null),
                columns: [
                  sortableColumn('Order #'),
                  sortableColumn('Language'),
                  sortableColumn('Customer'),
                  sortableColumn('Discord'),
                  sortableColumn('Items'),
                  sortableColumn('Total', numeric: true),
                  sortableColumn('Status'),
                  sortableColumn('Shipping'),
                  sortableColumn('Tracking'),
                  sortableColumn('Created'),
                  sortableColumn('Modified'),
                  const DataColumn(label: Text('Actions')),
                ],
                rows: widget.orders
                    .asMap()
                    .entries
                    .map((entry) => _buildRow(
                          context,
                          entry.value,
                          stripe: entry.key.isOdd ? stripe : null,
                        ))
                    .toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildRow(BuildContext context, Order order, {Color? stripe}) {
    final displayId = order.displayOrderNumber ?? order.id;

    return DataRow(
      color: stripe != null
          ? WidgetStateProperty.all(stripe)
          : null,
      cells: [
        DataCell(
          Text(displayId, style: const TextStyle(fontWeight: FontWeight.w500)),
          onTap: () => context.push('/orders/${order.id}'),
        ),
        DataCell(_LanguageBadge(language: order.language)),
        DataCell(Text(order.shippingAddress.fullName)),
        DataCell(Text(order.discordName ?? '-')),
        DataCell(Text('${order.items.length}')),
        DataCell(Text(order.quoteRequired
            ? 'Quote Needed'
            : '\$${order.totalAmount.toStringAsFixed(2)}')),
        DataCell(_StatusChip(
          order: order,
          onStatusChanged: widget.currentUserRole == UserRole.superUser
              ? (newStatus) {
                  context.read<OrdersBloc>().add(
                        OrderStatusUpdateRequested(
                          orderId: order.id,
                          status: newStatus,
                        ),
                      );
                }
              : null,
        )),
        DataCell(Text(order.shippingMethod ?? '-')),
        DataCell(
          order.trackingNumber != null
              ? Text(order.trackingNumber!)
              : const Text('-'),
        ),
        DataCell(Text(_formatDate(order.createdAt))),
        DataCell(Text(_formatDate(order.updatedAt))),
        DataCell(_ActionButtons(order: order)),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final m = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour < 12 ? 'AM' : 'PM';
    return '${local.month}/${local.day}/${local.year} $h:$m $ampm';
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
    // Admin can move orders to any status (except the current one)
    return OrderStatus.values.where((s) => s != current).toList();
  }
}

class _ActionButtons extends StatelessWidget {
  final Order order;
  const _ActionButtons({required this.order});

  void _confirmDelete(BuildContext context) {
    final displayId = order.displayOrderNumber ?? order.id;
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Order'),
        content: Text('Are you sure you want to delete order "$displayId"? '
            'This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Tokens.destructive),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        context.read<OrdersBloc>().add(
              OrderDeleteRequested(orderId: order.id),
            );
      }
    });
  }

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
        IconButton(
          icon: Icon(Icons.delete_outline, size: 18, color: Tokens.destructive),
          tooltip: 'Delete order',
          visualDensity: VisualDensity.compact,
          onPressed: () => _confirmDelete(context),
        ),
      ],
    );
  }
}
