import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/network/api_client.dart';

@injectable
class MessagingApi {
  final ApiClient _apiClient;

  const MessagingApi(this._apiClient);

  /// Liste des conversations
  /// GET /conversations/
  Future<Response<Map<String, dynamic>>> getConversations({
    int page = 1,
    int pageSize = 20,
    String status = "all", // "all|unread|archived"
  }) async {
    return await _apiClient.get('/api/v1/conversations/', queryParameters: {
      'page': page,
      'page_size': pageSize,
      'status': status,
    });
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
      'page': page,
      'page_size': pageSize,
    };

    if (beforeMessageId != null) {
      queryParams['before_message_id'] = beforeMessageId;
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
  }) async {
    final data = {
      'content': content,
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
  }) async {
    final formData = FormData.fromMap({
      'media_file': await MultipartFile.fromFile(mediaFilePath),
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
    required List<String> messageIds,
  }) async {
    return await _apiClient.put(
      '/conversations/$conversationId/messages/mark-as-read/',
      data: {
        'message_ids': messageIds,
      },
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

  /// Récupérer une conversation spécifique
  /// GET /conversations/{conversation_id}/
  Future<Response<Map<String, dynamic>>> getConversation(
      String conversationId) async {
    return await _apiClient.get('/conversations/$conversationId/');
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

  // Méthodes supprimées car endpoints inexistants dans la documentation backend :
  // - sendTypingIndicator() - Endpoint inexistant, utiliser WebSocket
  // - getPresenceStatus() - Endpoint inexistant, utiliser WebSocket
  // - getMessages() - Duplication de getConversationMessages()
  // - sendMessage() - Duplication de sendTextMessage()
  // - markAsRead() - Duplication de markMessageAsRead()
  // - setTypingStatus() - Duplication de sendTypingIndicator()
}
