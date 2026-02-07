import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';
import '../../repositories/order_repository.dart';

// Events
sealed class OrdersEvent {
  const OrdersEvent();
}

final class OrdersFetchRequested extends OrdersEvent {
  final OrderFilter? filter;
  const OrdersFetchRequested({this.filter});
}

final class OrderStatusUpdateRequested extends OrdersEvent {
  final String orderId;
  final OrderStatus status;
  const OrderStatusUpdateRequested({required this.orderId, required this.status});
}

// State
sealed class OrdersState {
  const OrdersState();
}

final class OrdersInitial extends OrdersState {
  const OrdersInitial();
}

final class OrdersLoading extends OrdersState {
  const OrdersLoading();
}

final class OrdersLoaded extends OrdersState {
  final List<Order> orders;
  const OrdersLoaded({required this.orders});
}

final class OrdersFailure extends OrdersState {
  final String message;
  const OrdersFailure({required this.message});
}

// BLoC
class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final OrderRepository _orderRepository;

  OrdersBloc({required OrderRepository orderRepository})
      : _orderRepository = orderRepository,
        super(const OrdersInitial()) {
    on<OrdersFetchRequested>(_onFetchRequested);
    on<OrderStatusUpdateRequested>(_onStatusUpdateRequested);
  }

  Future<void> _onFetchRequested(
    OrdersFetchRequested event,
    Emitter<OrdersState> emit,
  ) async {
    emit(const OrdersLoading());
    try {
      final orders = await _orderRepository.getOrders(filter: event.filter);
      emit(OrdersLoaded(orders: orders));
    } catch (e) {
      emit(OrdersFailure(message: e.toString()));
    }
  }

  Future<void> _onStatusUpdateRequested(
    OrderStatusUpdateRequested event,
    Emitter<OrdersState> emit,
  ) async {
    try {
      await _orderRepository.updateOrder(
        event.orderId,
        UpdateOrderRequest(status: event.status),
      );
      add(const OrdersFetchRequested());
    } catch (e) {
      // Handle error
    }
  }
}
