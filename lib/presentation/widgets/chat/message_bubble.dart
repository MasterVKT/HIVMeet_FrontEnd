// lib/presentation/widgets/chat/message_bubble.dart

import 'package:flutter/material.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isOwnMessage;
  final VoidCallback? onDelete;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isOwnMessage,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isOwnMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: AppSpacing.xs),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment:
              isOwnMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isOwnMessage
                    ? AppColors.primaryPurple
                    : AppColors.platinum,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isOwnMessage ? 16 : 4),
                  bottomRight: Radius.circular(isOwnMessage ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.type == MessageType.text)
                    Text(
                      message.content,
                      style: TextStyle(
                        color: isOwnMessage ? Colors.white : AppColors.charcoal,
                      ),
                    )
                  else if (message.type == MessageType.image && message.mediaUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        message.mediaUrl!,
                        width: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('HH:mm').format(message.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.slate,
                  ),
                ),
                if (isOwnMessage) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    message.status == MessageStatus.read
                        ? Icons.done_all
                        : Icons.done,
                    size: 16,
                    color: message.status == MessageStatus.read
                        ? AppColors.primaryPurple
                        : AppColors.slate,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}