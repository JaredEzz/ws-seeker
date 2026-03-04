import 'package:flutter/material.dart';
import 'package:ws_seeker_frontend/l10n/app_localizations.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';

class AddressForm extends StatefulWidget {
  final ShippingAddress? initialAddress;
  final ValueChanged<ShippingAddress> onChanged;
  final GlobalKey<FormState>? formKey;

  const AddressForm({
    super.key,
    this.initialAddress,
    required this.onChanged,
    this.formKey,
  });

  @override
  State<AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<AddressForm> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _addressLine1Controller;
  late final TextEditingController _addressLine2Controller;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _postalCodeController;
  late final TextEditingController _countryController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final addr = widget.initialAddress;
    _fullNameController = TextEditingController(text: addr?.fullName ?? '');
    _addressLine1Controller = TextEditingController(text: addr?.addressLine1 ?? '');
    _addressLine2Controller = TextEditingController(text: addr?.addressLine2 ?? '');
    _cityController = TextEditingController(text: addr?.city ?? '');
    _stateController = TextEditingController(text: addr?.state ?? '');
    _postalCodeController = TextEditingController(text: addr?.postalCode ?? '');
    _countryController = TextEditingController(text: addr?.country ?? 'USA');
    _phoneController = TextEditingController(text: addr?.phone ?? '');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _notifyChanged() {
    widget.onChanged(ShippingAddress(
      fullName: _fullNameController.text.trim(),
      addressLine1: _addressLine1Controller.text.trim(),
      addressLine2: _addressLine2Controller.text.trim().isEmpty
          ? null
          : _addressLine2Controller.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      postalCode: _postalCodeController.text.trim(),
      country: _countryController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.shippingAddressRequired, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          _buildField(context, _fullNameController, l10n.fullName, required: true),
          const SizedBox(height: 12),
          _buildField(context, _addressLine1Controller, l10n.addressLine1, required: true),
          const SizedBox(height: 12),
          _buildField(context, _addressLine2Controller, l10n.addressLine2Optional),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildField(context, _cityController, l10n.city, required: true)),
              const SizedBox(width: 12),
              Expanded(child: _buildField(context, _stateController, l10n.state, required: true)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildField(context, _postalCodeController, l10n.postalCode, required: true)),
              const SizedBox(width: 12),
              Expanded(child: _buildField(context, _countryController, l10n.country, required: true)),
            ],
          ),
          const SizedBox(height: 12),
          _buildField(context, _phoneController, l10n.phone, required: true),
        ],
      ),
    );
  }

  Widget _buildField(
    BuildContext context,
    TextEditingController controller,
    String label, {
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      validator: required
          ? (value) => (value == null || value.trim().isEmpty) ? AppLocalizations.of(context).fieldIsRequired(label) : null
          : null,
      onChanged: (_) => _notifyChanged(),
    );
  }
}
