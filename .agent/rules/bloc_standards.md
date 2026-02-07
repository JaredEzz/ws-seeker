# BLoC Standards for Croma Wholesale

**Version:** 1.0  
**Applies To:** `/frontend` Flutter Web Application  
**State Management:** flutter_bloc ^8.1.0+

---

## 1. Core Principles

### 1.1 BLoC Over Cubit
- **ALWAYS use `Bloc<Event, State>`** for complex state management
- **Cubit is only permitted** for trivial, single-action state (e.g., theme toggle)
- **NEVER use Provider directly** for business logic state

### 1.2 Separation of Concerns
```
UI Layer (Widgets) → BLoC Layer (Events/States) → Repository Layer → Data Sources
```

- Widgets dispatch **Events**
- BLoCs emit **States**
- Repositories abstract data access
- Data Sources handle API/Database calls

---

## 2. File Structure

Each BLoC must follow this structure:

```
lib/blocs/
├── auth/
│   ├── auth_bloc.dart       # BLoC class
│   ├── auth_event.dart      # Event definitions
│   ├── auth_state.dart      # State definitions
│   └── auth_bloc.freezed.dart  # Generated (freezed)
├── orders/
│   ├── orders_bloc.dart
│   ├── orders_event.dart
│   ├── orders_state.dart
│   └── orders_bloc.freezed.dart
└── bloc_observer.dart       # Global observer
```

---

## 3. Event Standards

### 3.1 Naming Convention
- Events are **past-tense verbs** or **nouns with action suffix**
- Format: `{Subject}{Action}` or `{Subject}{Action}Requested`

```dart
// ✅ CORRECT
sealed class AuthEvent {
  const AuthEvent();
}

final class AuthMagicLinkRequested extends AuthEvent {
  const AuthMagicLinkRequested({required this.email});
  final String email;
}

final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

final class AuthSessionChecked extends AuthEvent {
  const AuthSessionChecked();
}

// ❌ INCORRECT
class Login extends AuthEvent {}      // Too vague
class DoLogout extends AuthEvent {}   // Imperative, not descriptive
```

### 3.2 Use Freezed for Complex Events
```dart
@freezed
sealed class OrderEvent with _$OrderEvent {
  const factory OrderEvent.created({
    required ProductLanguage language,
    required List<OrderItem> items,
    required ShippingAddress address,
  }) = OrderCreated;

  const factory OrderEvent.statusUpdated({
    required String orderId,
    required OrderStatus newStatus,
  }) = OrderStatusUpdated;
}
```

---

## 4. State Standards

### 4.1 State Classes
- Use **sealed classes** with distinct subclasses
- States must be **immutable**
- Include `copyWith` for complex states

```dart
// ✅ CORRECT - Sealed class pattern
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
  const AuthAuthenticated({required this.user});
  final AppUser user;
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

final class AuthFailure extends AuthState {
  const AuthFailure({required this.message});
  final String message;
}
```

### 4.2 Complex State with Freezed
```dart
@freezed
sealed class OrdersState with _$OrdersState {
  const factory OrdersState.initial() = OrdersInitial;
  
  const factory OrdersState.loading() = OrdersLoading;
  
  const factory OrdersState.loaded({
    required List<Order> orders,
    required OrderFilter filter,
    @Default(false) bool hasReachedMax,
  }) = OrdersLoaded;
  
  const factory OrdersState.failure({
    required String message,
  }) = OrdersFailure;
}
```

### 4.3 Status Enum Pattern (Alternative)
For states with shared data:

```dart
enum OrderFormStatus { initial, loading, success, failure }

@freezed
class OrderFormState with _$OrderFormState {
  const factory OrderFormState({
    @Default(OrderFormStatus.initial) OrderFormStatus status,
    @Default(ProductLanguage.japanese) ProductLanguage language,
    @Default([]) List<OrderItem> items,
    ShippingAddress? address,
    String? errorMessage,
  }) = _OrderFormState;
}
```

---

## 5. BLoC Implementation

### 5.1 Constructor Pattern
```dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required AuthRepository authRepository,
  })  : _authRepository = authRepository,
        super(const AuthInitial()) {
    on<AuthMagicLinkRequested>(_onMagicLinkRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthSessionChecked>(_onSessionChecked);
  }

  final AuthRepository _authRepository;
  
  // Event handlers...
}
```

### 5.2 Event Handlers
- Use **private methods** prefixed with `_on`
- Always use `emit` within handlers
- Handle errors gracefully

```dart
Future<void> _onMagicLinkRequested(
  AuthMagicLinkRequested event,
  Emitter<AuthState> emit,
) async {
  emit(const AuthLoading());
  
  try {
    await _authRepository.sendMagicLink(email: event.email);
    emit(const AuthMagicLinkSent());
  } on AuthException catch (e) {
    emit(AuthFailure(message: e.message));
  } catch (e) {
    emit(const AuthFailure(message: 'An unexpected error occurred'));
  }
}
```

### 5.3 Transformers for Debouncing/Throttling
```dart
on<ProductSearchQueryChanged>(
  _onSearchQueryChanged,
  transformer: debounce(const Duration(milliseconds: 300)),
);

// Transformer utility
EventTransformer<E> debounce<E>(Duration duration) {
  return (events, mapper) => events.debounceTime(duration).flatMap(mapper);
}
```

---

## 6. Repository Pattern

### 6.1 Repository Interface
```dart
abstract interface class OrderRepository {
  Future<List<Order>> getOrders({
    required String userId,
    OrderFilter? filter,
  });
  
  Future<Order> createOrder(CreateOrderRequest request);
  
  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
  });
  
  Stream<List<OrderComment>> watchComments(String orderId);
}
```

### 6.2 Repository Implementation
```dart
class FirestoreOrderRepository implements OrderRepository {
  FirestoreOrderRepository({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  @override
  Future<List<Order>> getOrders({
    required String userId,
    OrderFilter? filter,
  }) async {
    // Implementation...
  }
}
```

---

## 7. Widget Integration

### 7.1 BlocProvider Placement
- Provide BLoCs at the **route level** or in `main.dart`
- Use `MultiBlocProvider` for multiple BLoCs

```dart
// ✅ CORRECT - Route level
MaterialPageRoute(
  builder: (_) => BlocProvider(
    create: (context) => OrderFormBloc(
      orderRepository: context.read<OrderRepository>(),
    ),
    child: const OrderFormScreen(),
  ),
);

// ✅ CORRECT - App level for global BLoCs
MultiBlocProvider(
  providers: [
    BlocProvider(create: (_) => AuthBloc(authRepository: authRepo)),
    BlocProvider(create: (_) => ThemeBloc()),
  ],
  child: const CromaApp(),
);
```

### 7.2 BlocBuilder Usage
```dart
// ✅ CORRECT - Specific rebuild
BlocBuilder<OrdersBloc, OrdersState>(
  buildWhen: (previous, current) => previous != current,
  builder: (context, state) {
    return switch (state) {
      OrdersInitial() => const SizedBox.shrink(),
      OrdersLoading() => const CircularProgressIndicator(),
      OrdersLoaded(:final orders) => OrderListView(orders: orders),
      OrdersFailure(:final message) => ErrorDisplay(message: message),
    };
  },
);
```

### 7.3 BlocListener Usage
```dart
// ✅ CORRECT - Side effects only
BlocListener<AuthBloc, AuthState>(
  listenWhen: (previous, current) => current is AuthFailure,
  listener: (context, state) {
    if (state is AuthFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    }
  },
  child: const LoginForm(),
);
```

### 7.4 BlocConsumer (Combined)
```dart
BlocConsumer<OrderFormBloc, OrderFormState>(
  listenWhen: (previous, current) => 
    current.status == OrderFormStatus.success,
  listener: (context, state) {
    Navigator.of(context).pop();
    context.read<OrdersBloc>().add(const OrdersRefreshRequested());
  },
  builder: (context, state) {
    return OrderForm(
      isLoading: state.status == OrderFormStatus.loading,
      language: state.language,
      items: state.items,
    );
  },
);
```

---

## 8. Testing Standards

### 8.1 Required Tests
Every BLoC must have:
- Unit tests for each event handler
- Edge case tests (empty states, errors)
- Integration tests with mock repositories

### 8.2 Test Structure
```dart
void main() {
  late AuthBloc authBloc;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    authBloc = AuthBloc(authRepository: mockAuthRepository);
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc', () {
    test('initial state is AuthInitial', () {
      expect(authBloc.state, equals(const AuthInitial()));
    });

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthMagicLinkSent] when magic link succeeds',
      build: () {
        when(() => mockAuthRepository.sendMagicLink(email: any(named: 'email')))
            .thenAnswer((_) async {});
        return authBloc;
      },
      act: (bloc) => bloc.add(
        const AuthMagicLinkRequested(email: 'test@example.com'),
      ),
      expect: () => [
        const AuthLoading(),
        const AuthMagicLinkSent(),
      ],
    );
  });
}
```

---

## 9. WASM Compatibility Rules

### 9.1 Prohibited Imports
```dart
// ❌ NEVER USE in Flutter Web WASM
import 'dart:html';
import 'dart:js';
import 'dart:js_util';

// ✅ USE INSTEAD
import 'package:web/web.dart';
```

### 9.2 Conditional Imports
For platform-specific code:

```dart
// storage_service.dart
export 'storage_service_stub.dart'
    if (dart.library.html) 'storage_service_web.dart'
    if (dart.library.io) 'storage_service_io.dart';
```

---

## 10. Code Generation

### 10.1 Required Packages
```yaml
dependencies:
  flutter_bloc: ^8.1.6
  freezed_annotation: ^2.4.1
  json_annotation: ^4.9.0

dev_dependencies:
  bloc_test: ^9.1.7
  build_runner: ^2.4.9
  freezed: ^2.5.2
  json_serializable: ^6.8.0
  mocktail: ^1.0.3
```

### 10.2 Build Command
```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Quick Reference Card

| Concept | Pattern | Example |
|---------|---------|---------|
| Event naming | `{Subject}{Action}Requested` | `OrderCreatedRequested` |
| State classes | Sealed + subclasses | `sealed class OrderState` |
| Handler naming | `_on{EventName}` | `_onOrderCreatedRequested` |
| Repository | Interface + Implementation | `abstract interface class OrderRepo` |
| Provider placement | Route or App level | `BlocProvider(create: ...)` |
| Rebuilds | `buildWhen` for optimization | `buildWhen: (p, c) => ...` |
| Side effects | `BlocListener` | Navigation, Snackbars |

---

*This document serves as the authoritative guide for BLoC implementation in the Croma Wholesale project. All contributions must adhere to these standards.*
