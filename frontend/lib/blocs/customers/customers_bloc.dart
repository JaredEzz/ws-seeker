import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';

import '../../repositories/user_repository.dart';
import 'customers_event.dart';
import 'customers_state.dart';

export 'customers_event.dart';
export 'customers_state.dart';

class CustomersBloc extends Bloc<CustomersEvent, CustomersState> {
  final UserRepository _userRepository;

  CustomersBloc({required UserRepository userRepository})
      : _userRepository = userRepository,
        super(const CustomersInitial()) {
    on<CustomersFetchRequested>(_onFetchRequested);
    on<CustomerAccountManagerAssigned>(_onAccountManagerAssigned);
    on<ShopifySyncRequested>(_onShopifySyncRequested);
  }

  Future<void> _onFetchRequested(
    CustomersFetchRequested event,
    Emitter<CustomersState> emit,
  ) async {
    emit(const CustomersLoading());
    try {
      final allUsers = await _userRepository.listUsers();

      final customers = allUsers
          .where((u) => u.role == UserRole.wholesaler)
          .toList();

      final managers = allUsers
          .where((u) =>
              u.role == UserRole.superUser || u.role == UserRole.supplier)
          .toList();

      emit(CustomersLoaded(customers: customers, managers: managers));
    } catch (e) {
      emit(CustomersFailure(e.toString()));
    }
  }

  Future<void> _onAccountManagerAssigned(
    CustomerAccountManagerAssigned event,
    Emitter<CustomersState> emit,
  ) async {
    try {
      await _userRepository.assignAccountManager(
        event.userId,
        event.managerId,
      );
      // Refetch to get updated data
      add(const CustomersFetchRequested());
    } catch (e) {
      emit(CustomersFailure(e.toString()));
    }
  }

  Future<void> _onShopifySyncRequested(
    ShopifySyncRequested event,
    Emitter<CustomersState> emit,
  ) async {
    emit(const CustomersLoading());
    try {
      final result = await _userRepository.syncShopifyUsers();
      emit(ShopifySyncComplete(
        created: result.created,
        updated: result.updated,
        skipped: result.skipped,
      ));
      // Refetch users after sync
      add(const CustomersFetchRequested());
    } catch (e) {
      emit(CustomersFailure(e.toString()));
    }
  }
}
