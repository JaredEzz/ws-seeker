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

final class _AllChatsCommentsUpdated extends AllChatsEvent {
  final List<OrderComment> comments;
  const _AllChatsCommentsUpdated(this.comments);
}

final class _AllChatsOrdersLoaded extends AllChatsEvent {
  final List<Order> orders;
  const _AllChatsOrdersLoaded(this.orders);
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
  StreamSubscription<List<OrderComment>>? _commentsSubscription;
  List<Order> _orders = [];
  List<OrderComment> _allComments = [];

  AllChatsBloc({required OrderRepository orderRepository})
      : _orderRepository = orderRepository,
        super(const AllChatsInitial()) {
    on<AllChatsFetchRequested>(_onFetchRequested);
    on<_AllChatsOrdersLoaded>(_onOrdersLoaded);
    on<_AllChatsCommentsUpdated>(_onCommentsUpdated);
    on<_AllChatsError>(_onError);
  }

  Future<void> _onFetchRequested(
    AllChatsFetchRequested event,
    Emitter<AllChatsState> emit,
  ) async {
    emit(const AllChatsLoading());

    try {
      final orders = await _orderRepository.getOrders();
      _orders = orders;

      // Start watching all comments
      _commentsSubscription?.cancel();
      _commentsSubscription = _orderRepository.watchAllComments().listen(
        (comments) => add(_AllChatsCommentsUpdated(comments)),
        onError: (e) => add(_AllChatsError(e.toString())),
      );
    } catch (e) {
      emit(AllChatsFailure(message: e.toString()));
    }
  }

  void _onOrdersLoaded(
    _AllChatsOrdersLoaded event,
    Emitter<AllChatsState> emit,
  ) {
    _orders = event.orders;
    _rebuildConversations(emit);
  }

  void _onCommentsUpdated(
    _AllChatsCommentsUpdated event,
    Emitter<AllChatsState> emit,
  ) {
    _allComments = event.comments;
    _rebuildConversations(emit);
  }

  void _rebuildConversations(Emitter<AllChatsState> emit) {
    // Build a set of known order IDs for filtering
    final orderMap = {for (final o in _orders) o.id: o};

    // Group comments by orderId
    final commentsByOrder = <String, List<OrderComment>>{};
    for (final comment in _allComments) {
      if (orderMap.containsKey(comment.orderId)) {
        commentsByOrder.putIfAbsent(comment.orderId, () => []).add(comment);
      }
    }

    // Build conversations — only orders that have comments
    final conversations = <OrderConversation>[];
    for (final entry in commentsByOrder.entries) {
      final order = orderMap[entry.key];
      if (order != null) {
        // Comments arrive sorted desc from Firestore already
        conversations.add(OrderConversation(
          order: order,
          comments: entry.value,
        ));
      }
    }

    // Sort by most recent message first
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
    _commentsSubscription?.cancel();
    return super.close();
  }
}
