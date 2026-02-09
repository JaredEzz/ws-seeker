import 'package:ws_seeker_shared/ws_seeker_shared.dart';

sealed class AuthEvent {
  const AuthEvent();
}

final class AuthSessionChecked extends AuthEvent {
  const AuthSessionChecked();
}

final class AuthDeepLinkChecked extends AuthEvent {
  final Uri uri;
  const AuthDeepLinkChecked(this.uri);
}

final class AuthMagicLinkRequested extends AuthEvent {
  final String email;
  const AuthMagicLinkRequested({required this.email});
}

final class AuthMagicLinkVerified extends AuthEvent {
  final String email;
  final String link;
  const AuthMagicLinkVerified({required this.email, required this.link});
}

final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
