import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';
import '../../repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthInitial()) {
    on<AuthSessionChecked>(_onSessionChecked);
    on<AuthDeepLinkChecked>(_onDeepLinkChecked);
    on<AuthMagicLinkRequested>(_onMagicLinkRequested);
    on<AuthMagicLinkVerified>(_onMagicLinkVerified);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onSessionChecked(
    AuthSessionChecked event,
    Emitter<AuthState> emit,
  ) async {
    final user = await _authRepository.getCurrentUser();
    if (user != null) {
      emit(AuthAuthenticated(user: user));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onDeepLinkChecked(
    AuthDeepLinkChecked event,
    Emitter<AuthState> emit,
  ) async {
    final link = event.uri.toString();
    if (_authRepository.isSignInWithEmailLink(link)) {
      emit(const AuthLoading());
      try {
        final email = await _authRepository.retrievePendingEmail();
        if (email != null) {
          final user = await _authRepository.verifyMagicLink(email, link);
          emit(AuthAuthenticated(user: user));
        } else {
          // Email not found on this device.
          // In a real app, we would emit a state to prompt for email.
          // For now, we fail gracefully.
          emit(const AuthFailure(message: 'Please enter your email again to complete sign in.'));
        }
      } catch (e) {
        emit(AuthFailure(message: e.toString()));
      }
    }
  }

  Future<void> _onMagicLinkRequested(
    AuthMagicLinkRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.loginWithMagicLink(event.email);
      emit(const AuthMagicLinkSent());
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }

  Future<void> _onMagicLinkVerified(
    AuthMagicLinkVerified event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.verifyMagicLink(event.email, event.link);
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.logout();
    emit(const AuthUnauthenticated());
  }
}
