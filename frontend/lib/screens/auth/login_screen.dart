import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../app/design_tokens.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();

  // TODO: Remove _debugMode and all related code when ready for production.
  // Set to false to send real emails via Resend.
  bool _debugMode = true;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              } else if (state is AuthMagicLinkSent) {
                // TODO: Remove debug link dialog when ready for production
                if (state.link != null) {
                  _showDebugLinkDialog(context, state.link!);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Magic link sent! Check your email.')),
                  );
                }
              }
            },
            builder: (context, state) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'WS-Seeker',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'A Croma TCG web app',
                    style: TextStyle(
                      fontSize: 16,
                      color: Tokens.textTertiary,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: state is AuthLoading
                        ? null
                        : () {
                            context.read<AuthBloc>().add(
                                  AuthMagicLinkRequested(
                                    email: _emailController.text,
                                    // TODO: Remove skipEmail when ready for production
                                    skipEmail: _debugMode,
                                  ),
                                );
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    child: state is AuthLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Send Magic Link'),
                  ),
                  // TODO: Remove debug mode switch when ready for production
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Debug mode (skip email)',
                        style: TextStyle(
                          fontSize: 13,
                          color: Tokens.textTertiary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: _debugMode,
                        onChanged: (v) => setState(() => _debugMode = v),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // TODO: Remove this method when ready for production
  void _showDebugLinkDialog(BuildContext context, String link) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Debug: Magic Link'),
        content: SelectableText(
          link,
          style: const TextStyle(fontSize: 14, color: Colors.blue),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // Navigate to the callback URL directly
              final uri = Uri.parse(link);
              context.read<AuthBloc>().add(AuthDeepLinkChecked(uri));
            },
            child: const Text('Open Link'),
          ),
        ],
      ),
    );
  }
}
