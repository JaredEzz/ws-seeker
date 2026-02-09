import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_event.dart';
import 'repositories/auth_repository.dart';
import 'repositories/order_repository.dart';
import 'repositories/product_repository.dart';

void main() {
  // Use path strategy (remove # from URLs)
  usePathUrlStrategy();

  final authRepository = MockAuthRepository();
  final orderRepository = MockOrderRepository();
  final productRepository = MockProductRepository();

  // Create AuthBloc immediately so we can pass it to the Router
  final authBloc = AuthBloc(authRepository: authRepository)
    ..add(const AuthSessionChecked())
    ..add(AuthDeepLinkChecked(Uri.base));

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<OrderRepository>.value(value: orderRepository),
        RepositoryProvider<ProductRepository>.value(value: productRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
        ],
        child: WSSeekerApp(authBloc: authBloc),
      ),
    ),
  );
}

class WSSeekerApp extends StatefulWidget {
  final AuthBloc authBloc;

  const WSSeekerApp({super.key, required this.authBloc});

  @override
  State<WSSeekerApp> createState() => _WSSeekerAppState();
}

class _WSSeekerAppState extends State<WSSeekerApp> {
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _appRouter = AppRouter(authBloc: widget.authBloc);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'WS-Seeker',
      theme: AppTheme.lightTheme,
      routerConfig: _appRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
