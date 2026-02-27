import 'package:flutter/foundation.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';

@immutable
sealed class CustomersState {
  const CustomersState();
}

final class CustomersInitial extends CustomersState {
  const CustomersInitial();
}

final class CustomersLoading extends CustomersState {
  const CustomersLoading();
}

final class CustomersLoaded extends CustomersState {
  final List<AppUser> customers;
  final List<AppUser> managers;

  const CustomersLoaded({
    required this.customers,
    required this.managers,
  });
}

final class CustomersFailure extends CustomersState {
  final String message;

  const CustomersFailure(this.message);
}

final class ShopifySyncComplete extends CustomersState {
  final int created;
  final int updated;
  final int skipped;

  const ShopifySyncComplete({
    required this.created,
    required this.updated,
    required this.skipped,
  });
}
