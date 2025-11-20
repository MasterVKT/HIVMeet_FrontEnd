// lib/presentation/widgets/matches/match_card.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Widget pour afficher une carte de match
///
/// Affiche:
/// - Photo du profil
/// - Nom et âge
/// - Dernier message (preview)
/// - Badge "Nouveau" si match récent
/// - Compteur de messages non lus
/// - Timestamp du dernier message
class MatchCard extends StatelessWidget {
  final Match match;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const MatchCard({
    super.key,
    required this.match,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = match.profile;
    final hasUnread = match.hasUnreadMessages;

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
            // Photo de profil avec badge "New"
            _buildProfilePhoto(context),
            const SizedBox(width: 12),

            // Informations du match
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom + badge new
                  _buildHeader(context),
                  const SizedBox(height: 4),

                  // Dernier message ou statut
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
    final photoUrl = match.profile.photos.main;

    return Stack(
      children: [
        // Photo de profil
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: match.isNew
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: ClipOval(
            child: photoUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: photoUrl,
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
        ),

        // Badge "NEW" si nouveau match
        if (match.isNew)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
              child: Text(
                'NEW',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = match.profile.displayName;
    final age = _calculateAge(match.profile.birthDate);

    return Row(
      children: [
        Expanded(
          child: Text(
            '$displayName, $age',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: match.hasUnreadMessages
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
    final lastMessage = match.lastMessage;

    if (lastMessage == null) {
      return Text(
        'Dites bonjour! 👋',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontStyle: FontStyle.italic,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    // Détermine si le message a été envoyé par l'utilisateur actuel
    final isOwnMessage = lastMessage.senderId == match.profile.userId;

    return Text(
      isOwnMessage ? 'Vous: ${lastMessage.content}' : lastMessage.content,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: match.hasUnreadMessages
            ? theme.colorScheme.onSurface
            : theme.colorScheme.onSurface.withOpacity(0.6),
        fontWeight: match.hasUnreadMessages
            ? FontWeight.w500
            : FontWeight.normal,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildTrailing(BuildContext context) {
    final theme = Theme.of(context);
    final lastMessageTime = match.lastMessage?.createdAt ?? match.matchedAt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Timestamp
        Text(
          _formatTimestamp(lastMessageTime),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
            fontSize: 11,
          ),
        ),

        // Badge unread count
        if (match.hasUnreadMessages) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${match.unreadCount}',
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

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
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
