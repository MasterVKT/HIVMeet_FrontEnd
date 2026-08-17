import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/realtime/realtime_event.dart';
import 'package:hivmeet/core/realtime/realtime_event_bus.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/domain/usecases/message/delete_conversation.dart'
    as delete_conversation;
import 'package:hivmeet/domain/usecases/message/get_conversations.dart';
import 'package:hivmeet/domain/usecases/message/mark_as_read.dart';
import 'package:hivmeet/domain/usecases/message/send_message.dart';

part 'conversations_event.dart';
part 'conversations_state.dart';

@injectable
class ConversationsBloc extends Bloc<ConversationsEvent, ConversationsState> {
  final GetConversations _getConversations;
  // Reserved for local conversation send shortcuts in a later phase.
  // ignore: unused_field
  final SendMessage _sendMessage;
  final MarkAsRead _markAsRead;
  final delete_conversation.DeleteConversation _deleteConversation;
  final RealtimeEventBus _realtimeBus;

  List<Conversation> _allConversations = [];
  bool _hasMore = true;
  int _currentPage = 1;
  int _loadGeneration = 0;
  ConversationFilter _activeFilter = ConversationFilter.all;

  StreamSubscription<RealtimeEvent>? _realtimeSub;
  Timer? _reconcileDebounce;
  static const _reconcileDebounceDelay = Duration(milliseconds: 600);

  ConversationsBloc({
    required GetConversations getConversations,
    required SendMessage sendMessage,
    required MarkAsRead markAsRead,
    required delete_conversation.DeleteConversation deleteConversation,
    required RealtimeEventBus realtimeBus,
  })  : _getConversations = getConversations,
        _sendMessage = sendMessage,
        _markAsRead = markAsRead,
        _deleteConversation = deleteConversation,
        _realtimeBus = realtimeBus,
        super(ConversationsInitial()) {
    on<LoadConversations>(_onLoadConversations);
    on<LoadMoreConversations>(_onLoadMoreConversations);
    on<RefreshConversations>(_onRefreshConversations);
    on<ChangeConversationFilter>(_onChangeConversationFilter);
    on<MarkConversationAsRead>(_onMarkConversationAsRead);
    on<SearchConversations>(_onSearchConversations);
    on<DeleteConversation>(_onDeleteConversation);
    on<ClearConversationActionError>(_onClearActionError);
    on<ConversationRealtimeSignal>(_onConversationRealtimeSignal);
    on<ReconcileConversations>(_onReconcileConversations);

    // Abonnement au bus dans le constructeur (pas via un événement `Start`)
    // pour être actif dès la création du BLoC, indépendamment du cycle de
    // vie de la page qui le consomme.
    _realtimeSub = _realtimeBus.events.listen(_onRealtimeEvent);
  }

  void _onRealtimeEvent(RealtimeEvent event) {
    switch (event.type) {
      case RealtimeEventType.newMessage:
        final conversationId = event.conversationId;
        if (conversationId == null || conversationId.isEmpty) {
          add(const ReconcileConversations());
          return;
        }
        add(ConversationRealtimeSignal(
          conversationId: conversationId,
          preview: event.preview,
          senderId: event.fromUserId,
        ));
      case RealtimeEventType.newMatch:
      case RealtimeEventType.messageRead:
      case RealtimeEventType.messageDelivered:
      case RealtimeEventType.conversationRead:
      case RealtimeEventType.appResumed:
        add(const ReconcileConversations());
      case RealtimeEventType.likeReceived:
      case RealtimeEventType.superLikeReceived:
        // Sans lien avec la liste des conversations.
        break;
    }
  }

  Future<void> _onLoadConversations(
    LoadConversations event,
    Emitter<ConversationsState> emit,
  ) async {
    final previous = state;
    final searchQuery =
        previous is ConversationsLoaded ? previous.searchQuery : '';
    final generation = ++_loadGeneration;
    if (event.refresh) {
      _allConversations = [];
      _hasMore = true;
      _currentPage = 1;
    }

    emit(ConversationsLoading(activeFilter: _activeFilter));
    final result = await _getConversations(
      GetConversationsParams.initial(filter: _activeFilter),
    );
    if (generation != _loadGeneration) return;

    result.fold(
      (failure) => emit(ConversationsError(message: failure.message)),
      (page) {
        _currentPage = 1;
        _allConversations = _sortConversations(page.conversations);
        _hasMore = page.hasMore;
        emit(_loaded(searchQuery: searchQuery));
      },
    );
  }

  Future<void> _onLoadMoreConversations(
    LoadMoreConversations event,
    Emitter<ConversationsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ConversationsLoaded ||
        !_hasMore ||
        currentState.isLoadingMore) {
      return;
    }
    final generation = _loadGeneration;
    emit(currentState.copyWith(isLoadingMore: true));
    final result = await _getConversations(
      GetConversationsParams.initial(filter: _activeFilter)
          .nextPage(_currentPage + 1),
    );
    if (generation != _loadGeneration) return;

    result.fold(
      (_) => emit(_loaded(
        searchQuery: currentState.searchQuery,
        actionError: currentState.actionError,
      )),
      (page) {
        if (page.conversations.isEmpty) {
          _hasMore = false;
        } else {
          _currentPage += 1;
          _allConversations = _sortConversations([
            ..._allConversations,
            ...page.conversations,
          ]);
          _hasMore = page.hasMore;
        }
        emit(_loaded(searchQuery: currentState.searchQuery));
      },
    );
  }

  Future<void> _onRefreshConversations(
    RefreshConversations event,
    Emitter<ConversationsState> emit,
  ) async {
    add(const LoadConversations(refresh: true));
  }

  Future<void> _onChangeConversationFilter(
    ChangeConversationFilter event,
    Emitter<ConversationsState> emit,
  ) async {
    if (event.filter == _activeFilter) return;
    _loadGeneration++;
    _activeFilter = event.filter;
    _allConversations = [];
    _hasMore = true;
    _currentPage = 1;
    emit(ConversationsLoading(activeFilter: _activeFilter));
    add(const LoadConversations(refresh: true));
  }

  Future<void> _onMarkConversationAsRead(
    MarkConversationAsRead event,
    Emitter<ConversationsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ConversationsLoaded) return;
    final conversation = _conversationById(event.conversationId);
    if (conversation?.lastMessage == null || conversation!.unreadCount == 0) {
      return;
    }
    final generation = _loadGeneration;

    final result = await _markAsRead(MarkAsReadParams(
      conversationId: event.conversationId,
      messageId: conversation.lastMessage!.id,
    ));
    if (generation != _loadGeneration) return;
    result.fold(
      (_) => emit(currentState.copyWith(
        actionError:
            LocalizationService.translate('conversations.mark_read_failed'),
      )),
      (readResult) {
        _allConversations = _allConversations.map((item) {
          return item.id == event.conversationId
              ? item.copyWith(unreadCount: readResult.unreadCountForMe)
              : item;
        }).toList();
        emit(_loaded(searchQuery: currentState.searchQuery));
      },
    );
  }

  void _onSearchConversations(
    SearchConversations event,
    Emitter<ConversationsState> emit,
  ) {
    if (state is! ConversationsLoaded) return;
    emit(_loaded(searchQuery: event.query));
  }

  Future<void> _onDeleteConversation(
    DeleteConversation event,
    Emitter<ConversationsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ConversationsLoaded ||
        _conversationById(event.conversationId) == null) {
      return;
    }

    final snapshot = List<Conversation>.from(_allConversations);
    final snapshotHasMore = _hasMore;
    final snapshotPage = _currentPage;
    final generation = _loadGeneration;
    _allConversations = _allConversations
        .where((conversation) => conversation.id != event.conversationId)
        .toList();
    emit(_loaded(searchQuery: currentState.searchQuery));

    final result = await _deleteConversation(
      delete_conversation.DeleteConversationParams(
        conversationId: event.conversationId,
      ),
    );
    if (generation != _loadGeneration) return;
    result.fold(
      (failure) {
        if (failure.code == 'not-found') return;
        _allConversations = snapshot;
        _hasMore = snapshotHasMore;
        _currentPage = snapshotPage;
        emit(_loaded(
          searchQuery: currentState.searchQuery,
          actionError: _deleteFailureMessage(failure),
        ));
      },
      (_) {},
    );
  }

  void _onClearActionError(
    ClearConversationActionError event,
    Emitter<ConversationsState> emit,
  ) {
    final currentState = state;
    if (currentState is ConversationsLoaded &&
        currentState.actionError != null) {
      emit(currentState.copyWith(actionError: null));
    }
  }

  /// Patch optimiste instantané (sans requête réseau) suivi d'une
  /// réconciliation serveur débouncée. N'émet jamais `ConversationsLoading` —
  /// contrairement à `LoadConversations`, qui provoquerait un flash d'écran
  /// de chargement à chaque message temps réel reçu.
  void _onConversationRealtimeSignal(
    ConversationRealtimeSignal event,
    Emitter<ConversationsState> emit,
  ) {
    if (state is! ConversationsLoaded) {
      _scheduleReconcile();
      return;
    }

    // La conversation actuellement ouverte gère déjà son propre temps réel
    // via ChatBloc (qui marque les messages lus au fil de l'eau) ; y
    // appliquer aussi un incrément optimiste ici créerait un badge non-lu
    // transitoire incorrect pour un écran que l'utilisateur regarde déjà.
    final isActiveConversation =
        event.conversationId == _realtimeBus.activeConversationId;
    if (!isActiveConversation) {
      final index = _allConversations.indexWhere(
        (conversation) => conversation.id == event.conversationId,
      );
      if (index >= 0) {
        final existing = _allConversations[index];
        final optimisticMessage = Message(
          id: 'optimistic_${DateTime.now().microsecondsSinceEpoch}',
          conversationId: event.conversationId,
          senderId: event.senderId ?? existing.otherUserId ?? '',
          content: event.preview ?? existing.lastMessage?.content ?? '',
          type: MessageType.text,
          createdAt: DateTime.now(),
          status: MessageStatus.sent,
        );
        final updated = existing.copyWith(
          lastMessage: optimisticMessage,
          unreadCount: existing.unreadCount + 1,
          updatedAt: DateTime.now(),
        );
        _allConversations = _sortConversations([
          ..._allConversations.where((c) => c.id != event.conversationId),
          updated,
        ]);
        emit(_loaded(
          searchQuery: (state as ConversationsLoaded).searchQuery,
        ));
      }
      // Conversation absente du cache local (ex: premier message d'une
      // conversation pas encore chargée) : rien à patcher localement, la
      // réconciliation ci-dessous s'en chargera.
    }

    _scheduleReconcile();
  }

  void _scheduleReconcile() {
    _reconcileDebounce?.cancel();
    _reconcileDebounce = Timer(_reconcileDebounceDelay, () {
      add(const ReconcileConversations());
    });
  }

  /// Recharge la première page côté serveur et la fusionne dans le cache
  /// local sans jamais émettre `ConversationsLoading`. Idempotente : deux
  /// signaux temps réel pour le même message (WebSocket + FCM) convergent
  /// vers le même état car `unread_count_for_me` fait autorité côté serveur.
  Future<void> _onReconcileConversations(
    ReconcileConversations event,
    Emitter<ConversationsState> emit,
  ) async {
    final generation = _loadGeneration;
    final result = await _getConversations(
      GetConversationsParams.initial(filter: _activeFilter),
    );
    if (generation != _loadGeneration) return;

    result.fold(
      (_) {
        // Échec silencieux : le cache local reste affiché tel quel, la
        // prochaine réconciliation (ou action manuelle) retentera.
      },
      (page) {
        final fresh = {for (final c in page.conversations) c.id: c};
        final merged = [
          for (final existing in _allConversations)
            fresh[existing.id] ?? existing,
          for (final entry in fresh.entries)
            if (!_allConversations.any((c) => c.id == entry.key)) entry.value,
        ];
        _allConversations = _sortConversations(merged);
        final currentState = state;
        // Si un chargement est en cours (`ConversationsLoading`) ou n'a pas
        // encore démarré (`ConversationsInitial`), on ne fait qu'actualiser
        // le cache : ce chargement émettra son propre état à son tour.
        if (currentState is ConversationsLoaded) {
          emit(_loaded(searchQuery: currentState.searchQuery));
        }
      },
    );
  }

  @override
  Future<void> close() async {
    _reconcileDebounce?.cancel();
    await _realtimeSub?.cancel();
    return super.close();
  }

  ConversationsLoaded _loaded({
    required String searchQuery,
    String? actionError,
  }) {
    final normalizedQuery = searchQuery.trim().toLowerCase();
    final visible = normalizedQuery.isEmpty
        ? _allConversations
        : _allConversations.where((conversation) {
            final name = conversation.otherUserName?.toLowerCase() ?? '';
            final content =
                conversation.lastMessage?.content.toLowerCase() ?? '';
            return name.contains(normalizedQuery) ||
                content.contains(normalizedQuery);
          }).toList();
    final totalUnread = _allConversations.fold<int>(
      0,
      (sum, conversation) => sum + conversation.unreadCount,
    );
    return ConversationsLoaded(
      conversations: visible,
      allConversations: _allConversations,
      hasMore: _hasMore,
      isLoadingMore: false,
      totalUnreadCount: totalUnread,
      searchQuery: normalizedQuery,
      activeFilter: _activeFilter,
      actionError: actionError,
    );
  }

  Conversation? _conversationById(String conversationId) {
    for (final conversation in _allConversations) {
      if (conversation.id == conversationId) return conversation;
    }
    return null;
  }

  String _deleteFailureMessage(Failure failure) {
    if (failure is AuthFailure) {
      return LocalizationService.translate('conversations.hide_auth_error');
    }
    return LocalizationService.translate('conversations.hide_failed');
  }

  List<Conversation> _sortConversations(List<Conversation> conversations) {
    final unique = <String, Conversation>{
      for (final conversation in conversations) conversation.id: conversation,
    }.values.toList();
    unique.sort((a, b) {
      final byUpdatedAt = b.updatedAt.compareTo(a.updatedAt);
      return byUpdatedAt != 0 ? byUpdatedAt : b.id.compareTo(a.id);
    });
    return unique;
  }
}
