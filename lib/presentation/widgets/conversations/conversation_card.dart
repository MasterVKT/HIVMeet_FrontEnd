// lib/presentation/widgets/conversations/conversation_card.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Widget pour afficher une carte de conversation
///
/// Affiche:
/// - Photo du participant
/// - Nom du participant
/// - Dernier message (preview)
/// - Compteur de messages non lus
/// - Timestamp du dernier message
///
/// Note: Pour l'instant, le nom et la photo du participant doivent être fournis
/// séparément car Conversation ne contient que les IDs des participants.
/// TODO: Enrichir Conversation avec les profils des participants
class ConversationCard extends StatelessWidget {
  final Conversation conversation;
  final String participantName;
  final String? participantPhotoUrl;
  final String currentUserId;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const ConversationCard({
    super.key,
    required this.conversation,
    required this.participantName,
    this.participantPhotoUrl,
    required this.currentUserId,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasUnread = conversation.unreadCount > 0;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: hasUnread
              ? theme.colorScheme.primaryContainer.withOpacity(0.05)
              : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.dividerColor.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            // Photo de profil
            _buildProfilePhoto(context),
            const SizedBox(width: 12),

            // Informations de la conversation
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom du participant
                  _buildHeader(context),
                  const SizedBox(height: 4),

                  // Dernier message
                  _buildMessagePreview(context),
                ],
              ),
            ),

            // Timestamp + badge unread count
            _buildTrailing(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePhoto(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: conversation.unreadCount > 0
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: ClipOval(
        child: participantPhotoUrl != null && participantPhotoUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: participantPhotoUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: Icon(
                    Icons.person,
                    size: 32,
                    color: Colors.grey[600],
                  ),
                ),
              )
            : Container(
                color: Colors.grey[300],
                child: Icon(
                  Icons.person,
                  size: 32,
                  color: Colors.grey[600],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            participantName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: conversation.unreadCount > 0
                  ? FontWeight.bold
                  : FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMessagePreview(BuildContext context) {
    final theme = Theme.of(context);
    final lastMessage = conversation.lastMessage;

    if (lastMessage == null) {
      return Text(
        'Aucun message',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.4),
          fontStyle: FontStyle.italic,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    // Détermine si le message a été envoyé par l'utilisateur actuel
    final isOwnMessage = lastMessage.senderId == currentUserId;

    // Préfixe pour les messages média
    String messageContent = lastMessage.content;
    if (lastMessage.type == MessageType.image) {
      messageContent = '📷 Photo';
    } else if (lastMessage.type == MessageType.video) {
      messageContent = '🎥 Vidéo';
    } else if (lastMessage.type == MessageType.voice) {
      messageContent = '🎤 Message vocal';
    }

    return Text(
      isOwnMessage ? 'Vous: $messageContent' : messageContent,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: conversation.unreadCount > 0
            ? theme.colorScheme.onSurface
            : theme.colorScheme.onSurface.withOpacity(0.6),
        fontWeight: conversation.unreadCount > 0
            ? FontWeight.w500
            : FontWeight.normal,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildTrailing(BuildContext context) {
    final theme = Theme.of(context);
    final timestamp = conversation.lastMessage?.createdAt ?? conversation.updatedAt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Timestamp
        Text(
          _formatTimestamp(timestamp),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
            fontSize: 11,
          ),
        ),

        // Badge unread count
        if (conversation.unreadCount > 0) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${conversation.unreadCount}',
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      // Aujourd'hui: afficher l'heure
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      // Cette semaine: afficher le jour
      final weekdays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      return weekdays[dateTime.weekday - 1];
    } else {
      // Plus ancien: utiliser timeago
      timeago.setLocaleMessages('fr', timeago.FrMessages());
      return timeago.format(dateTime, locale: 'fr');
    }
  }
}
