import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_event.dart';
import 'repositories/auth_repository.dart';
import 'repositories/order_repository.dart';
import 'repositories/product_repository.dart';

void main() {
  // Hash strategy is used by default in Flutter Web, 
  // which is required for GitHub Pages to avoid 404s on refresh.
  
  final authRepository = MockAuthRepository();
  final orderRepository = MockOrderRepository();
  final productRepository = MockProductRepository();

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(create: (_) => authRepository),
        RepositoryProvider<OrderRepository>(create: (_) => orderRepository),
        RepositoryProvider<ProductRepository>(create: (_) => productRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthBloc(
              authRepository: context.read<AuthRepository>(),
            )..add(const AuthSessionChecked()),
          ),
        ],
        child: const WSSeekerApp(),
      ),
    ),
  );
}

class WSSeekerApp extends StatelessWidget {
  const WSSeekerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'WS-Seeker',
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
