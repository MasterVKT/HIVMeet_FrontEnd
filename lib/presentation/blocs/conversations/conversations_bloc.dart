// lib/presentation/blocs/conversations/conversations_bloc.dart

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/domain/usecases/message/get_conversations.dart';
import 'package:hivmeet/domain/usecases/message/send_message.dart';
import 'package:hivmeet/domain/usecases/message/mark_as_read.dart';

part 'conversations_event.dart';
part 'conversations_state.dart';

/// BLoC pour gérer la liste des conversations
///
/// Features:
/// - Chargement initial et pagination
/// - Rafraîchissement (pull-to-refresh)
/// - Filtrage/recherche local
/// - Optimistic updates pour mark as read
/// - Tri par dernière activité
@injectable
class ConversationsBloc extends Bloc<ConversationsEvent, ConversationsState> {
  final GetConversations _getConversations;
  final SendMessage _sendMessage;
  final MarkAsRead _markAsRead;

  // État interne pour gérer la pagination
  List<Conversation> _allConversations = [];
  bool _hasMore = true;

  ConversationsBloc({
    required GetConversations getConversations,
    required SendMessage sendMessage,
    required MarkAsRead markAsRead,
  })  : _getConversations = getConversations,
        _sendMessage = sendMessage,
        _markAsRead = markAsRead,
        super(ConversationsInitial()) {
    on<LoadConversations>(_onLoadConversations);
    on<LoadMoreConversations>(_onLoadMoreConversations);
    on<RefreshConversations>(_onRefreshConversations);
    on<MarkConversationAsRead>(_onMarkConversationAsRead);
    on<SearchConversations>(_onSearchConversations);
  }

  Future<void> _onLoadConversations(
    LoadConversations event,
    Emitter<ConversationsState> emit,
  ) async {
    if (event.refresh) {
      _allConversations = [];
      _hasMore = true;
    }

    emit(ConversationsLoading());

    final params = GetConversationsParams.initial();
    final result = await _getConversations(params);

    result.fold(
      (failure) => emit(ConversationsError(message: failure.message)),
      (conversations) {
        _allConversations = conversations;
        _hasMore = conversations.length >= 20;

        final totalUnread = conversations
            .map((c) => c.unreadCount)
            .fold(0, (sum, count) => sum + count);

        emit(ConversationsLoaded(
          conversations: conversations,
          allConversations: conversations,
          hasMore: _hasMore,
          isLoadingMore: false,
          totalUnreadCount: totalUnread,
          searchQuery: '',
        ));
      },
    );
  }

  Future<void> _onLoadMoreConversations(
    LoadMoreConversations event,
    Emitter<ConversationsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ConversationsLoaded) return;
    if (!_hasMore || currentState.isLoadingMore) return;

    emit(currentState.copyWith(isLoadingMore: true));

    final lastConversationId = _allConversations.isNotEmpty
        ? _allConversations.last.id
        : null;

    if (lastConversationId == null) {
      emit(currentState.copyWith(isLoadingMore: false));
      return;
    }

    final params = GetConversationsParams.initial().nextPage(lastConversationId);
    final result = await _getConversations(params);

    result.fold(
      (failure) {
        emit(currentState.copyWith(isLoadingMore: false));
        emit(ConversationsError(message: failure.message));
      },
      (newConversations) {
        if (newConversations.isEmpty) {
          _hasMore = false;
        } else {
          _allConversations.addAll(newConversations);
          _hasMore = newConversations.length >= 20;
        }

        final totalUnread = _allConversations
            .map((c) => c.unreadCount)
            .fold(0, (sum, count) => sum + count);

        emit(ConversationsLoaded(
          conversations: _allConversations,
          allConversations: _allConversations,
          hasMore: _hasMore,
          isLoadingMore: false,
          totalUnreadCount: totalUnread,
          searchQuery: currentState.searchQuery,
        ));
      },
    );
  }

  Future<void> _onRefreshConversations(
    RefreshConversations event,
    Emitter<ConversationsState> emit,
  ) async {
    add(LoadConversations(refresh: true));
  }

  Future<void> _onMarkConversationAsRead(
    MarkConversationAsRead event,
    Emitter<ConversationsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ConversationsLoaded) return;

    // Optimistic update
    final updatedConversations = _allConversations.map((conv) {
      if (conv.id == event.conversationId) {
        return Conversation(
          id: conv.id,
          participantIds: conv.participantIds,
          lastMessage: conv.lastMessage,
          unreadCount: 0,
          updatedAt: conv.updatedAt,
        );
      }
      return conv;
    }).toList();

    final totalUnread = updatedConversations
        .map((c) => c.unreadCount)
        .fold(0, (sum, count) => sum + count);

    emit(currentState.copyWith(
      conversations: updatedConversations,
      allConversations: updatedConversations,
      totalUnreadCount: totalUnread,
    ));

    // Appel API
    final params = MarkAsReadParams(conversationId: event.conversationId);
    final result = await _markAsRead(params);

    result.fold(
      (failure) {
        // Rollback en cas d'erreur
        emit(currentState);
        emit(ConversationsError(message: failure.message));
      },
      (_) {
        // Succès - update déjà fait en optimistic
        _allConversations = updatedConversations;
      },
    );
  }

  void _onSearchConversations(
    SearchConversations event,
    Emitter<ConversationsState> emit,
  ) {
    final currentState = state;
    if (currentState is! ConversationsLoaded) return;

    final query = event.query.toLowerCase();

    if (query.isEmpty) {
      emit(currentState.copyWith(
        conversations: _allConversations,
        searchQuery: '',
      ));
      return;
    }

    // Recherche locale par nom de participant
    // TODO: Enrichir avec les noms des participants depuis ProfileRepository
    final filtered = _allConversations.where((conv) {
      // Pour l'instant, recherche basique sur le contenu du dernier message
      final lastMessageContent = conv.lastMessage?.content.toLowerCase() ?? '';
      return lastMessageContent.contains(query);
    }).toList();

    emit(currentState.copyWith(
      conversations: filtered,
      searchQuery: query,
    ));
  }
}
