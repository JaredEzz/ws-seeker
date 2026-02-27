import 'package:flutter/foundation.dart';

@immutable
sealed class CustomersEvent {
  const CustomersEvent();
}

final class CustomersFetchRequested extends CustomersEvent {
  const CustomersFetchRequested();
}

final class CustomerAccountManagerAssigned extends CustomersEvent {
  final String userId;
  final String? managerId;

  const CustomerAccountManagerAssigned({
    required this.userId,
    required this.managerId,
  });
}

final class ShopifySyncRequested extends CustomersEvent {
  const ShopifySyncRequested();
}
