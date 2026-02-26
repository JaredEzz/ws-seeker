import 'dart:async';
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

final class _CommentsUpdated extends CommentsEvent {
  final List<OrderComment> comments;
  const _CommentsUpdated(this.comments);
}

final class _CommentsError extends CommentsEvent {
  final String message;
  const _CommentsError(this.message);
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
  StreamSubscription<List<OrderComment>>? _subscription;

  CommentsBloc({required OrderRepository orderRepository})
      : _orderRepository = orderRepository,
        super(const CommentsInitial()) {
    on<CommentsFetchRequested>(_onFetchRequested);
    on<CommentSendRequested>(_onSendRequested);
    on<_CommentsUpdated>(_onUpdated);
    on<_CommentsError>(_onError);
  }

  void _onFetchRequested(
    CommentsFetchRequested event,
    Emitter<CommentsState> emit,
  ) {
    emit(const CommentsLoading());
    _subscription?.cancel();
    _subscription = _orderRepository.watchComments(event.orderId).listen(
      (comments) => add(_CommentsUpdated(comments)),
      onError: (e) => add(_CommentsError(e.toString())),
    );
  }

  void _onUpdated(
    _CommentsUpdated event,
    Emitter<CommentsState> emit,
  ) {
    emit(CommentsLoaded(comments: event.comments));
  }

  void _onError(
    _CommentsError event,
    Emitter<CommentsState> emit,
  ) {
    emit(CommentsFailure(message: event.message));
  }

  Future<void> _onSendRequested(
    CommentSendRequested event,
    Emitter<CommentsState> emit,
  ) async {
    try {
      await _orderRepository.addComment(event.orderId, event.content);
      // No need to manually refresh — Firestore stream will emit the update
    } catch (e) {
      emit(CommentsFailure(message: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
