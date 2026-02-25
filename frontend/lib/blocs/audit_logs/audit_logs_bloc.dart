import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';

import '../../repositories/audit_log_repository.dart';

// Events
sealed class AuditLogsEvent {
  const AuditLogsEvent();
}

final class AuditLogsFetchRequested extends AuditLogsEvent {
  final AuditLogQuery query;
  const AuditLogsFetchRequested({required this.query});
}

final class AuditLogsNextPageRequested extends AuditLogsEvent {
  const AuditLogsNextPageRequested();
}

// States
sealed class AuditLogsState {
  const AuditLogsState();
}

final class AuditLogsInitial extends AuditLogsState {
  const AuditLogsInitial();
}

final class AuditLogsLoading extends AuditLogsState {
  const AuditLogsLoading();
}

final class AuditLogsLoaded extends AuditLogsState {
  final List<AuditLog> logs;
  final int total;
  final AuditLogQuery lastQuery;
  final bool isLoadingMore;

  const AuditLogsLoaded({
    required this.logs,
    required this.total,
    required this.lastQuery,
    this.isLoadingMore = false,
  });
}

final class AuditLogsFailure extends AuditLogsState {
  final String message;
  const AuditLogsFailure({required this.message});
}

// BLoC
class AuditLogsBloc extends Bloc<AuditLogsEvent, AuditLogsState> {
  final AuditLogRepository _repository;

  AuditLogsBloc({required AuditLogRepository repository})
      : _repository = repository,
        super(const AuditLogsInitial()) {
    on<AuditLogsFetchRequested>(_onFetchRequested);
    on<AuditLogsNextPageRequested>(_onNextPageRequested);
  }

  Future<void> _onFetchRequested(
    AuditLogsFetchRequested event,
    Emitter<AuditLogsState> emit,
  ) async {
    emit(const AuditLogsLoading());
    try {
      final page = await _repository.getAuditLogs(event.query);
      emit(AuditLogsLoaded(
        logs: page.logs,
        total: page.total,
        lastQuery: event.query,
      ));
    } catch (e) {
      emit(AuditLogsFailure(message: e.toString()));
    }
  }

  Future<void> _onNextPageRequested(
    AuditLogsNextPageRequested event,
    Emitter<AuditLogsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AuditLogsLoaded) return;
    if (currentState.logs.length >= currentState.total) return;

    emit(AuditLogsLoaded(
      logs: currentState.logs,
      total: currentState.total,
      lastQuery: currentState.lastQuery,
      isLoadingMore: true,
    ));

    try {
      final nextQuery = AuditLogQuery(
        action: currentState.lastQuery.action,
        resourceType: currentState.lastQuery.resourceType,
        search: currentState.lastQuery.search,
        startDate: currentState.lastQuery.startDate,
        endDate: currentState.lastQuery.endDate,
        limit: currentState.lastQuery.limit,
        offset: currentState.logs.length,
      );
      final page = await _repository.getAuditLogs(nextQuery);
      emit(AuditLogsLoaded(
        logs: [...currentState.logs, ...page.logs],
        total: page.total,
        lastQuery: currentState.lastQuery,
      ));
    } catch (e) {
      emit(AuditLogsFailure(message: e.toString()));
    }
  }
}
