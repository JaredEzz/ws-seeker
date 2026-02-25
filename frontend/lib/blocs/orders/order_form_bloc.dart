import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';
import '../../repositories/order_repository.dart';
import '../../repositories/product_repository.dart';

// Events
sealed class OrderFormEvent {
  const OrderFormEvent();
}

final class OrderFormLanguageSelected extends OrderFormEvent {
  final ProductLanguage language;
  const OrderFormLanguageSelected(this.language);
}

final class OrderFormItemAdded extends OrderFormEvent {
  final Product product;
  final int quantity;
  const OrderFormItemAdded(this.product, this.quantity);
}

final class OrderFormProfileLoaded extends OrderFormEvent {
  final AppUser user;
  const OrderFormProfileLoaded(this.user);
}

final class OrderFormShippingMethodChanged extends OrderFormEvent {
  final String? shippingMethod;
  const OrderFormShippingMethodChanged(this.shippingMethod);
}

final class OrderFormDiscordNameChanged extends OrderFormEvent {
  final String discordName;
  const OrderFormDiscordNameChanged(this.discordName);
}

final class OrderFormSubmitted extends OrderFormEvent {
  final ShippingAddress address;
  const OrderFormSubmitted(this.address);
}

// State
enum OrderFormStatus { initial, loading, success, failure }

class OrderFormState {
  final OrderFormStatus status;
  final ProductLanguage? language;
  final List<Product> availableProducts;
  final Map<String, int> selectedItems; // productId -> quantity
  final List<OrderItemRequest> itemRequests;
  final String? errorMessage;
  final String? discordName;
  final String? shippingMethod;
  final ShippingAddress? prefillAddress;
  final String? prefillPhone;

  const OrderFormState({
    this.status = OrderFormStatus.initial,
    this.language,
    this.availableProducts = const [],
    this.selectedItems = const {},
    this.itemRequests = const [],
    this.errorMessage,
    this.discordName,
    this.shippingMethod,
    this.prefillAddress,
    this.prefillPhone,
  });

  OrderFormState copyWith({
    OrderFormStatus? status,
    ProductLanguage? language,
    List<Product>? availableProducts,
    Map<String, int>? selectedItems,
    List<OrderItemRequest>? itemRequests,
    String? errorMessage,
    String? discordName,
    String? shippingMethod,
    ShippingAddress? prefillAddress,
    String? prefillPhone,
  }) {
    return OrderFormState(
      status: status ?? this.status,
      language: language ?? this.language,
      availableProducts: availableProducts ?? this.availableProducts,
      selectedItems: selectedItems ?? this.selectedItems,
      itemRequests: itemRequests ?? this.itemRequests,
      errorMessage: errorMessage ?? this.errorMessage,
      discordName: discordName ?? this.discordName,
      shippingMethod: shippingMethod ?? this.shippingMethod,
      prefillAddress: prefillAddress ?? this.prefillAddress,
      prefillPhone: prefillPhone ?? this.prefillPhone,
    );
  }

  /// Calculate estimated subtotal from selected items
  double get estimatedSubtotal {
    double total = 0;
    for (final entry in selectedItems.entries) {
      final product = availableProducts.where((p) => p.id == entry.key).firstOrNull;
      if (product != null) {
        total += product.basePrice * entry.value;
      }
    }
    return total;
  }

  /// Shipping method options based on language
  static List<String> shippingMethodsFor(ProductLanguage? language) {
    return switch (language) {
      ProductLanguage.japanese => [
        'FedEx International Priority',
        'FedEx International Economy',
        'FedEx Air Connect',
      ],
      ProductLanguage.chinese => ['Air', 'Ocean', 'Mix'],
      ProductLanguage.korean || null => [],
    };
  }
}

// BLoC
class OrderFormBloc extends Bloc<OrderFormEvent, OrderFormState> {
  final ProductRepository _productRepository;
  final OrderRepository _orderRepository;

  OrderFormBloc({
    required ProductRepository productRepository,
    required OrderRepository orderRepository,
  })  : _productRepository = productRepository,
        _orderRepository = orderRepository,
        super(const OrderFormState()) {
    on<OrderFormLanguageSelected>(_onLanguageSelected);
    on<OrderFormItemAdded>(_onItemAdded);
    on<OrderFormProfileLoaded>(_onProfileLoaded);
    on<OrderFormShippingMethodChanged>(_onShippingMethodChanged);
    on<OrderFormDiscordNameChanged>(_onDiscordNameChanged);
    on<OrderFormSubmitted>(_onSubmitted);
  }

  void _onProfileLoaded(
    OrderFormProfileLoaded event,
    Emitter<OrderFormState> emit,
  ) {
    emit(state.copyWith(
      discordName: event.user.discordName,
      prefillAddress: event.user.savedAddress,
      prefillPhone: event.user.phone,
    ));
  }

  Future<void> _onLanguageSelected(
    OrderFormLanguageSelected event,
    Emitter<OrderFormState> emit,
  ) async {
    emit(state.copyWith(status: OrderFormStatus.loading, language: event.language));
    try {
      final products = await _productRepository.getProducts(event.language);
      emit(state.copyWith(
        status: OrderFormStatus.initial,
        availableProducts: products,
        selectedItems: {},
        shippingMethod: null,
      ));
    } catch (e) {
      emit(state.copyWith(status: OrderFormStatus.failure, errorMessage: e.toString()));
    }
  }

  void _onItemAdded(
    OrderFormItemAdded event,
    Emitter<OrderFormState> emit,
  ) {
    final updatedItems = Map<String, int>.from(state.selectedItems);
    if (event.quantity <= 0) {
      updatedItems.remove(event.product.id);
    } else {
      updatedItems[event.product.id] = event.quantity;
    }

    final updatedRequests = updatedItems.entries
        .where((e) => e.value > 0)
        .map((e) => OrderItemRequest(productId: e.key, quantity: e.value))
        .toList();

    emit(state.copyWith(
      selectedItems: updatedItems,
      itemRequests: updatedRequests,
    ));
  }

  void _onShippingMethodChanged(
    OrderFormShippingMethodChanged event,
    Emitter<OrderFormState> emit,
  ) {
    emit(state.copyWith(shippingMethod: event.shippingMethod));
  }

  void _onDiscordNameChanged(
    OrderFormDiscordNameChanged event,
    Emitter<OrderFormState> emit,
  ) {
    emit(state.copyWith(discordName: event.discordName));
  }

  Future<void> _onSubmitted(
    OrderFormSubmitted event,
    Emitter<OrderFormState> emit,
  ) async {
    if (state.language == null || state.itemRequests.isEmpty) return;

    emit(state.copyWith(status: OrderFormStatus.loading));
    try {
      final request = CreateOrderRequest(
        language: state.language!,
        items: state.itemRequests,
        shippingAddress: event.address,
        shippingMethod: state.shippingMethod,
        discordName: state.discordName,
      );
      await _orderRepository.createOrder(request);
      emit(state.copyWith(status: OrderFormStatus.success));
    } catch (e) {
      emit(state.copyWith(status: OrderFormStatus.failure, errorMessage: e.toString()));
    }
  }
}
