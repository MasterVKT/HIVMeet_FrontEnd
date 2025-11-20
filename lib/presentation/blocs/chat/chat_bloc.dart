// Assumant le fichier chat_bloc.dart
// Enlever part 'chat_event.dart'; part 'chat_state.dart';
// Ajouter import 'chat_event.dart'; import 'chat_state.dart';

// Puis pour event.dart: part of 'chat_bloc.dart';
// State similaire.
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/data/repositories/messaging_repository.dart';
import 'dart:io';

part 'chat_event.dart';
part 'chat_state.dart';

@injectable
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final MessagingRepository _repository;

  ChatBloc(this._repository) : super(ChatInitial()) {
    on<LoadConversation>(_onLoadConversation);
    on<SendTextMessage>(_onSendTextMessage);
    on<SendMediaMessage>(_onSendMediaMessage);
    on<MarkAsRead>(_onMarkAsRead);
    on<DeleteMessage>(_onDeleteMessage);
    on<SetTypingStatus>(_onSetTypingStatus);
  }

  void _onLoadConversation(LoadConversation event, Emitter<ChatState> emit) {
    emit(ChatLoading());
    try {
      final stream = _repository.getMessages(event.conversationId);
      emit(ChatLoaded(messages: [], stream: stream, isTyping: false));
    } catch (e) {
      emit(ChatError(message: 'Erreur: $e'));
    }
  }

  void _onSendTextMessage(
      SendTextMessage event, Emitter<ChatState> emit) async {
    try {
      final msg = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        conversationId: (state is ChatLoaded) ? '' : '',
        senderId: '',
        content: event.content,
        type: MessageType.text,
        createdAt: DateTime.now(),
        status: MessageStatus.sending,
      );
      await _repository.sendMessage(msg);
    } catch (e) {
      emit(ChatError(message: 'Envoi échoué: $e'));
    }
  }

  void _onSendMediaMessage(
      SendMediaMessage event, Emitter<ChatState> emit) async {
    try {
      // Exemple: uploader puis envoyer un message media
      final url = await _repository.uploadMedia(event.mediaFile.path);
      final msg = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        conversationId: (state is ChatLoaded) ? '' : '',
        senderId: '',
        content: '',
        type: event.type,
        mediaUrl: url,
        createdAt: DateTime.now(),
        status: MessageStatus.sending,
      );
      await _repository.sendMessage(msg);
    } catch (e) {
      emit(ChatError(message: 'Envoi média échoué: $e'));
    }
  }

  void _onMarkAsRead(MarkAsRead event, Emitter<ChatState> emit) async {
    await _repository.markAsRead(event.conversationId, event.messageId);
  }

  void _onSetTypingStatus(SetTypingStatus event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      emit((state as ChatLoaded).copyWith(isTyping: event.isTyping));
    }
  }

  void _onDeleteMessage(DeleteMessage event, Emitter<ChatState> emit) async {
    try {
      // Suppression basique via Firestore
      // Non implémenté dans repository; à ajouter si besoin
    } catch (e) {
      emit(ChatError(message: 'Suppression échouée: $e'));
    }
  }

  // Pour médias/vidéo : Ajoutez events SendMedia, StartVideoCall (intégrez WebRTC)
}
