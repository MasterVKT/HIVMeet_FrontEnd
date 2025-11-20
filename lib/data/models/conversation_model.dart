import 'package:json_annotation/json_annotation.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/data/models/message_model.dart';

part 'conversation_model.g.dart';

@JsonSerializable()
class ConversationModel {
  final String id;
  final List<String> participants;
  @JsonKey(name: 'last_message')
  final MessageModel? lastMessage;
  @JsonKey(name: 'unread_counts')
  final Map<String, int> unreadCounts;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'last_activity_at')
  final DateTime? lastActivityAt;

  const ConversationModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    required this.unreadCounts,
    required this.createdAt,
    this.lastActivityAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) =>
      _$ConversationModelFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationModelToJson(this);

  Conversation toEntity() {
    return Conversation(
      id: id,
      participantIds: participants,
      lastMessage: lastMessage?.toEntity(),
      unreadCount: unreadCounts.values.fold(0, (a, b) => a + b),
      updatedAt: lastActivityAt ?? createdAt,
    );
  }

  factory ConversationModel.fromEntity(Conversation conversation) {
    return ConversationModel(
      id: conversation.id,
      participants: conversation.participantIds,
      lastMessage: conversation.lastMessage != null
          ? MessageModel.fromEntity(conversation.lastMessage!)
          : null,
      unreadCounts: {'current_user': conversation.unreadCount},
      createdAt: conversation.updatedAt,
      lastActivityAt: conversation.updatedAt,
    );
  }
}
