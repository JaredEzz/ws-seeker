import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';

import '../../blocs/customers/customers_bloc.dart';
import '../../repositories/user_repository.dart';
import '../../widgets/navigation/admin_shell.dart';

class CustomerManagementScreen extends StatelessWidget {
  const CustomerManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CustomersBloc(
        userRepository: context.read<UserRepository>(),
      )..add(const CustomersFetchRequested()),
      child: const AdminShell(
        selectedIndex: 3,
        child: _CustomerManagementContent(),
      ),
    );
  }
}

class _CustomerManagementContent extends StatefulWidget {
  const _CustomerManagementContent();

  @override
  State<_CustomerManagementContent> createState() =>
      _CustomerManagementContentState();
}

class _CustomerManagementContentState
    extends State<_CustomerManagementContent> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CustomersBloc, CustomersState>(
      listener: (context, state) {
        if (state is ShopifySyncComplete) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Shopify sync complete: ${state.created} created, '
                '${state.updated} updated, ${state.skipped} skipped',
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
        if (state is CustomersFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.message}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Customer Management'),
            actions: [
              IconButton(
                icon: const Icon(Icons.sync),
                tooltip: 'Sync from Shopify',
                onPressed: state is CustomersLoading
                    ? null
                    : () => context
                        .read<CustomersBloc>()
                        .add(const ShopifySyncRequested()),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                onPressed: state is CustomersLoading
                    ? null
                    : () => context
                        .read<CustomersBloc>()
                        .add(const CustomersFetchRequested()),
              ),
            ],
          ),
          body: switch (state) {
            CustomersInitial() || CustomersLoading() =>
              const Center(child: CircularProgressIndicator()),
            CustomersFailure(:final message) =>
              Center(child: Text('Error: $message')),
            ShopifySyncComplete() =>
              const Center(child: CircularProgressIndicator()),
            CustomersLoaded(:final customers, :final managers) =>
              _buildContent(context, customers, managers),
          },
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<AppUser> customers,
    List<AppUser> managers,
  ) {
    final filtered = _searchQuery.isEmpty
        ? customers
        : customers.where((c) {
            final q = _searchQuery.toLowerCase();
            return c.email.toLowerCase().contains(q) ||
                (c.discordName?.toLowerCase().contains(q) ?? false) ||
                (c.phone?.toLowerCase().contains(q) ?? false);
          }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by email, discord, or phone...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '${filtered.length} customer${filtered.length == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No customers found'))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Discord')),
                        DataColumn(label: Text('Phone')),
                        DataColumn(label: Text('Account Manager')),
                        DataColumn(label: Text('Created')),
                      ],
                      rows: filtered.map((customer) {
                        return DataRow(
                          cells: [
                            DataCell(Text(customer.email)),
                            DataCell(Text(customer.discordName ?? '-')),
                            DataCell(Text(customer.phone ?? '-')),
                            DataCell(
                              _AccountManagerDropdown(
                                customer: customer,
                                managers: managers,
                              ),
                            ),
                            DataCell(Text(
                              '${customer.createdAt.month}/${customer.createdAt.day}/${customer.createdAt.year}',
                            )),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _AccountManagerDropdown extends StatelessWidget {
  final AppUser customer;
  final List<AppUser> managers;

  const _AccountManagerDropdown({
    required this.customer,
    required this.managers,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String?>(
      value: customer.accountManagerId,
      hint: const Text('Unassigned'),
      underline: const SizedBox.shrink(),
      isDense: true,
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('Unassigned'),
        ),
        ...managers.map((m) => DropdownMenuItem<String?>(
              value: m.id,
              child: Text(m.discordName ?? m.email),
            )),
      ],
      onChanged: (managerId) {
        // If the value is already null and they pick null, no change
        if (managerId == customer.accountManagerId) return;
        context.read<CustomersBloc>().add(
              CustomerAccountManagerAssigned(
                userId: customer.id,
                managerId: managerId,
              ),
            );
      },
    );
  }
}
