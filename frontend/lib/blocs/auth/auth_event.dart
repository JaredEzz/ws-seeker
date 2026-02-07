import 'package:ws_seeker_shared/ws_seeker_shared.dart';

sealed class AuthEvent {
  const AuthEvent();
}

final class AuthSessionChecked extends AuthEvent {
  const AuthSessionChecked();
}

final class AuthMagicLinkRequested extends AuthEvent {
  final String email;
  const AuthMagicLinkRequested({required this.email});
}

final class AuthMagicLinkVerified extends AuthEvent {
  final String token;
  const AuthMagicLinkVerified({required this.token});
}

final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
