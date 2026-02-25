import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminShell extends StatelessWidget {
  final int selectedIndex;
  final Widget child;

  const AdminShell({
    super.key,
    required this.selectedIndex,
    required this.child,
  });

  static const _destinations = [
    _AdminDestination(
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
      label: 'Orders',
      path: '/admin/orders',
    ),
    _AdminDestination(
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
      label: 'Products',
      path: '/admin/products',
    ),
    _AdminDestination(
      icon: Icons.description_outlined,
      selectedIcon: Icons.description,
      label: 'Invoices',
      path: '/admin/invoices',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    void onDestinationSelected(int index) {
      if (index != selectedIndex) {
        context.go(_destinations[index].path);
      }
    }

    if (width >= 800) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Admin',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      tooltip: 'Back to Dashboard',
                      onPressed: () => context.go('/dashboard'),
                    ),
                  ),
                ),
              ),
              destinations: _destinations
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
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: _destinations
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
