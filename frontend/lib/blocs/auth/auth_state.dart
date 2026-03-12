import 'package:ws_seeker_shared/ws_seeker_shared.dart';

sealed class AuthState {
  const AuthState();
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class AuthAuthenticated extends AuthState {
  final AppUser user;
  const AuthAuthenticated({required this.user});
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

final class AuthMagicLinkSent extends AuthState {
  const AuthMagicLinkSent();
}

final class AuthFailure extends AuthState {
  final String message;
  const AuthFailure({required this.message});
}
