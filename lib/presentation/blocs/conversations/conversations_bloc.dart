// lib/presentation/blocs/conversations/conversations_bloc.dart

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/data/repositories/messaging_repository.dart';

part 'conversations_event.dart';
part 'conversations_state.dart';

@injectable
class ConversationsBloc extends Bloc<ConversationsEvent, ConversationsState> {
  final MessagingRepository _repository;

  ConversationsBloc(this._repository) : super(ConversationsInitial()) {
    on<LoadConversations>(_onLoadConversations);
    on<RefreshConversations>(_onRefreshConversations);
  }

  void _onLoadConversations(
      LoadConversations event, Emitter<ConversationsState> emit) {
    emit(ConversationsLoading());
    try {
      // Pour l'instant, on utilise une liste vide en attendant l'implémentation complète
      // TODO: Récupérer l'userId depuis AuthenticationService ou AuthBloc
      final stream = _repository.getConversations('current_user_id');
      emit(ConversationsLoaded(
          conversations: [], stream: stream)); // Stream pour updates real-time
    } catch (e) {
      emit(ConversationsError(message: 'Erreur chargement conversations: $e'));
    }
  }

  void _onRefreshConversations(
      RefreshConversations event, Emitter<ConversationsState> emit) async {
    if (state is ConversationsLoaded) {
      add(LoadConversations());
    }
  }
}
