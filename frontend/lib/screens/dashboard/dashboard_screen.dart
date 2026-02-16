import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';
import '../../app/design_tokens.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/orders/orders_bloc.dart';
import '../../repositories/order_repository.dart';
import '../../widgets/navigation/adaptive_navigation.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    return BlocProvider(
      create: (context) => OrdersBloc(
        orderRepository: context.read<OrderRepository>(),
      )..add(const OrdersFetchRequested()),
      child: AdaptiveNavigation(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) context.push('/place-order');
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_shopping_cart_outlined),
            selectedIcon: Icon(Icons.add_shopping_cart),
            label: 'New Order',
          ),
          NavigationDestination(
            icon: Icon(Icons.message_outlined),
            selectedIcon: Icon(Icons.message),
            label: 'Messages',
          ),
        ],
        child: Scaffold(
          appBar: AppBar(
            title: Text(user?.role == UserRole.superUser ? 'Super User Dashboard' : 'Wholesale Dashboard'),
            actions: [
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    context.read<OrdersBloc>().add(const OrdersFetchRequested());
                  },
                ),
              ),
              const CircleAvatar(child: Icon(Icons.person)),
              const SizedBox(width: 16),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${user?.email ?? "User"}',
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
                        return Center(child: Text('Error: ${state.message}'));
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
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
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text('No orders yet', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => context.push('/place-order'),
              icon: const Icon(Icons.add),
              label: const Text('Place Order'),
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
            title: Text('Order ${order.id.length > 8 ? order.id.substring(0, 8) : order.id} - ${order.language.name.toUpperCase()}'),
            subtitle: Text('${Tokens.statusLabel(order.status)} • \$${order.totalAmount.toStringAsFixed(2)}'),
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
