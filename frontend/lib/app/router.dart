import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/auth_callback_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/orders/order_form_screen.dart';
import '../screens/admin/product_management_screen.dart';
import 'go_router_refresh_stream.dart';

class AppRouter {
  final AuthBloc authBloc;

  AppRouter({required this.authBloc});

  late final router = GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final authState = authBloc.state;
      final loggingIn = state.matchedLocation == '/login';

      // Initial or Loading -> Stay put (or splash)
      if (authState is AuthInitial || authState is AuthLoading) return null;

      // Unauthenticated -> Force Login
      if (authState is! AuthAuthenticated) {
        return loggingIn ? null : '/login';
      }

      // Check for Admin access to admin routes
      if (state.matchedLocation.startsWith('/admin') && 
          authState.user.role != UserRole.superUser) {
        return '/dashboard';
      }

      // Authenticated -> Go to Dashboard if on Login
      if (loggingIn) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/callback',
        builder: (context, state) => AuthCallbackScreen(uri: state.uri),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/place-order',
        builder: (context, state) => const OrderFormScreen(),
      ),
      GoRoute(
        path: '/admin/products',
        builder: (context, state) => const ProductManagementScreen(),
      ),
    ],
  );
}
