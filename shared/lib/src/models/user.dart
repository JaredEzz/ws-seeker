/// User model and role definitions
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// User roles in the Croma Wholesale system
enum UserRole {
  /// Wholesaler member - can place orders and view own history
  @JsonValue('wholesaler')
  wholesaler,

  /// Supplier (Mimi) - can manage Japanese orders only
  @JsonValue('supplier')
  supplier,

  /// Super User (Admin, Jared) - can manage all orders
  @JsonValue('super_user')
  superUser,
}

/// Represents an application user
@freezed
class AppUser with _$AppUser {
  const factory AppUser({
    required String id,
    required String email,
    required UserRole role,
    ShippingAddress? savedAddress,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) => _$AppUserFromJson(json);
}

/// Shipping address for orders
@freezed
class ShippingAddress with _$ShippingAddress {
  const factory ShippingAddress({
    required String fullName,
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    required String postalCode,
    required String country,
    String? phone,
  }) = _ShippingAddress;

  factory ShippingAddress.fromJson(Map<String, dynamic> json) =>
      _$ShippingAddressFromJson(json);
}
