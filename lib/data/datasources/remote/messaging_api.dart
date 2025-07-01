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
    int perPage = 20,
    String filter = "all", // "all|unread|archived"
  }) async {
    return await _apiClient.get('/conversations/', queryParameters: {
      'page': page,
      'per_page': perPage,
      'filter': filter,
    });
  }

  /// Messages d'une conversation
  /// GET /conversations/{conversation_id}/messages
  Future<Response<Map<String, dynamic>>> getConversationMessages({
    required String conversationId,
    int page = 1,
    int perPage = 50,
    String? beforeMessageId,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };

    if (beforeMessageId != null) {
      queryParams['before_message_id'] = beforeMessageId;
    }

    return await _apiClient.get(
      '/conversations/$conversationId/messages',
      queryParameters: queryParams,
    );
  }

  /// Envoi de message texte
  /// POST /conversations/{conversation_id}/messages
  Future<Response<Map<String, dynamic>>> sendTextMessage({
    required String conversationId,
    required String content,
    required String clientMessageId,
  }) async {
    final data = {
      'content': content,
      'message_type': 'text',
      'client_message_id': clientMessageId,
    };

    return await _apiClient.post(
      '/conversations/$conversationId/messages',
      data: data,
    );
  }

  /// Envoi de média (Premium)
  /// POST /conversations/{conversation_id}/messages
  Future<Response<Map<String, dynamic>>> sendMediaMessage({
    required String conversationId,
    required String mediaFilePath,
    required String messageType, // "image|video|audio"
    required String clientMessageId,
  }) async {
    final formData = FormData.fromMap({
      'media_file': await MultipartFile.fromFile(mediaFilePath),
      'message_type': messageType,
      'client_message_id': clientMessageId,
    });

    return await _apiClient.post(
      '/conversations/$conversationId/messages',
      data: formData,
    );
  }

  /// Marquer comme lu
  /// PUT /conversations/{conversation_id}/messages/{message_id}/read
  Future<Response<Map<String, dynamic>>> markMessageAsRead({
    required String conversationId,
    required String messageId,
  }) async {
    return await _apiClient.put(
      '/conversations/$conversationId/messages/$messageId/read',
    );
  }

  /// Initiation d'appel
  /// POST /calls/
  Future<Response<Map<String, dynamic>>> initiateCall({
    required String calleeId,
    required String callType, // "audio|video"
    required String offerSdp,
  }) async {
    final data = {
      'callee_id': calleeId,
      'call_type': callType,
      'offer_sdp': offerSdp,
    };

    return await _apiClient.post('/calls/', data: data);
  }

  /// Répondre à un appel
  /// PUT /calls/{call_id}/answer
  Future<Response<Map<String, dynamic>>> answerCall({
    required String callId,
    required String answerSdp,
  }) async {
    final data = {
      'answer_sdp': answerSdp,
    };

    return await _apiClient.put('/calls/$callId/answer', data: data);
  }

  /// Terminer un appel
  /// PUT /calls/{call_id}/end
  Future<Response<Map<String, dynamic>>> endCall({
    required String callId,
    required String endReason, // "normal|declined|failed|timeout"
  }) async {
    final data = {
      'end_reason': endReason,
    };

    return await _apiClient.put('/calls/$callId/end', data: data);
  }

  /// Indicateur de frappe
  /// POST /conversations/{conversation_id}/typing
  Future<Response<Map<String, dynamic>>> sendTypingIndicator({
    required String conversationId,
    required bool isTyping,
  }) async {
    final data = {
      'is_typing': isTyping,
    };

    return await _apiClient.post(
      '/conversations/$conversationId/typing',
      data: data,
    );
  }

  /// Statut de présence
  /// GET /conversations/{conversation_id}/presence
  Future<Response<Map<String, dynamic>>> getPresenceStatus({
    required String conversationId,
  }) async {
    return await _apiClient.get('/conversations/$conversationId/presence');
  }

  /// Récupérer une conversation spécifique
  /// GET /conversations/{conversation_id}
  Future<Response<Map<String, dynamic>>> getConversation(
      String conversationId) async {
    return await _apiClient.get('/conversations/$conversationId');
  }

  /// Récupérer les messages d'une conversation (alias pour getConversationMessages)
  /// GET /conversations/{conversation_id}/messages
  Future<Response<Map<String, dynamic>>> getMessages({
    required String conversationId,
    int page = 1,
    int limit = 50,
    String? beforeMessageId,
  }) async {
    return await getConversationMessages(
      conversationId: conversationId,
      page: page,
      perPage: limit,
      beforeMessageId: beforeMessageId,
    );
  }

  /// Envoyer un message (alias pour sendTextMessage)
  /// POST /conversations/{conversation_id}/messages
  Future<Response<Map<String, dynamic>>> sendMessage({
    required String conversationId,
    required String content,
    required String messageType,
    String? mediaUrl,
  }) async {
    final data = <String, dynamic>{
      'content': content,
      'message_type': messageType,
      'client_message_id': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    if (mediaUrl != null) {
      data['media_url'] = mediaUrl;
    }

    return await _apiClient.post(
      '/conversations/$conversationId/messages',
      data: data,
    );
  }

  /// Marquer des messages comme lus
  /// PUT /conversations/{conversation_id}/read
  Future<Response<Map<String, dynamic>>> markAsRead({
    required String conversationId,
    required List<String> messageIds,
  }) async {
    final data = {
      'message_ids': messageIds,
    };

    return await _apiClient.put(
      '/conversations/$conversationId/read',
      data: data,
    );
  }

  /// Supprimer un message
  /// DELETE /conversations/{conversation_id}/messages/{message_id}
  Future<Response<Map<String, dynamic>>> deleteMessage({
    required String conversationId,
    required String messageId,
  }) async {
    return await _apiClient.delete(
      '/conversations/$conversationId/messages/$messageId',
    );
  }

  /// Définir le statut de frappe
  /// POST /conversations/{conversation_id}/typing
  Future<Response<Map<String, dynamic>>> setTypingStatus({
    required String conversationId,
    required bool isTyping,
  }) async {
    return await sendTypingIndicator(
      conversationId: conversationId,
      isTyping: isTyping,
    );
  }
}
