// lib/presentation/blocs/conversations/conversations_bloc.dart

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/domain/repositories/message_repository.dart';
import 'package:hivmeet/domain/repositories/profile_repository.dart';
import 'conversations_event.dart';
import 'conversations_state.dart';

@injectable
class ConversationsBloc extends Bloc<ConversationsEvent, ConversationsState> {
  final MessageRepository _messageRepository;
  final ProfileRepository _profileRepository;
  
  StreamSubscription? _conversationsSubscription;
  
  ConversationsBloc({
    required MessageRepository messageRepository,
    required ProfileRepository profileRepository,
  })  : _messageRepository = messageRepository,
        _profileRepository = profileRepository,
        super(ConversationsInitial()) {
    on<LoadConversations>(_onLoadConversations);
    on<LoadMoreConversations>(_onLoadMoreConversations);
    on<DeleteConversation>(_onDeleteConversation);
    on<ArchiveConversation>(_onArchiveConversation);
  }

  Future<void> _onLoadConversations(
    LoadConversations event,
    Emitter<ConversationsState> emit,
  ) async {
    emit(ConversationsLoading());
    
    _conversationsSubscription?.cancel();
    _conversationsSubscription = _messageRepository.watchConversations().listen(
      (conversations) async {
        final conversationsWithProfiles = <ConversationWithProfile>[];
        
        for (final conversation in conversations) {
          final otherUserId = conversation.participants.firstWhere(
            (id) => id != 'currentUserId', // TODO: Get current user ID
          );
          
          final profileResult = await _profileRepository.getProfile(otherUserId);
          profileResult.fold(
            (failure) => null,
            (profile) {
              conversationsWithProfiles.add(
                ConversationWithProfile(
                  conversation: conversation,
                  otherUserName: profile.displayName,
                  otherUserPhotoUrl: profile.photos.main,
                  isOtherUserOnline: profile.isOnline,
                ),
              );
            },
          );
        }
        
        final totalUnread = conversationsWithProfiles.fold<int>(
          0,
          (sum, conv) => sum + conv.conversation.getUnreadCount('currentUserId'),
        );
        
        emit(ConversationsLoaded(
          conversations: conversationsWithProfiles,
          hasMore: false,
          totalUnreadCount: totalUnread,
        ));
      },
      onError: (error) {
        emit(ConversationsError(message: error.toString()));
      },
    );
  }

  Future<void> _onLoadMoreConversations(
    LoadMoreConversations event,
    Emitter<ConversationsState> emit,
  ) async {
    // Implemented with pagination if needed
  }

  Future<void> _onDeleteConversation(
    DeleteConversation event,
    Emitter<ConversationsState> emit,
  ) async {
    // TODO: Implement delete
  }

  Future<void> _onArchiveConversation(
    ArchiveConversation event,
    Emitter<ConversationsState> emit,
  ) async {
    // TODO: Implement archive
  }

  @override
  Future<void> close() {
    _conversationsSubscription?.cancel();
    return super.close();
  }
}