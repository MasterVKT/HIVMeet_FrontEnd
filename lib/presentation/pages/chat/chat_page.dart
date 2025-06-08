// lib/presentation/pages/chat/chat_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:hivmeet/injection.dart';
import 'package:hivmeet/presentation/blocs/chat/chat_bloc.dart';
import 'package:hivmeet/presentation/blocs/chat/chat_event.dart';
import 'package:hivmeet/presentation/blocs/chat/chat_state.dart';
import 'package:hivmeet/presentation/widgets/chat/message_bubble.dart';
import 'package:hivmeet/presentation/widgets/chat/message_input.dart';
import 'package:hivmeet/presentation/widgets/loaders/hiv_loader.dart';
import 'package:go_router/go_router.dart';

class ChatPage extends StatefulWidget {
  final String conversationId;

  const ChatPage({
    Key? key,
    required this.conversationId,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late ScrollController _scrollController;
  late TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ChatBloc>()
        ..add(LoadConversation(conversationId: widget.conversationId)),
      child: Scaffold(
        backgroundColor: AppColors.primaryWhite,
        appBar: _buildAppBar(),
        body: BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            if (state is ChatLoading) {
              return const Center(child: HIVLoader());
            }
            
            if (state is ChatError) {
              return Center(
                child: Text(state.message),
              );
            }
            
            if (state is ChatLoaded) {
              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: EdgeInsets.all(AppSpacing.md),
                      itemCount: state.messages.length + (state.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == state.messages.length) {
                          if (!state.isLoadingMore) {
                            context.read<ChatBloc>().add(LoadMoreMessages());
                          }
                          return const Center(child: HIVLoader());
                        }
                        
                        final message = state.messages[state.messages.length - 1 - index];
                        final isOwnMessage = message.senderId == 'currentUserId'; // TODO
                        
                        return MessageBubble(
                          message: message,
                          isOwnMessage: isOwnMessage,
                          onDelete: () {
                            context.read<ChatBloc>().add(
                              DeleteMessage(messageId: message.id),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  MessageInput(
                    controller: _messageController,
                    onSend: (content) {
                      context.read<ChatBloc>().add(
                        SendTextMessage(content: content),
                      );
                      _messageController.clear();
                    },
                    onTypingChanged: (isTyping) {
                      context.read<ChatBloc>().add(
                        SetTypingStatus(isTyping: isTyping),
                      );
                    },
                  ),
                ],
              );
            }
            
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      title: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          if (state is ChatLoaded) {
            final profile = state.otherUserProfile;
            return Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(profile.photos.main),
                  radius: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.displayName,
                        style: const TextStyle(fontSize: 16),
                      ),
                      if (profile.isOnline)
                        const Text(
                          'En ligne',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.success,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.phone),
          onPressed: () {
            // TODO: Initier appel audio
          },
        ),
        IconButton(
          icon: const Icon(Icons.videocam),
          onPressed: () {
            // TODO: Initier appel vidéo
          },
        ),
      ],
    );
  }
}