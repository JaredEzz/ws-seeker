import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../repositories/user_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _discordNameController;
  late TextEditingController _phoneController;
  late TextEditingController _wiseEmailController;
  late TextEditingController _fullNameController;
  late TextEditingController _addressLine1Controller;
  late TextEditingController _addressLine2Controller;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _postalCodeController;
  late TextEditingController _countryController;
  String? _preferredPaymentMethod;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    final user =
        authState is AuthAuthenticated ? authState.user : null;
    final addr = user?.savedAddress;

    _discordNameController =
        TextEditingController(text: user?.discordName ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _wiseEmailController =
        TextEditingController(text: user?.wiseEmail ?? '');
    _fullNameController =
        TextEditingController(text: addr?.fullName ?? '');
    _addressLine1Controller =
        TextEditingController(text: addr?.addressLine1 ?? '');
    _addressLine2Controller =
        TextEditingController(text: addr?.addressLine2 ?? '');
    _cityController = TextEditingController(text: addr?.city ?? '');
    _stateController = TextEditingController(text: addr?.state ?? '');
    _postalCodeController =
        TextEditingController(text: addr?.postalCode ?? '');
    _countryController =
        TextEditingController(text: addr?.country ?? 'USA');
    _preferredPaymentMethod = user?.preferredPaymentMethod;
  }

  @override
  void dispose() {
    _discordNameController.dispose();
    _phoneController.dispose();
    _wiseEmailController.dispose();
    _fullNameController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final address = ShippingAddress(
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
      );

      await context.read<UserRepository>().updateProfile(
            discordName: _discordNameController.text.trim(),
            phone: _phoneController.text.trim(),
            preferredPaymentMethod: _preferredPaymentMethod,
            wiseEmail: _wiseEmailController.text.trim().isEmpty
                ? null
                : _wiseEmailController.text.trim(),
            savedAddress: address,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user =
        authState is AuthAuthenticated ? authState.user : null;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Account info (read-only)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Account', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Text('Email: ${user?.email ?? ""}'),
                      Text(
                          'Role: ${user?.role.name ?? "wholesaler"}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Contact info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Contact Info',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      _field(_discordNameController, 'Discord Name'),
                      const SizedBox(height: 12),
                      _field(_phoneController, 'Phone'),
                      const SizedBox(height: 12),
                      _field(_wiseEmailController, 'Wise Email',
                          hint: 'For Japanese orders'),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _preferredPaymentMethod,
                        decoration: const InputDecoration(
                          labelText: 'Preferred Payment Method',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'Venmo', child: Text('Venmo')),
                          DropdownMenuItem(
                              value: 'PayPal', child: Text('PayPal')),
                          DropdownMenuItem(
                              value: 'ACH', child: Text('ACH')),
                          DropdownMenuItem(
                              value: 'Wise', child: Text('Wise')),
                        ],
                        onChanged: (val) =>
                            setState(() => _preferredPaymentMethod = val),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Shipping address
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Saved Shipping Address',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text('This will pre-fill your order forms.',
                          style: theme.textTheme.bodySmall),
                      const SizedBox(height: 12),
                      _field(_fullNameController, 'Full Name'),
                      const SizedBox(height: 12),
                      _field(_addressLine1Controller, 'Address Line 1'),
                      const SizedBox(height: 12),
                      _field(_addressLine2Controller,
                          'Address Line 2 (optional)'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                              child: _field(_cityController, 'City')),
                          const SizedBox(width: 12),
                          Expanded(
                              child:
                                  _field(_stateController, 'State')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                              child: _field(
                                  _postalCodeController, 'Postal Code')),
                          const SizedBox(width: 12),
                          Expanded(
                              child:
                                  _field(_countryController, 'Country')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2),
                        )
                      : const Text('Save Profile'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label,
      {String? hint}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}
