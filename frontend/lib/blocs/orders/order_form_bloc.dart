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

  const OrderFormState({
    this.status = OrderFormStatus.initial,
    this.language,
    this.availableProducts = const [],
    this.selectedItems = const {},
    this.itemRequests = const [],
    this.errorMessage,
  });

  OrderFormState copyWith({
    OrderFormStatus? status,
    ProductLanguage? language,
    List<Product>? availableProducts,
    Map<String, int>? selectedItems,
    List<OrderItemRequest>? itemRequests,
    String? errorMessage,
  }) {
    return OrderFormState(
      status: status ?? this.status,
      language: language ?? this.language,
      availableProducts: availableProducts ?? this.availableProducts,
      selectedItems: selectedItems ?? this.selectedItems,
      itemRequests: itemRequests ?? this.itemRequests,
      errorMessage: errorMessage ?? this.errorMessage,
    );
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
    on<OrderFormSubmitted>(_onSubmitted);
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
    updatedItems[event.product.id] = event.quantity;
    
    final updatedRequests = updatedItems.entries
        .map((e) => OrderItemRequest(productId: e.key, quantity: e.value))
        .toList();

    emit(state.copyWith(
      selectedItems: updatedItems,
      itemRequests: updatedRequests,
    ));
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
      );
      await _orderRepository.createOrder(request);
      emit(state.copyWith(status: OrderFormStatus.success));
    } catch (e) {
      emit(state.copyWith(status: OrderFormStatus.failure, errorMessage: e.toString()));
    }
  }
}
