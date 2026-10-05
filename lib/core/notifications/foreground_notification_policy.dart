/// Decides whether a foreground *system* alert is redundant.
///
/// WebSocket events still refresh the in-app list and badges.  A native popup
/// is suppressed only for a new message in the conversation currently shown
/// to the user; being on a list, the Notifications page, or another route is
/// not enough to hide it.
class ForegroundNotificationPolicy {
  const ForegroundNotificationPolicy._();

  static bool shouldSuppress({
    required Map<String, dynamic> data,
    required String? activeConversationId,
  }) {
    if (data['type'] != 'new_message') return false;
    final conversationId = data['conversation_id'];
    return conversationId is String &&
        conversationId.isNotEmpty &&
        conversationId == activeConversationId;
  }
}
