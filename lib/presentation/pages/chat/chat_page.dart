// lib/presentation/pages/chat/chat_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:hivmeet/injection.dart';
import 'package:hivmeet/presentation/blocs/chat/chat_bloc.dart';
// Events/States sont des parts de ChatBloc, on n'importe que le bloc
import 'package:hivmeet/presentation/widgets/chat/message_bubble.dart';
import 'package:hivmeet/presentation/widgets/chat/message_input.dart';
import 'package:hivmeet/presentation/widgets/common/hiv_toast.dart';
import 'package:hivmeet/presentation/widgets/loaders/hiv_loader.dart';

class ChatPage extends StatefulWidget {
  final String conversationId;
  final DiscoveryProfile? matchedProfile;

  const ChatPage({
    super.key,
    required this.conversationId,
    this.matchedProfile,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late ScrollController _scrollController;
  late AnimationController _appearanceController;
  late AnimationController _typingController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _typingAnimation;

  bool _isKeyboardVisible = false;
  bool _isRecording = false;
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    _appearanceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _typingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _appearanceController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _appearanceController,
      curve: Curves.easeOutCubic,
    ));

    _typingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _typingController,
      curve: Curves.easeInOut,
    ));

    _typingController.repeat(reverse: true);
    _appearanceController.forward();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _appearanceController.dispose();
    _typingController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    final wasKeyboardVisible = _isKeyboardVisible;

    setState(() {
      _isKeyboardVisible = bottomInset > 0;
    });

    // Scroll to bottom when keyboard appears
    if (!wasKeyboardVisible && _isKeyboardVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void _onScroll() {
    final showScrollToBottom =
        _scrollController.hasClients && _scrollController.offset > 200;

    if (showScrollToBottom != _showScrollToBottom) {
      setState(() {
        _showScrollToBottom = showScrollToBottom;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ChatBloc>()
        ..add(LoadConversation(conversationId: widget.conversationId)),
      child: Scaffold(
        backgroundColor: AppColors.primaryWhite,
        appBar: _buildAppBar(),
        body: AnimatedBuilder(
          animation: _appearanceController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: child,
              ),
            );
          },
          child: Column(
            children: [
              // Messages
              Expanded(
                child: BlocConsumer<ChatBloc, ChatState>(
                  listener: (context, state) {
                    if (state is ChatLoaded) {
                      _scrollToBottom();
                    } else if (state is ChatError) {
                      HIVToast.showError(
                        context: context,
                        message: state.message,
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state is ChatLoading) {
                      return const Center(child: HIVLoader());
                    }

                    if (state is ChatLoaded) {
                      return Stack(
                        children: [
                          // Messages list
                          _buildMessagesList(state.messages, state.isTyping),

                          // Scroll to bottom button
                          if (_showScrollToBottom) _buildScrollToBottomButton(),
                        ],
                      );
                    }

                    if (state is ChatLoaded && state.messages.isEmpty) {
                      return _buildEmptyState();
                    }

                    return const Center(
                      child: Text('Une erreur est survenue'),
                    );
                  },
                ),
              ),

              // Input area
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.1),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: AppColors.charcoal),
        onPressed: () => context.pop(),
      ),
      title: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundImage: widget.matchedProfile?.mainPhotoUrl != null
                ? NetworkImage(widget.matchedProfile!.mainPhotoUrl)
                : null,
            backgroundColor: AppColors.slate.withOpacity(0.2),
            child: widget.matchedProfile?.mainPhotoUrl == null
                ? Icon(Icons.person, color: AppColors.slate)
                : null,
          ),
          const SizedBox(width: 12),

          // Name and status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.matchedProfile?.displayName ?? 'Utilisateur',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.charcoal,
                      ),
                ),
                BlocBuilder<ChatBloc, ChatState>(
                  builder: (context, state) {
                    if (state is ChatLoaded && state.isTyping) {
                      return AnimatedBuilder(
                        animation: _typingAnimation,
                        builder: (context, child) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                LocalizationService.translate('chat.typing'),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.primaryPurple,
                                      fontStyle: FontStyle.italic,
                                    ),
                              ),
                              SizedBox(
                                width: 20,
                                child: AnimatedBuilder(
                                  animation: _typingAnimation,
                                  builder: (context, child) {
                                    return Text(
                                      '...',
                                      style: TextStyle(
                                        color:
                                            AppColors.primaryPurple.withOpacity(
                                          0.5 + (_typingAnimation.value * 0.5),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    }

                    return Text(
                      widget.matchedProfile?.isOnline == true
                          ? LocalizationService.translate('chat.online')
                          : LocalizationService.translate('chat.last_seen',
                              params: {
                                  'time': _formatLastSeen(
                                      widget.matchedProfile?.lastActive),
                                }),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: widget.matchedProfile?.isOnline == true
                                ? AppColors.success
                                : AppColors.slate,
                          ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Audio call
        IconButton(
          icon: Icon(Icons.call, color: AppColors.primaryPurple),
          onPressed: () => _initiateCall(CallType.audio),
          tooltip: LocalizationService.translate('chat.audio_call'),
        ),

        // Video call
        IconButton(
          icon: Icon(Icons.videocam, color: AppColors.primaryPurple),
          onPressed: () => _initiateCall(CallType.video),
          tooltip: LocalizationService.translate('chat.video_call'),
        ),

        // More options
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: AppColors.charcoal),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person, color: AppColors.slate),
                  const SizedBox(width: 8),
                  Text(LocalizationService.translate('chat.view_profile')),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'block',
              child: Row(
                children: [
                  Icon(Icons.block, color: AppColors.error),
                  const SizedBox(width: 8),
                  Text(LocalizationService.translate('chat.block_user')),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  Icon(Icons.report, color: AppColors.error),
                  const SizedBox(width: 8),
                  Text(LocalizationService.translate('chat.report_user')),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMessagesList(List<Message> messages, bool isTyping) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: messages.length + (isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length && isTyping) {
          return _buildTypingIndicator();
        }

        final message = messages[index];
        final isMe =
            message.senderId == 'current_user_id'; // TODO: Get from auth
        final previousMessage = index > 0 ? messages[index - 1] : null;
        final nextMessage =
            index < messages.length - 1 ? messages[index + 1] : null;

        final showAvatar = _shouldShowAvatar(message, nextMessage, isMe);
        final showTimestamp = _shouldShowTimestamp(message, previousMessage);

        return Column(
          children: [
            if (showTimestamp) _buildTimestampDivider(message.createdAt),
            MessageBubble(
              message: message,
              isOwnMessage: isMe,
              onDelete: () => _deleteMessage(message),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundImage: widget.matchedProfile?.mainPhotoUrl != null
                ? NetworkImage(widget.matchedProfile!.mainPhotoUrl)
                : null,
            backgroundColor: AppColors.slate.withOpacity(0.2),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.slate.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: AnimatedBuilder(
              animation: _typingAnimation,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    final delay = index * 0.3;
                    final animationValue =
                        (_typingAnimation.value + delay) % 1.0;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      child: Transform.translate(
                        offset: Offset(
                            0, -4 * (1 - (animationValue * 2 - 1).abs())),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.slate.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimestampDivider(DateTime timestamp) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: AppColors.slate.withOpacity(0.3))),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.slate.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.slate,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(child: Divider(color: AppColors.slate.withOpacity(0.3))),
        ],
      ),
    );
  }

  Widget _buildScrollToBottomButton() {
    return Positioned(
      bottom: 80,
      right: 16,
      child: FloatingActionButton.small(
        onPressed: _scrollToBottom,
        backgroundColor: AppColors.primaryPurple,
        child: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite,
                size: 60,
                color: AppColors.primaryPurple,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              LocalizationService.translate('chat.its_a_match'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryPurple,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              LocalizationService.translate('chat.start_conversation', params: {
                'name': widget.matchedProfile?.displayName ?? 'cette personne',
              }),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.slate,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _QuickMessageButton(
                  text: LocalizationService.translate('chat.quick_hello'),
                  onPressed: () => _sendQuickMessage(
                    LocalizationService.translate('chat.quick_hello_message'),
                  ),
                ),
                _QuickMessageButton(
                  text: LocalizationService.translate('chat.quick_compliment'),
                  onPressed: () => _sendQuickMessage(
                    LocalizationService.translate(
                        'chat.quick_compliment_message'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        return MessageInput(
          onSendMessage: (content, type) {
            if (type == MessageType.text) {
              context.read<ChatBloc>().add(SendTextMessage(content: content));
            } else {
              // TODO: Handle media messages
            }
          },
          onSendMediaMessage: (file, type) {
            context.read<ChatBloc>().add(SendMediaMessage(
                  mediaFile: file,
                  type: type,
                ));
          },
          onStartTyping: () {
            context.read<ChatBloc>().add(const SetTypingStatus(isTyping: true));
          },
          onStopTyping: () {
            context
                .read<ChatBloc>()
                .add(const SetTypingStatus(isTyping: false));
          },
          onRecordingStateChanged: (isRecording) {
            setState(() {
              _isRecording = isRecording;
            });
          },
        );
      },
    );
  }

  bool _shouldShowAvatar(Message message, Message? nextMessage, bool isMe) {
    if (isMe) return false;
    if (nextMessage == null) return true;
    if (nextMessage.senderId != message.senderId) return true;

    final timeDiff =
        nextMessage.createdAt.difference(message.createdAt).inMinutes;
    return timeDiff > 5;
  }

  bool _shouldShowTimestamp(Message message, Message? previousMessage) {
    if (previousMessage == null) return true;

    final timeDiff =
        message.createdAt.difference(previousMessage.createdAt).inHours;
    return timeDiff >= 1;
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays == 0) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return LocalizationService.translate('common.yesterday');
    } else if (diff.inDays < 7) {
      return LocalizationService.translate('common.days_ago',
          params: {'count': diff.inDays.toString()});
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  String _formatLastSeen(DateTime? lastActive) {
    if (lastActive == null) return '';

    final diff = DateTime.now().difference(lastActive);

    if (diff.inMinutes < 1) {
      return LocalizationService.translate('common.just_now');
    } else if (diff.inHours < 1) {
      return LocalizationService.translate('common.minutes_ago',
          params: {'count': diff.inMinutes.toString()});
    } else if (diff.inDays < 1) {
      return LocalizationService.translate('common.hours_ago',
          params: {'count': diff.inHours.toString()});
    } else {
      return LocalizationService.translate('common.days_ago',
          params: {'count': diff.inDays.toString()});
    }
  }

  void _handleMessageTap(Message message) {
    if (message.type == MessageType.image ||
        message.type == MessageType.video) {
      // Ouvrir la galerie/viewer
      _openMediaViewer(message);
    }
  }

  void _handleMessageLongPress(Message message) {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      builder: (context) => _MessageOptionsSheet(
        message: message,
        onCopy: () => _copyMessage(message),
        onDelete: () => _deleteMessage(message),
        onReport: () => _reportMessage(message),
      ),
    );
  }

  void _initiateCall(CallType type) {
    // TODO: Implémenter les appels WebRTC
    HIVToast.showInfo(
      context: context,
      message: LocalizationService.translate('chat.call_feature_coming_soon'),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'profile':
        // Naviguer vers le profil détaillé
        context.push('/profile/${widget.matchedProfile?.id}');
        break;
      case 'block':
        _showBlockDialog();
        break;
      case 'report':
        _showReportDialog();
        break;
    }
  }

  void _sendQuickMessage(String message) {
    context.read<ChatBloc>().add(SendTextMessage(content: message));
  }

  void _openMediaViewer(Message message) {
    // TODO: Implémenter le viewer de médias
  }

  void _copyMessage(Message message) {
    Clipboard.setData(ClipboardData(text: message.content));
    HIVToast.showSuccess(
      context: context,
      message: LocalizationService.translate('chat.message_copied'),
    );
  }

  void _deleteMessage(Message message) {
    context.read<ChatBloc>().add(DeleteMessage(messageId: message.id));
  }

  void _reportMessage(Message message) {
    // TODO: Implémenter le système de signalement
  }

  void _showBlockDialog() {
    // TODO: Implémenter la boîte de dialogue de blocage
  }

  void _showReportDialog() {
    // TODO: Implémenter la boîte de dialogue de signalement
  }
}

class _QuickMessageButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _QuickMessageButton({
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryPurple.withValues(alpha: 0.1),
        foregroundColor: AppColors.primaryPurple,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(text),
    );
  }
}

class _MessageOptionsSheet extends StatelessWidget {
  final Message message;
  final VoidCallback onCopy;
  final VoidCallback onDelete;
  final VoidCallback onReport;

  const _MessageOptionsSheet({
    required this.message,
    required this.onCopy,
    required this.onDelete,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.type == MessageType.text)
            ListTile(
              leading: Icon(Icons.copy, color: AppColors.charcoal),
              title: Text(LocalizationService.translate('chat.copy_message')),
              onTap: () {
                Navigator.pop(context);
                onCopy();
              },
            ),
          ListTile(
            leading: Icon(Icons.delete, color: AppColors.error),
            title: Text(LocalizationService.translate('chat.delete_message')),
            onTap: () {
              Navigator.pop(context);
              onDelete();
            },
          ),
          ListTile(
            leading: Icon(Icons.report, color: AppColors.error),
            title: Text(LocalizationService.translate('chat.report_message')),
            onTap: () {
              Navigator.pop(context);
              onReport();
            },
          ),
        ],
      ),
    );
  }
}

enum CallType { audio, video }
