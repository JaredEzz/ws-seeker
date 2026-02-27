import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';
import '../../repositories/order_repository.dart';

// Events
sealed class AllChatsEvent {
  const AllChatsEvent();
}

final class AllChatsFetchRequested extends AllChatsEvent {
  const AllChatsFetchRequested();
}

final class _AllChatsOrderCommentsUpdated extends AllChatsEvent {
  final String orderId;
  final List<OrderComment> comments;
  const _AllChatsOrderCommentsUpdated(this.orderId, this.comments);
}

final class _AllChatsError extends AllChatsEvent {
  final String message;
  const _AllChatsError(this.message);
}

// Data class for a conversation group
class OrderConversation {
  final Order order;
  final List<OrderComment> comments;

  const OrderConversation({required this.order, required this.comments});

  DateTime get lastMessageTime =>
      comments.isNotEmpty ? comments.first.createdAt : order.updatedAt;
}

// States
sealed class AllChatsState {
  const AllChatsState();
}

final class AllChatsInitial extends AllChatsState {
  const AllChatsInitial();
}

final class AllChatsLoading extends AllChatsState {
  const AllChatsLoading();
}

final class AllChatsLoaded extends AllChatsState {
  final List<OrderConversation> conversations;
  const AllChatsLoaded({required this.conversations});
}

final class AllChatsFailure extends AllChatsState {
  final String message;
  const AllChatsFailure({required this.message});
}

// BLoC
class AllChatsBloc extends Bloc<AllChatsEvent, AllChatsState> {
  final OrderRepository _orderRepository;
  final List<StreamSubscription<List<OrderComment>>> _commentSubscriptions = [];
  List<Order> _orders = [];
  final Map<String, List<OrderComment>> _commentsByOrder = {};

  AllChatsBloc({required OrderRepository orderRepository})
      : _orderRepository = orderRepository,
        super(const AllChatsInitial()) {
    on<AllChatsFetchRequested>(_onFetchRequested);
    on<_AllChatsOrderCommentsUpdated>(_onOrderCommentsUpdated);
    on<_AllChatsError>(_onError);
  }

  Future<void> _onFetchRequested(
    AllChatsFetchRequested event,
    Emitter<AllChatsState> emit,
  ) async {
    emit(const AllChatsLoading());

    // Cancel previous per-order subscriptions
    for (final sub in _commentSubscriptions) {
      await sub.cancel();
    }
    _commentSubscriptions.clear();
    _commentsByOrder.clear();

    try {
      // getOrders() is already role-filtered (supplier → JPN only, etc.)
      final orders = await _orderRepository.getOrders();
      _orders = orders;

      if (orders.isEmpty) {
        emit(const AllChatsLoaded(conversations: []));
        return;
      }

      // Pre-populate empty comment lists so orders with 0 comments still
      // appear in the aggregated view immediately.
      for (final order in orders) {
        _commentsByOrder[order.id] = [];
      }

      // Watch comments for each order individually — uses per-document
      // subcollection reads which respect Firestore security rules.
      // Errors on individual orders are isolated to avoid poisoning the
      // entire view.
      for (final order in orders) {
        final sub = _orderRepository.watchComments(order.id).listen(
          (comments) => add(_AllChatsOrderCommentsUpdated(order.id, comments)),
          onError: (e) {
            // Isolate per-order errors — log but don't kill the whole view.
            print('Failed to watch comments for order ${order.id}: $e');
          },
        );
        _commentSubscriptions.add(sub);
      }

      // Emit initial state with all orders (0 comments each) so the UI
      // doesn't stay on Loading until the first comment stream fires.
      _rebuildConversations(emit);
    } catch (e) {
      emit(AllChatsFailure(message: e.toString()));
    }
  }

  void _onOrderCommentsUpdated(
    _AllChatsOrderCommentsUpdated event,
    Emitter<AllChatsState> emit,
  ) {
    _commentsByOrder[event.orderId] = event.comments;
    _rebuildConversations(emit);
  }

  void _rebuildConversations(Emitter<AllChatsState> emit) {
    final orderMap = {for (final o in _orders) o.id: o};

    final conversations = <OrderConversation>[];
    for (final entry in _commentsByOrder.entries) {
      final order = orderMap[entry.key];
      if (order != null) {
        // watchComments returns ascending; reverse for most-recent-first
        final sorted = List<OrderComment>.from(entry.value)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        conversations.add(OrderConversation(
          order: order,
          comments: sorted,
        ));
      }
    }

    // Sort conversations by most recent message first
    conversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

    emit(AllChatsLoaded(conversations: conversations));
  }

  void _onError(
    _AllChatsError event,
    Emitter<AllChatsState> emit,
  ) {
    emit(AllChatsFailure(message: event.message));
  }

  @override
  Future<void> close() {
    for (final sub in _commentSubscriptions) {
      sub.cancel();
    }
    return super.close();
  }
}
