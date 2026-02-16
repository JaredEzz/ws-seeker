import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';
import '../../repositories/order_repository.dart';

// Events
sealed class CommentsEvent {
  const CommentsEvent();
}

final class CommentsFetchRequested extends CommentsEvent {
  final String orderId;
  const CommentsFetchRequested({required this.orderId});
}

final class CommentSendRequested extends CommentsEvent {
  final String orderId;
  final String content;
  const CommentSendRequested({required this.orderId, required this.content});
}

// States
sealed class CommentsState {
  const CommentsState();
}

final class CommentsInitial extends CommentsState {
  const CommentsInitial();
}

final class CommentsLoading extends CommentsState {
  const CommentsLoading();
}

final class CommentsLoaded extends CommentsState {
  final List<OrderComment> comments;
  const CommentsLoaded({required this.comments});
}

final class CommentsFailure extends CommentsState {
  final String message;
  const CommentsFailure({required this.message});
}

// BLoC
class CommentsBloc extends Bloc<CommentsEvent, CommentsState> {
  final OrderRepository _orderRepository;

  CommentsBloc({required OrderRepository orderRepository})
      : _orderRepository = orderRepository,
        super(const CommentsInitial()) {
    on<CommentsFetchRequested>(_onFetchRequested);
    on<CommentSendRequested>(_onSendRequested);
  }

  Future<void> _onFetchRequested(
    CommentsFetchRequested event,
    Emitter<CommentsState> emit,
  ) async {
    emit(const CommentsLoading());
    try {
      final comments = await _orderRepository
          .watchComments(event.orderId)
          .first;
      emit(CommentsLoaded(comments: comments));
    } catch (e) {
      emit(CommentsFailure(message: e.toString()));
    }
  }

  Future<void> _onSendRequested(
    CommentSendRequested event,
    Emitter<CommentsState> emit,
  ) async {
    try {
      await _orderRepository.addComment(event.orderId, event.content);
      // Re-fetch comments after sending
      add(CommentsFetchRequested(orderId: event.orderId));
    } catch (e) {
      emit(CommentsFailure(message: e.toString()));
    }
  }
}
