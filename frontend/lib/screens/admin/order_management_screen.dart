import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ws_seeker_frontend/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';
import '../../app/design_tokens.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/orders/orders_bloc.dart';
import '../../repositories/order_repository.dart';
import '../../repositories/user_repository.dart';
import '../../widgets/common/theme_toggle_button.dart';
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
  String? _accountManagerFilter;
  String _searchQuery = '';
  int? _sortColumnIndex;
  bool _sortAscending = true;
  bool _filtersExpanded = true;
  final _searchController = TextEditingController();

  /// Map of managerId → display name for account managers
  Map<String, String> _managerNames = {};
  bool _managersLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadManagers();
  }

  Future<void> _loadManagers() async {
    try {
      final userRepo = context.read<UserRepository>();
      final users = await userRepo.listUsers();
      if (!mounted) return;
      setState(() {
        _managerNames = {
          for (final u in users.where((u) =>
              u.role == UserRole.superUser || u.role == UserRole.supplier))
            u.id: u.discordName ?? u.email,
        };
        _managersLoaded = true;
      });
    } catch (_) {
      // Silently fail — filter just won't appear
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters =>
      _languageFilter != null ||
      _statusFilter != null ||
      _accountManagerFilter != null ||
      _searchQuery.isNotEmpty;

  void _clearAllFilters() {
    setState(() {
      _languageFilter = null;
      _statusFilter = null;
      _accountManagerFilter = null;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
            ? l10n.japaneseOrders
            : l10n.orderManagement),
        actions: [
          const ThemeToggleButton(),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.actionRefresh,
            onPressed: () {
              context
                  .read<OrdersBloc>()
                  .add(const OrdersFetchRequested());
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l10n.actionLogout,
            onPressed: () {
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Collapsible filter bar
          _CollapsibleFilterBar(
            expanded: _filtersExpanded,
            onToggle: () =>
                setState(() => _filtersExpanded = !_filtersExpanded),
            activeFilterCount: (_languageFilter != null ? 1 : 0) +
                (_statusFilter != null ? 1 : 0) +
                (_accountManagerFilter != null ? 1 : 0) +
                (_searchQuery.isNotEmpty ? 1 : 0),
            child: _FilterBar(
              languageFilter: _languageFilter,
              statusFilter: _statusFilter,
              accountManagerFilter: _accountManagerFilter,
              managerNames: _managerNames,
              showManagerFilter:
                  user?.role == UserRole.superUser && _managersLoaded,
              searchController: _searchController,
              showLanguageFilter: user?.role != UserRole.supplier,
              hasActiveFilters: _hasActiveFilters,
              onLanguageChanged: (lang) =>
                  setState(() => _languageFilter = lang),
              onStatusChanged: (status) =>
                  setState(() => _statusFilter = status),
              onAccountManagerChanged: (id) =>
                  setState(() => _accountManagerFilter = id),
              onSearchChanged: (query) =>
                  setState(() => _searchQuery = query),
              onClearAll: _clearAllFilters,
            ),
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
                  return Center(
                      child: Text(l10n.errorWithMessage(state.message)));
                }
                if (state is OrdersLoaded) {
                  var filtered = _applyFilters(state.orders);
                  filtered = _sortOrders(filtered);
                  if (filtered.isEmpty) {
                    return Center(child: Text(l10n.noOrdersMatchFilters));
                  }
                  return _OrdersTable(
                    orders: filtered,
                    currentUserRole: user?.role,
                    managerNames: _managerNames,
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
    if (_accountManagerFilter != null) {
      result = result
          .where((o) => o.accountManagerId == _accountManagerFilter)
          .toList();
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
        keyOf = (o) => _managerNames[o.accountManagerId] ?? '';
      case 5:
        keyOf = (o) => o.items.length;
      case 6:
        keyOf = (o) => o.totalAmount;
      case 7:
        keyOf = (o) => o.status.index;
      case 8:
        keyOf = (o) => o.shippingMethod ?? '';
      case 9:
        keyOf = (o) => o.trackingNumber ?? '';
      case 10:
        keyOf = (o) => o.createdAt;
      case 11:
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

class _CollapsibleFilterBar extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;
  final int activeFilterCount;
  final Widget child;

  const _CollapsibleFilterBar({
    required this.expanded,
    required this.onToggle,
    required this.activeFilterCount,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  expanded
                      ? Icons.filter_list_off
                      : Icons.filter_list,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.searchAndFilters,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (activeFilterCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$activeFilterCount',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: expanded ? child : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  final ProductLanguage? languageFilter;
  final OrderStatus? statusFilter;
  final String? accountManagerFilter;
  final Map<String, String> managerNames;
  final bool showManagerFilter;
  final TextEditingController searchController;
  final bool showLanguageFilter;
  final bool hasActiveFilters;
  final ValueChanged<ProductLanguage?> onLanguageChanged;
  final ValueChanged<OrderStatus?> onStatusChanged;
  final ValueChanged<String?> onAccountManagerChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearAll;

  const _FilterBar({
    required this.languageFilter,
    required this.statusFilter,
    this.accountManagerFilter,
    this.managerNames = const {},
    this.showManagerFilter = false,
    required this.searchController,
    this.showLanguageFilter = true,
    required this.hasActiveFilters,
    required this.onLanguageChanged,
    required this.onStatusChanged,
    required this.onAccountManagerChanged,
    required this.onSearchChanged,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                    hintText: l10n.searchOrders,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            tooltip: l10n.clearSearch,
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
                  label: Text(l10n.clearFilters),
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
                Text(l10n.filterLanguage,
                    style: const TextStyle(fontSize: 12)),
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
              Text(l10n.filterStatus, style: const TextStyle(fontSize: 12)),
              ...OrderStatus.values.map(
                (status) => FilterChip(
                  label: Text(localizedStatusLabel(status, l10n)),
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
          if (showManagerFilter && managerNames.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(l10n.filterAccountManager,
                    style: const TextStyle(fontSize: 12)),
                FilterChip(
                  label: Text(l10n.filterAll),
                  selected: accountManagerFilter == null,
                  onSelected: (_) => onAccountManagerChanged(null),
                  visualDensity: VisualDensity.compact,
                ),
                ...managerNames.entries.map(
                  (entry) => FilterChip(
                    label: Text(entry.value),
                    selected: accountManagerFilter == entry.key,
                    onSelected: (selected) =>
                        onAccountManagerChanged(selected ? entry.key : null),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _OrdersTable extends StatefulWidget {
  final List<Order> orders;
  final UserRole? currentUserRole;
  final Map<String, String> managerNames;
  final int? sortColumnIndex;
  final bool sortAscending;
  final void Function(int columnIndex, bool ascending) onSort;

  const _OrdersTable({
    required this.orders,
    this.currentUserRole,
    this.managerNames = const {},
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
    final l10n = AppLocalizations.of(context);
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
                  sortableColumn(l10n.columnOrderNumber),
                  sortableColumn(l10n.columnLanguage),
                  sortableColumn(l10n.columnCustomer),
                  sortableColumn(l10n.columnDiscord),
                  sortableColumn(l10n.columnAcctManager),
                  sortableColumn(l10n.columnItems),
                  sortableColumn(l10n.columnTotal, numeric: true),
                  sortableColumn(l10n.columnStatus),
                  sortableColumn(l10n.columnShipping),
                  sortableColumn(l10n.columnTracking),
                  sortableColumn(l10n.columnCreated),
                  sortableColumn(l10n.columnModified),
                  DataColumn(label: Text(l10n.columnActions)),
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
    final l10n = AppLocalizations.of(context);
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
        DataCell(Text(
            widget.managerNames[order.accountManagerId] ?? '-')),
        DataCell(Text('${order.items.length}')),
        DataCell(Text(order.quoteRequired
            ? l10n.quoteNeeded
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
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (label, bg, fg) = switch (language) {
      ProductLanguage.japanese => (l10n.langJPN,
          isDark ? Colors.red.shade900 : Colors.red.shade100,
          isDark ? Colors.red.shade100 : Colors.red.shade900),
      ProductLanguage.chinese => (l10n.langCN,
          isDark ? Colors.amber.shade900 : Colors.amber.shade100,
          isDark ? Colors.amber.shade100 : Colors.amber.shade900),
      ProductLanguage.korean => (l10n.langKR,
          isDark ? Colors.blue.shade900 : Colors.blue.shade100,
          isDark ? Colors.blue.shade100 : Colors.blue.shade900),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final Order order;
  final ValueChanged<OrderStatus>? onStatusChanged;

  const _StatusChip({required this.order, this.onStatusChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (onStatusChanged == null) {
      // Read-only chip
      return Chip(
        label: Text(localizedStatusLabel(order.status, l10n),
            style: const TextStyle(fontSize: 12)),
        backgroundColor: Tokens.statusColor(order.status).withValues(alpha: 0.15),
        side: BorderSide.none,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      );
    }

    // Admin: dropdown to change status
    return PopupMenuButton<OrderStatus>(
      tooltip: l10n.changeStatus,
      child: Chip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(localizedStatusLabel(order.status, l10n),
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
        final innerL10n = AppLocalizations.of(context);
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
                      Text(localizedStatusLabel(s, innerL10n)),
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
    final l10n = AppLocalizations.of(context);
    final displayId = order.displayOrderNumber ?? order.id;
    showDialog<bool>(
      context: context,
      builder: (ctx) {
        final dialogL10n = AppLocalizations.of(ctx);
        return AlertDialog(
          title: Text(dialogL10n.deleteOrder),
          content: Text(dialogL10n.deleteOrderConfirmation(displayId)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(dialogL10n.actionCancel),
            ),
            FilledButton(
              style:
                  FilledButton.styleFrom(backgroundColor: Tokens.destructive),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(dialogL10n.actionDelete),
            ),
          ],
        );
      },
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
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.visibility, size: 18),
          tooltip: l10n.viewDetails,
          visualDensity: VisualDensity.compact,
          onPressed: () => context.push('/orders/${order.id}'),
        ),
        IconButton(
          icon: Icon(Icons.delete_outline, size: 18, color: Tokens.destructive),
          tooltip: l10n.deleteOrderTooltip,
          visualDensity: VisualDensity.compact,
          onPressed: () => _confirmDelete(context),
        ),
      ],
    );
  }
}
