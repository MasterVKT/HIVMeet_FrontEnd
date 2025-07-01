// lib/presentation/pages/conversations/conversations_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:hivmeet/injection.dart';
import 'package:hivmeet/presentation/blocs/conversations/conversations_bloc.dart';
import 'package:hivmeet/presentation/blocs/conversations/conversations_event.dart';
import 'package:hivmeet/presentation/blocs/conversations/conversations_state.dart';
import 'package:hivmeet/presentation/widgets/cards/conversation_card.dart';
import 'package:hivmeet/presentation/widgets/loaders/hiv_loader.dart';
import 'package:go_router/go_router.dart';

class ConversationsPage extends StatelessWidget {
  const ConversationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ConversationsBloc>()..add(const LoadConversations()),
      child: Scaffold(
        backgroundColor: AppColors.primaryWhite,
        appBar: AppBar(
          title: const Text('Messages'),
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: BlocBuilder<ConversationsBloc, ConversationsState>(
          builder: (context, state) {
            if (state is ConversationsLoading) {
              return const Center(child: HIVLoader());
            }
            
            if (state is ConversationsLoaded) {
              if (state.conversations.isEmpty) {
                return _buildEmptyState(context);
              }
              
              return ListView.builder(
                itemCount: state.conversations.length,
                itemBuilder: (context, index) {
                  final convWithProfile = state.conversations[index];
                  final conversation = convWithProfile.conversation;
                  
                  return ConversationCard(
                    imageUrl: convWithProfile.otherUserPhotoUrl,
                    name: convWithProfile.otherUserName,
                    lastMessage: conversation.lastMessage?.content ?? '',
                    lastMessageTime: conversation.lastMessage?.createdAt,
                    isOnline: convWithProfile.isOtherUserOnline,
                    unreadCount: conversation.getUnreadCount('currentUserId'),
                    onTap: () => context.push('/chat/${conversation.id}'),
                    onDelete: () {
                      context.read<ConversationsBloc>().add(
                        DeleteConversation(conversationId: conversation.id),
                      );
                    },
                  );
                },
              );
            }
            
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: AppColors.slate,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Pas encore de conversations',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Vos conversations apparaîtront ici',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.slate,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}