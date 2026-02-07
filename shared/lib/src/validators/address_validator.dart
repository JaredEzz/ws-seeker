/// Address validation utilities
library;

import '../models/user.dart';

/// Address validation result
class AddressValidationResult {
  const AddressValidationResult({
    required this.isValid,
    this.errors = const [],
    this.suggestions,
  });

  final bool isValid;
  final List<String> errors;
  final ShippingAddress? suggestions;

  factory AddressValidationResult.valid() => 
      const AddressValidationResult(isValid: true);

  factory AddressValidationResult.invalid(List<String> errors) =>
      AddressValidationResult(isValid: false, errors: errors);
}

/// Address validation interface
abstract interface class AddressValidator {
  /// Validate a shipping address
  Future<AddressValidationResult> validate(ShippingAddress address);
}

/// Basic address validator (field presence only)
/// 
/// For production, integrate with address validation API
class BasicAddressValidator implements AddressValidator {
  const BasicAddressValidator();

  @override
  Future<AddressValidationResult> validate(ShippingAddress address) async {
    final errors = <String>[];

    if (address.fullName.trim().isEmpty) {
      errors.add('Full name is required');
    }

    if (address.addressLine1.trim().isEmpty) {
      errors.add('Address line 1 is required');
    }

    if (address.city.trim().isEmpty) {
      errors.add('City is required');
    }

    if (address.state.trim().isEmpty) {
      errors.add('State/Province is required');
    }

    if (address.postalCode.trim().isEmpty) {
      errors.add('Postal code is required');
    }

    if (address.country.trim().isEmpty) {
      errors.add('Country is required');
    }

    // Basic postal code format check for common countries
    if (address.country.toUpperCase() == 'US' ||
        address.country.toUpperCase() == 'USA') {
      final usZipRegex = RegExp(r'^\d{5}(-\d{4})?$');
      if (!usZipRegex.hasMatch(address.postalCode)) {
        errors.add('Invalid US postal code format');
      }
    }

    if (errors.isEmpty) {
      return AddressValidationResult.valid();
    }

    return AddressValidationResult.invalid(errors);
  }
}
