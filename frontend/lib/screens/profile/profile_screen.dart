import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ws_seeker_frontend/l10n/app_localizations.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/locale/locale_cubit.dart';
import '../../repositories/user_repository.dart';
import '../../widgets/common/theme_toggle_button.dart';

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
  late TextEditingController _venmoHandleController;
  late TextEditingController _paypalEmailController;
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
    _venmoHandleController =
        TextEditingController(text: user?.venmoHandle ?? '');
    _paypalEmailController =
        TextEditingController(text: user?.paypalEmail ?? '');
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
    _venmoHandleController.dispose();
    _paypalEmailController.dispose();
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

      final updatedUser =
          await context.read<UserRepository>().updateProfile(
                discordName: _discordNameController.text.trim(),
                phone: _phoneController.text.trim(),
                preferredPaymentMethod: _preferredPaymentMethod,
                wiseEmail: _wiseEmailController.text.trim().isEmpty
                    ? null
                    : _wiseEmailController.text.trim(),
                venmoHandle: _venmoHandleController.text.trim().isEmpty
                    ? null
                    : _venmoHandleController.text.trim(),
                paypalEmail: _paypalEmailController.text.trim().isEmpty
                    ? null
                    : _paypalEmailController.text.trim(),
                savedAddress: address,
                preferredLocale: context.read<LocaleCubit>().state.languageCode,
              );

      if (mounted) {
        // Update the AuthBloc so the new profile persists across screens
        context.read<AuthBloc>().add(AuthUserChanged(updatedUser));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).profileSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).errorWithMessage(e.toString()))),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = context.watch<AuthBloc>().state;
    final user =
        authState is AuthAuthenticated ? authState.user : null;
    final theme = Theme.of(context);
    final currentLocale = context.watch<LocaleCubit>().state;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myProfile),
        actions: const [ThemeToggleButton()],
      ),
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
                      Text(l10n.sectionAccount, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Text(l10n.emailLabel(user?.email ?? '')),
                      Text(l10n.roleLabel(user?.role.name ?? 'wholesaler')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Language preference
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.languagePreference, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      SegmentedButton<String>(
                        segments: [
                          ButtonSegment(value: 'en', label: Text(l10n.languageEnglish)),
                          ButtonSegment(value: 'ja', label: Text(l10n.languageJapaneseOption)),
                        ],
                        selected: {currentLocale.languageCode},
                        onSelectionChanged: (selection) {
                          context.read<LocaleCubit>().setLocale(Locale(selection.first));
                        },
                      ),
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
                      Text(l10n.sectionContactInfo,
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      _field(_discordNameController, l10n.discordName),
                      const SizedBox(height: 12),
                      _field(_phoneController, l10n.phone),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Payment info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.sectionPaymentInfo,
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _preferredPaymentMethod,
                        decoration: InputDecoration(
                          labelText: l10n.preferredPaymentMethod,
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                        ),
                        items: [
                          DropdownMenuItem(
                              value: 'Venmo', child: Text(l10n.venmo)),
                          DropdownMenuItem(
                              value: 'PayPal', child: Text(l10n.payPal)),
                          DropdownMenuItem(
                              value: 'ACH', child: Text(l10n.ach)),
                          DropdownMenuItem(
                              value: 'Wise', child: Text(l10n.wise)),
                        ],
                        onChanged: (val) =>
                            setState(() => _preferredPaymentMethod = val),
                      ),
                      if (_preferredPaymentMethod == 'Wise') ...[
                        const SizedBox(height: 12),
                        _field(_wiseEmailController, l10n.wiseEmailLabel,
                            hint: l10n.wiseEmailHint),
                      ],
                      if (_preferredPaymentMethod == 'Venmo') ...[
                        const SizedBox(height: 12),
                        _field(_venmoHandleController, l10n.venmoHandleLabel,
                            hint: l10n.venmoHandleHint),
                      ],
                      if (_preferredPaymentMethod == 'PayPal') ...[
                        const SizedBox(height: 12),
                        _field(_paypalEmailController, l10n.paypalEmailLabel,
                            hint: l10n.paypalEmailHint),
                      ],
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
                      Text(l10n.savedShippingAddress,
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(l10n.addressPrefillNote,
                          style: theme.textTheme.bodySmall),
                      const SizedBox(height: 12),
                      _field(_fullNameController, l10n.fullName),
                      const SizedBox(height: 12),
                      _field(_addressLine1Controller, l10n.addressLine1),
                      const SizedBox(height: 12),
                      _field(_addressLine2Controller,
                          l10n.addressLine2Optional),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                              child: _field(_cityController, l10n.city)),
                          const SizedBox(width: 12),
                          Expanded(
                              child:
                                  _field(_stateController, l10n.state)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                              child: _field(
                                  _postalCodeController, l10n.postalCode)),
                          const SizedBox(width: 12),
                          Expanded(
                              child:
                                  _field(_countryController, l10n.country)),
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
                      : Text(l10n.saveProfile),
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
