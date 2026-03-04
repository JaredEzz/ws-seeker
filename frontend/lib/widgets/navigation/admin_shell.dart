import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ws_seeker_frontend/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../common/theme_toggle_button.dart';

class AdminShell extends StatelessWidget {
  final int selectedIndex;
  final Widget child;

  const AdminShell({
    super.key,
    required this.selectedIndex,
    required this.child,
  });

  static List<_AdminDestination> _allDestinations(AppLocalizations l10n) => [
    _AdminDestination(
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
      label: l10n.navOrders,
      path: '/admin/orders',
    ),
    _AdminDestination(
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
      label: l10n.navProducts,
      path: '/admin/products',
    ),
    _AdminDestination(
      icon: Icons.description_outlined,
      selectedIcon: Icons.description,
      label: l10n.navInvoices,
      path: '/admin/invoices',
    ),
    _AdminDestination(
      icon: Icons.people_outlined,
      selectedIcon: Icons.people,
      label: l10n.navCustomers,
      path: '/admin/customers',
    ),
    _AdminDestination(
      icon: Icons.chat_outlined,
      selectedIcon: Icons.chat,
      label: l10n.navChats,
      path: '/admin/chats',
    ),
    _AdminDestination(
      icon: Icons.history_outlined,
      selectedIcon: Icons.history,
      label: l10n.navAuditLogs,
      path: '/admin/audit-logs',
    ),
    _AdminDestination(
      icon: Icons.person_outlined,
      selectedIcon: Icons.person,
      label: l10n.navProfile,
      path: '/profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final authState = context.watch<AuthBloc>().state;
    final isSupplier = authState is AuthAuthenticated &&
        authState.user.role == UserRole.supplier;

    final allDest = _allDestinations(l10n);

    // Suppliers see Orders + Chats only (no Products, Invoices, or Audit Logs)
    final destinations = isSupplier
        ? allDest
            .where((d) =>
                d.path == '/admin/orders' ||
                d.path == '/admin/chats' ||
                d.path == '/profile')
            .toList()
        : allDest;

    final label = isSupplier ? l10n.labelSupplier : l10n.labelAdmin;

    void onDestinationSelected(int index) {
      if (index < destinations.length && index != selectedIndex) {
        context.go(destinations[index].path);
      }
    }

    final clampedIndex = selectedIndex.clamp(0, destinations.length - 1);

    if (width >= 800) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: clampedIndex,
              onDestinationSelected: onDestinationSelected,
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const ThemeToggleButton(),
                        const SizedBox(height: 8),
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          tooltip: l10n.backToDashboard,
                          onPressed: () => context.go('/dashboard'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              destinations: destinations
                  .map((d) => NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selectedIcon),
                        label: Text(d.label),
                      ))
                  .toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: clampedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: destinations
            .map((d) => NavigationDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: d.label,
                ))
            .toList(),
      ),
    );
  }
}

class _AdminDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String path;

  const _AdminDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.path,
  });
}
