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
import '../../widgets/common/theme_toggle_button.dart';
import '../../widgets/navigation/adaptive_navigation.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<OrdersBloc>().add(const OrdersFetchRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    return AdaptiveNavigation(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) context.push('/place-order');
          if (index == 2) context.push('/chats');
          if (index == 3) {
            if (user?.role == UserRole.superUser || user?.role == UserRole.supplier) {
              context.go('/admin/orders');
            } else {
              context.push('/profile');
            }
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: l10n.navDashboard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.add_shopping_cart_outlined),
            selectedIcon: const Icon(Icons.add_shopping_cart),
            label: l10n.navNewOrder,
          ),
          NavigationDestination(
            icon: const Icon(Icons.chat_outlined),
            selectedIcon: const Icon(Icons.chat),
            label: l10n.navChats,
          ),
          if (user?.role == UserRole.superUser || user?.role == UserRole.supplier)
            NavigationDestination(
              icon: const Icon(Icons.admin_panel_settings_outlined),
              selectedIcon: const Icon(Icons.admin_panel_settings),
              label: l10n.navAdmin,
            )
          else
            NavigationDestination(
              icon: const Icon(Icons.person_outlined),
              selectedIcon: const Icon(Icons.person),
              label: l10n.navProfile,
            ),
        ],
        child: Scaffold(
          appBar: AppBar(
            title: Text(user?.role == UserRole.superUser ? l10n.superUserDashboard : l10n.wholesaleDashboard),
            actions: [
              const ThemeToggleButton(),
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    context.read<OrdersBloc>().add(const OrdersFetchRequested());
                  },
                ),
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
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.welcomeUser(user?.email ?? 'User'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: BlocBuilder<OrdersBloc, OrdersState>(
                    builder: (context, state) {
                      if (state is OrdersLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state is OrdersLoaded) {
                        return _OrderList(orders: state.orders);
                      }
                      if (state is OrdersFailure) {
                        return Center(child: Text(l10n.errorWithMessage(state.message)));
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final OrderStatus status;
  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Tokens.statusColor(status),
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final List<Order> orders;
  const _OrderList({required this.orders});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: SemanticColors.of(context).textTertiary),
            const SizedBox(height: 16),
            Text(l10n.noOrdersYet, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => context.push('/place-order'),
              icon: const Icon(Icons.add),
              label: Text(l10n.placeOrder),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(l10n.orderWithLanguage(order.displayOrderNumber ?? order.id, order.language.name.toUpperCase())),
            subtitle: Text('${localizedStatusLabel(order.status, l10n)} • ${order.quoteRequired ? l10n.quoteNeeded : '\$${order.totalAmount.toStringAsFixed(2)}'}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StatusDot(status: order.status),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => context.push('/orders/${order.id}'),
          ),
        );
      },
    );
  }
}
