// lib/presentation/widgets/cards/conversation_card.dart

import 'package:flutter/material.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:intl/intl.dart';

class ConversationCard extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final bool isOnline;
  final int unreadCount;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const ConversationCard({
    Key? key,
    required this.imageUrl,
    required this.name,
    required this.lastMessage,
    this.lastMessageTime,
    this.isOnline = false,
    this.unreadCount = 0,
    required this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(name),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: AppSpacing.lg),
        color: AppColors.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Supprimer la conversation'),
            content: const Text('Cette action est irréversible.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) => onDelete?.call(),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(imageUrl),
                    radius: 28,
                  ),
                  if (isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (lastMessageTime != null)
                          Text(
                            _formatTime(lastMessageTime!),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: unreadCount > 0 ? AppColors.primaryPurple : AppColors.slate,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lastMessage,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.slate,
                              fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (unreadCount > 0)
                          Container(
                            margin: EdgeInsets.only(left: AppSpacing.sm),
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryPurple,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inDays > 7) {
      return DateFormat('dd/MM/yy').format(time);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Maintenant';
    }
  }
}