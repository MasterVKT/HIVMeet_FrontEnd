import 'package:injectable/injectable.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/data/datasources/remote/messaging_api.dart';

@injectable
class MessagingRepository {
  final MessagingApi _messagingApi;

  MessagingRepository(this._messagingApi);

  Stream<List<Conversation>> getConversations(String userId) async* {
    try {
      // Utiliser l'API backend au lieu de Firebase pour éviter les problèmes de données
      final response = await _messagingApi.getConversations();
      final payload = response.data!;
      final list = (payload['results'] ?? payload['data'] ?? []);
      final conversations =
          list.map((json) => Conversation.fromJson(json)).toList();

      // Émettre la liste des conversations
      yield conversations;
    } catch (e) {
      // En cas d'erreur, émettre une liste vide
      yield <Conversation>[];
    }
  }

  Stream<List<Message>> getMessages(String conversationId) async* {
    try {
      // Utiliser l'API backend au lieu de Firebase
      final response = await _messagingApi.getConversationMessages(
        conversationId: conversationId,
      );
      final payload = response.data!;
      final list = (payload['results'] ?? payload['data'] ?? []);
      final messages = list.map((json) => Message.fromJson(json)).toList();

      // Émettre la liste des messages
      yield messages;
    } catch (e) {
      // En cas d'erreur, émettre une liste vide
      yield <Message>[];
    }
  }

  Future<void> sendMessage(Message message) async {
    try {
      // Utiliser l'API backend pour envoyer le message
      await _messagingApi.sendTextMessage(
        conversationId: message.conversationId,
        content: message.content,
      );
    } catch (e) {
      // Gérer l'erreur d'envoi
      rethrow;
    }
  }

  Future<void> markAsRead(String conversationId, String messageId) async {
    try {
      // Utiliser l'API backend pour marquer comme lu
      await _messagingApi.markMessageAsRead(
        conversationId: conversationId,
        messageIds: [messageId],
      );
    } catch (e) {
      // Gérer l'erreur
      rethrow;
    }
  }

  // Pour médias (upload via Storage, puis envoi URL dans message)
  Future<String> uploadMedia(String path) async {
    // Implémentez avec Firebase Storage
    // Exemple: final ref = FirebaseStorage.instance.ref().child('media/$path');
    // await ref.putFile(File(path));
    // return ref.getDownloadURL();
    return 'url_mock'; // Remplacez par impl réelle
  }

  // Pour vidéo calls : Intégrez signaling via Firestore ou backend WebRTC
}
