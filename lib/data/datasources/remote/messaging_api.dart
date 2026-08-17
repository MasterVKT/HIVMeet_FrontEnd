import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/network/api_client.dart';
import 'package:hivmeet/domain/entities/message.dart';

@injectable
class MessagingApi {
  final ApiClient _apiClient;

  const MessagingApi(this._apiClient);

  /// Liste des conversations
  /// GET /conversations/
  Future<Response<Map<String, dynamic>>> getConversations({
    int page = 1,
    int pageSize = 20,
    ConversationFilter filter = ConversationFilter.all,
  }) async {
    return await _apiClient.get('/conversations/', queryParameters: {
      'page': page,
      'page_size': pageSize,
      'status': filter.apiValue,
    });
  }

  /// Compteur global exact de non-lus (toutes conversations, pas seulement
  /// la première page).
  /// GET /conversations/unread-count/
  Future<Response<Map<String, dynamic>>> getUnreadCount() async {
    return await _apiClient.get('/conversations/unread-count/');
  }

  /// Messages d'une conversation
  /// GET /conversations/{conversation_id}/messages/
  Future<Response<Map<String, dynamic>>> getConversationMessages({
    required String conversationId,
    int page = 1,
    int pageSize = 50,
    String? beforeMessageId,
  }) async {
    final queryParams = <String, dynamic>{
      'page_size': pageSize,
    };

    if (beforeMessageId != null) {
      // Pagination cursor-based: le backend (`MessageService.
      // get_conversation_messages`) pagine exclusivement via
      // `before_message_id` pour cette ressource et ignore `page`. On
      // n'envoie donc pas `page` ici pour éviter un paramètre trompeur.
      queryParams['before_message_id'] = beforeMessageId;
    } else {
      queryParams['page'] = page;
    }

    return await _apiClient.get(
      '/conversations/$conversationId/messages/',
      queryParameters: queryParams,
    );
  }

  /// Envoi de message texte
  /// POST /conversations/{conversation_id}/messages/
  Future<Response<Map<String, dynamic>>> sendTextMessage({
    required String conversationId,
    required String content,
    required String clientMessageId,
  }) async {
    final data = {
      'client_message_id': clientMessageId,
      'content': content,
      'type': 'text',
    };

    return await _apiClient.post(
      '/conversations/$conversationId/messages/',
      data: data,
    );
  }

  /// Envoi de média (Premium)
  /// POST /conversations/{conversation_id}/messages/media/
  Future<Response<Map<String, dynamic>>> sendMediaMessage({
    required String conversationId,
    required String mediaFilePath,
    required String mediaType,
    required String clientMessageId,
    String? text,
  }) async {
    final formData = FormData.fromMap({
      'media_file': await MultipartFile.fromFile(mediaFilePath),
      'media_type': mediaType,
      'client_message_id': clientMessageId,
      if (text != null) 'text': text,
    });

    return await _apiClient.post(
      '/conversations/$conversationId/messages/media/',
      data: formData,
    );
  }

  /// Marquer comme lu
  /// PUT /conversations/{conversation_id}/messages/mark-as-read/
  Future<Response<Map<String, dynamic>>> markMessageAsRead({
    required String conversationId,
    required String lastReadMessageId,
  }) async {
    return await _apiClient.put(
      '/conversations/$conversationId/messages/mark-as-read/',
      data: {
        'last_read_message_id': lastReadMessageId,
      },
    );
  }

  /// Marquer un message unique comme lu
  /// PUT /conversations/{conversation_id}/messages/{message_id}/read/
  Future<Response<Map<String, dynamic>>> markSingleMessageAsRead({
    required String conversationId,
    required String messageId,
  }) async {
    return await _apiClient.put(
      '/conversations/$conversationId/messages/$messageId/read/',
    );
  }

  /// Supprimer un message
  /// DELETE /conversations/{conversation_id}/messages/{message_id}/
  Future<Response<Map<String, dynamic>>> deleteMessage({
    required String conversationId,
    required String messageId,
  }) async {
    return await _apiClient.delete(
      '/conversations/$conversationId/messages/$messageId/',
    );
  }

  /// Masquer une conversation pour l'utilisateur courant.
  /// DELETE /conversations/{conversation_id}/
  Future<Response<void>> deleteConversation(String conversationId) async {
    return _apiClient.delete<void>('/conversations/$conversationId/');
  }

  /// Initiation d'appel
  /// POST /calls/initiate
  Future<Response<Map<String, dynamic>>> initiateCall({
    required String calleeId,
    required String callType, // "audio|video"
  }) async {
    final data = {
      'target_user_id': calleeId,
      'call_type': callType,
    };

    return await _apiClient.post('/calls/initiate', data: data);
  }

  /// Répondre à un appel
  /// POST /calls/{call_id}/answer
  Future<Response<Map<String, dynamic>>> answerCall({
    required String callId,
  }) async {
    final data = {
      'answer': true,
    };

    return await _apiClient.post('/calls/$callId/answer', data: data);
  }

  /// Terminer un appel
  /// POST /calls/{call_id}/terminate
  Future<Response<Map<String, dynamic>>> endCall({
    required String callId,
  }) async {
    return await _apiClient.post('/calls/$callId/terminate');
  }

  /// Ajouter un candidat ICE
  /// POST /calls/{call_id}/ice-candidate
  Future<Response<Map<String, dynamic>>> sendIceCandidate({
    required String callId,
    required Map<String, dynamic> candidate,
  }) async {
    return await _apiClient.post(
      '/calls/$callId/ice-candidate',
      data: candidate,
    );
  }

  /// Initier un appel premium (exposé sous conversations/)
  /// POST /conversations/calls/initiate-premium/
  Future<Response<Map<String, dynamic>>> initiatePremiumCall({
    required String conversationId,
    required String callType, // "audio|video"
  }) async {
    return await _apiClient.post(
      '/conversations/calls/initiate-premium/',
      data: {
        'conversation_id': conversationId,
        'call_type': callType,
      },
    );
  }

  /// Typing indicator
  /// POST /conversations/{conversation_id}/typing/
  Future<Response<Map<String, dynamic>>> setTypingStatus({
    required String conversationId,
    required bool isTyping,
  }) async {
    return await _apiClient.post(
      '/conversations/$conversationId/typing/',
      data: {
        'is_typing': isTyping,
      },
    );
  }

  /// Presence indicator
  /// GET /conversations/{conversation_id}/presence/
  Future<Response<Map<String, dynamic>>> getPresence({
    required String conversationId,
  }) async {
    return await _apiClient.get('/conversations/$conversationId/presence/');
  }
}
