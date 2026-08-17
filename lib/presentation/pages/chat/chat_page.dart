// lib/presentation/pages/chat/chat_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/realtime/realtime_event_bus.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/domain/repositories/profile_repository.dart';
import 'package:hivmeet/injection.dart';
import 'package:hivmeet/presentation/blocs/chat/chat_bloc.dart';
// Events/States sont des parts de ChatBloc, on n'importe que le bloc
import 'package:hivmeet/presentation/widgets/chat/message_bubble.dart';
import 'package:hivmeet/presentation/widgets/chat/message_input.dart';
import 'package:hivmeet/presentation/widgets/common/hiv_toast.dart';
import 'package:hivmeet/presentation/widgets/common/safe_circle_avatar.dart';
import 'package:hivmeet/presentation/widgets/loaders/hiv_loader.dart';

class ChatPage extends StatefulWidget {
  final String conversationId;
  final Conversation? conversation;

  const ChatPage({
    super.key,
    required this.conversationId,
    this.conversation,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late ScrollController _scrollController;
  late AnimationController _appearanceController;
  late AnimationController _typingController;
  late final ChatBloc _chatBloc;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _typingAnimation;

  Conversation? _conversation;
  String? _hydratingParticipantId;
  bool _isHydratingParticipant = false;

  bool _isKeyboardVisible = false;
  bool _showScrollToBottom = false;
  static const double _bottomTolerance = 24;

  // Auto-scroll conditionnel (F1/F2): on ne force le scroll-to-bottom que si
  // l'utilisateur y était déjà, ou au tout premier chargement de la
  // conversation — sinon un message entrant pendant qu'on relit l'historique
  // plus haut arracherait la vue vers le bas sans prévenir.
  bool _wasAtBottom = true;
  bool _didInitialScroll = false;
  int _previousMessageCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _conversation = widget.conversation;

    _chatBloc = getIt<ChatBloc>()
      ..add(LoadConversation(conversationId: widget.conversationId))
      ..add(const ConnectToWebSocket());

    // Les notifications récentes fournissent l'identifiant de l'expéditeur.
    // On hydrate son profil dès l'ouverture, sans attendre les messages. Les
    // anciennes notifications sont couvertes après le chargement des messages.
    final knownOtherUserId = _otherUserId;
    if (knownOtherUserId != null) {
      _hydrateParticipant(knownOtherUserId);
    }

    // Signale au bus temps réel que cette conversation est à l'écran, pour
    // que ConversationsBloc n'applique pas un patch optimiste de non-lu
    // redondant pendant qu'on la regarde déjà (voir
    // ConversationsBloc._onConversationRealtimeSignal).
    getIt<RealtimeEventBus>().setActiveConversation(widget.conversationId);

    // Marquer automatiquement les messages comme lus après le premier chargement.
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Scroll to first unread message after initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToFirstUnread();
    });

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

    // _typingController ne tourne QUE quand l'interlocuteur est en train
    // d'écrire (piloté par le BlocListener ci-dessous) — le laisser tourner
    // en continu pendant toute la durée du chat consommait des cycles
    // d'animation (et donc de la batterie) pour rien la quasi-totalité du
    // temps.
    _appearanceController.forward();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    getIt<RealtimeEventBus>().setActiveConversation(null);
    _scrollController.dispose();
    _appearanceController.dispose();
    _typingController.dispose();
    // Coupe explicitement le WebSocket avant de fermer le bloc — sans ça, la
    // socket ne se ferme que via ChatWebSocketService.dispose() (appelé par
    // ChatBloc.close()), ce qui fonctionne mais ne notifie pas proprement le
    // serveur/le reste du bloc d'un disconnect intentionnel avant close.
    _chatBloc.add(const DisconnectFromWebSocket());
    _chatBloc.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coupe/rouvre le WebSocket de la conversation active avec le cycle de
    // vie de l'app : sans ça, une socket mise en arrière-plan reste ouverte
    // inutilement (batterie) et ne se resynchronise jamais au retour.
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _chatBloc.add(const DisconnectFromWebSocket());
        break;
      case AppLifecycleState.resumed:
        _chatBloc
          ..add(const ConnectToWebSocket())
          // La reconnexion volontaire ci-dessus ne déclenche pas
          // automatiquement de resync (elle succède à une déconnexion
          // intentionnelle, pas à une coupure détectée) : on le fait
          // explicitement pour rattraper les messages reçus pendant que
          // l'app était en arrière-plan.
          ..add(const ResyncMessages());
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  void didChangeMetrics() {
    final bottomInset = View.of(context).viewInsets.bottom;
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
    _wasAtBottom = _isScrolledToBottom();
    _updateScrollToBottomVisibility();

    // Si l'utilisateur est en bas de la conversation, marquer les messages non lus.
    if (_wasAtBottom) {
      _chatBloc.add(const MarkUnreadMessagesAsRead());
    }
  }

  void _updateScrollToBottomVisibility() {
    if (!_scrollController.hasClients) return;

    final shouldShow = !_isScrolledToBottom();
    if (shouldShow == _showScrollToBottom || !mounted) return;

    setState(() {
      _showScrollToBottom = shouldShow;
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController
          .animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      )
          .whenComplete(() {
        if (!mounted) return;
        _wasAtBottom = _isScrolledToBottom();
        _updateScrollToBottomVisibility();
      });
    }
  }

  void _scrollToFirstUnread() {
    if (!_scrollController.hasClients) return;

    // Try to find first unread message and scroll to it
    // Fallback to bottom if no unread messages
    final state = _chatBloc.state;
    if (state is ChatLoaded) {
      final unreadIndex = state.messages.indexWhere((m) => !m.isRead);
      if (unreadIndex != -1 && unreadIndex < state.messages.length) {
        // Scroll to first unread message
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent *
              (unreadIndex / state.messages.length),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        // No unread messages, scroll to bottom
        _scrollToBottom();
      }
    } else {
      _scrollToBottom();
    }
  }

  bool _isScrolledToBottom() {
    if (!_scrollController.hasClients) return false;
    final position = _scrollController.position;
    return position.extentAfter <= _bottomTolerance;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _chatBloc,
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
                      _hydrateParticipantFromMessages(state.messages);
                      if (state.completedAction != null) {
                        final completedAction = state.completedAction!;
                        _chatBloc.add(const ClearChatActionFeedback());
                        HIVToast.showSuccess(
                          context: context,
                          message: completedAction == ChatUserAction.block
                              ? LocalizationService.translate(
                                  'chat.block_success',
                                )
                              : LocalizationService.translate(
                                  'chat.report_success',
                                ),
                        );
                        if (completedAction == ChatUserAction.block) {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/conversations');
                          }
                        }
                        return;
                      }
                      if (state.actionError != null) {
                        _chatBloc.add(const ClearChatActionFeedback());
                        HIVToast.showError(
                          context: context,
                          message: LocalizationService.translate(
                            'chat.action_error',
                          ),
                        );
                        return;
                      }
                      // Typing indicator (F55): l'animation ne tourne que
                      // pendant que l'interlocuteur écrit réellement.
                      if (state.isTyping && !_typingController.isAnimating) {
                        _typingController.repeat(reverse: true);
                      } else if (!state.isTyping &&
                          _typingController.isAnimating) {
                        _typingController.stop();
                        _typingController.value = 0;
                      }

                      // Haptic léger à la réception d'un nouveau message de
                      // l'interlocuteur (F87) — pas au tout premier
                      // chargement de la conversation.
                      final hasNewMessages =
                          state.messages.length > _previousMessageCount;
                      if (hasNewMessages &&
                          _previousMessageCount > 0 &&
                          state.messages.isNotEmpty &&
                          !state.messages.last.isMine) {
                        HapticFeedback.lightImpact();
                      }

                      // Marquer comme lus si on est déjà en bas (ex: message entrant).
                      if (_isScrolledToBottom()) {
                        _chatBloc.add(const MarkUnreadMessagesAsRead());
                      }

                      // Auto-scroll (F1/F2): seulement si l'utilisateur était
                      // déjà en bas, ou au tout premier chargement de la
                      // conversation. Le post-frame callback est nécessaire
                      // car la ListView n'a pas encore de ScrollController
                      // "attaché" (hasClients=false) juste après le passage
                      // ChatLoading -> ChatLoaded — sans lui, le tout premier
                      // scroll-to-bottom ne faisait rien silencieusement.
                      final isFirstLoad =
                          !_didInitialScroll && state.messages.isNotEmpty;
                      if (isFirstLoad || _wasAtBottom) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          _scrollToBottom();
                          _updateScrollToBottomVisibility();
                          if (_isScrolledToBottom()) {
                            _chatBloc.add(const MarkUnreadMessagesAsRead());
                          }
                        });
                        _didInitialScroll = true;
                      } else {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            _updateScrollToBottomVisibility();
                          }
                        });
                      }
                      _previousMessageCount = state.messages.length;
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
                      if (state.messages.isEmpty) {
                        return _buildEmptyState();
                      }

                      return Stack(
                        children: [
                          // Messages list
                          _buildMessagesList(state.messages, state.isTyping),

                          // Scroll to bottom button
                          if (_showScrollToBottom) _buildScrollToBottomButton(),
                        ],
                      );
                    }

                    return Center(
                      child: Text(
                        LocalizationService.translate('common.error'),
                      ),
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

  String get _otherUserName {
    final name = _conversation?.otherUserName?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    return _isHydratingParticipant
        ? LocalizationService.translate('common.loading')
        : LocalizationService.translate('chat.profile_unavailable');
  }

  String? get _otherUserPhotoUrl {
    final photoUrl = _conversation?.otherUserPhotoUrl?.trim();
    return photoUrl == null || photoUrl.isEmpty ? null : photoUrl;
  }

  String? get _otherUserId {
    final otherUserId = _conversation?.otherUserId?.trim();
    if (otherUserId != null && otherUserId.isNotEmpty) {
      return otherUserId;
    }
    final participants = _conversation?.participantIds ?? const <String>[];
    return participants.isNotEmpty ? participants.first : null;
  }

  void _hydrateParticipantFromMessages(List<Message> messages) {
    if (_hasParticipantName || _isHydratingParticipant) return;

    // La liste est chronologique : le dernier message non envoyé par moi est
    // le meilleur candidat, même si la conversation est hors de la première
    // page de `/conversations/`.
    for (final message in messages.reversed) {
      final senderId = message.senderId.trim();
      if (!message.isMine && senderId.isNotEmpty) {
        _hydrateParticipant(senderId);
        return;
      }
    }
  }

  bool get _hasParticipantName {
    final name = _conversation?.otherUserName?.trim();
    return name != null && name.isNotEmpty;
  }

  Future<void> _hydrateParticipant(String userId) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty || _hasParticipantName) return;
    if (_hydratingParticipantId == normalizedUserId) return;

    _hydratingParticipantId = normalizedUserId;
    final currentConversation = _conversation ??
        Conversation(
          id: widget.conversationId,
          participantIds: [normalizedUserId],
          otherUserId: normalizedUserId,
          updatedAt: DateTime.now(),
        );
    final participantIds =
        currentConversation.participantIds.contains(normalizedUserId)
            ? currentConversation.participantIds
            : [...currentConversation.participantIds, normalizedUserId];

    setState(() {
      _conversation = currentConversation.copyWith(
        participantIds: participantIds,
        otherUserId: normalizedUserId,
      );
      _isHydratingParticipant = true;
    });

    try {
      final result =
          await getIt<ProfileRepository>().getProfile(normalizedUserId);
      if (!mounted || _hydratingParticipantId != normalizedUserId) return;

      result.fold(
        (_) => setState(() => _isHydratingParticipant = false),
        (profile) {
          final displayName = profile.displayName.trim();
          if (displayName.isEmpty) {
            setState(() => _isHydratingParticipant = false);
            return;
          }

          setState(() {
            _conversation = _conversation!.copyWith(
              otherUserName: displayName,
              otherUserPhotoUrl: profile.mainPhotoUrl,
              isOnline: profile.isOnline,
              lastActive: profile.lastActive,
            );
            _isHydratingParticipant = false;
          });
        },
      );
    } catch (_) {
      if (!mounted || _hydratingParticipantId != normalizedUserId) return;
      setState(() => _isHydratingParticipant = false);
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: AppColors.charcoal),
        onPressed: () => context.pop(),
      ),
      title: Row(
        children: [
          // Avatar — SafeCircleAvatar gère les erreurs réseau (404, etc.)
          // sans flood d'exceptions contrairement à NetworkImage.
          SafeCircleAvatar(
            imageUrl: _otherUserPhotoUrl,
            radius: 18,
          ),
          const SizedBox(width: 12),

          // Name and status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _otherUserName,
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
                                            AppColors.primaryPurple.withValues(
                                          alpha: 0.5 +
                                              (_typingAnimation.value * 0.5),
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

                    final isOnline = state is ChatLoaded
                        ? state.otherIsOnline ??
                            _conversation?.isOnline ??
                            false
                        : _conversation?.isOnline ?? false;
                    final lastActive = state is ChatLoaded
                        ? state.otherLastActive ?? _conversation?.lastActive
                        : _conversation?.lastActive;

                    return Text(
                      isOnline
                          ? LocalizationService.translate('chat.online')
                          : LocalizationService.translate('chat.last_seen',
                              params: {
                                  'time': _formatLastSeen(lastActive),
                                }),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                isOnline ? AppColors.success : AppColors.slate,
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
          // Évite toute action sur un expéditeur encore inconnu pendant
          // l'hydratation d'une ouverture par notification.
          onSelected: _otherUserId == null ? null : _handleMenuAction,
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
    return GestureDetector(
      // F12: tap dans la zone de messages ferme le clavier (le clavier
      // masquait sinon une partie de la conversation sans moyen rapide de le
      // fermer autrement qu'en rouvrant/refermant manuellement).
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: messages.length + (isTyping ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == messages.length && isTyping) {
            return _buildTypingIndicator();
          }

          final message = messages[index];
          final isMe = message.isMine;
          final previousMessage = index > 0 ? messages[index - 1] : null;

          final showTimestamp = _shouldShowTimestamp(message, previousMessage);

          return Column(
            children: [
              if (showTimestamp) _buildTimestampDivider(message.createdAt),
              MessageBubble(
                message: message,
                isOwnMessage: isMe,
                onDelete: () => _deleteMessage(message),
                onRetry: () => _retryMessage(message),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SafeCircleAvatar(
            imageUrl: _otherUserPhotoUrl,
            radius: 12,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.slate.withValues(alpha: 0.1),
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
                            color: AppColors.slate.withValues(alpha: 0.6),
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
          Expanded(
              child: Divider(color: AppColors.slate.withValues(alpha: 0.3))),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.slate.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              // Heure localisée (F25): 24h en FR, 12h AM/PM en EN — au lieu
              // d'un format HH:mm fixe qui ne convient qu'au FR.
              DateFormat.jm(LocalizationService.instance.currentLocale)
                  .format(timestamp),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.slate,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(
              child: Divider(color: AppColors.slate.withValues(alpha: 0.3))),
        ],
      ),
    );
  }

  Widget _buildScrollToBottomButton() {
    return Positioned(
      right: 16,
      bottom: 16,
      child: FloatingActionButton.small(
        onPressed: _scrollToBottom,
        heroTag: 'scrollToBottom',
        tooltip: LocalizationService.translate('chat.scroll_to_latest'),
        backgroundColor: AppColors.primaryWhite,
        foregroundColor: AppColors.primaryPurple,
        elevation: 4,
        child: const Icon(Icons.keyboard_arrow_down_rounded),
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
                color: AppColors.primaryPurple.withValues(alpha: 0.1),
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
                'name': _otherUserName,
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
          // MessageInput n'appelle onSendMessage que pour le texte (le média
          // passe systématiquement par onSendMediaMessage) — pas de branche
          // morte à gérer ici.
          onSendMessage: (content, type) {
            _chatBloc.add(SendTextMessageEvent(content: content));
          },
          onSendMediaMessage: (file, type) {
            _chatBloc.add(SendMediaMessageEvent(
              mediaFile: file,
              type: type,
            ));
          },
          onStartTyping: () {
            _chatBloc.add(const SetTypingStatus(isTyping: true));
          },
          onStopTyping: () {
            _chatBloc.add(const SetTypingStatus(isTyping: false));
          },
        );
      },
    );
  }

  bool _shouldShowTimestamp(Message message, Message? previousMessage) {
    if (previousMessage == null) return true;

    final timeDiff =
        message.createdAt.difference(previousMessage.createdAt).inHours;
    return timeDiff >= 1;
  }

  String _formatLastSeen(DateTime? lastActive) {
    if (lastActive == null) return '';

    // Décalage d'horloge client/serveur (F68): un timestamp dans le futur ne
    // doit pas produire un résultat absurde ("il y a -5 minutes"). Le repli
    // le plus sûr est "à l'instant".
    if (lastActive.isAfter(DateTime.now())) {
      return LocalizationService.translate('common.just_now');
    }

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
        final otherUserId = _otherUserId;
        if (otherUserId == null || otherUserId.isEmpty) {
          HIVToast.showError(
            context: context,
            message: LocalizationService.translate('chat.profile_unavailable'),
          );
          return;
        }
        context.push('/profile/$otherUserId');
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
    _chatBloc.add(SendTextMessageEvent(content: message));
  }

  void _deleteMessage(Message message) {
    _chatBloc.add(DeleteMessageEvent(messageId: message.id));
  }

  /// Réessaie l'envoi d'un message resté en statut `failed` (F15).
  ///
  /// Envoie une nouvelle tentative avec le même contenu plutôt que de tenter
  /// un DELETE réseau sur l'ancien message : un envoi raté n'a en général
  /// jamais existé côté serveur (id local `temp_...`), donc un DELETE
  /// dessus 404 sans rien casser mais n'apporte rien. L'ancienne bulle
  /// "échec" reste visible ; l'utilisateur peut la supprimer manuellement
  /// via le menu long-press s'il le souhaite. Seul le texte est supporté :
  /// le fichier local d'un média échoué n'est plus disponible depuis
  /// l'entité Message une fois l'optimistic update en place.
  void _retryMessage(Message message) {
    if (message.status != MessageStatus.failed) return;
    if (message.type == MessageType.text && message.content.isNotEmpty) {
      _chatBloc.add(SendTextMessageEvent(content: message.content));
    }
  }

  void _showBlockDialog() {
    final otherUserId = _otherUserId;
    if (otherUserId == null || otherUserId.isEmpty) {
      HIVToast.showError(
        context: context,
        message: LocalizationService.translate('chat.action_error'),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(LocalizationService.translate('chat.block_confirm_title')),
        content: Text(
          LocalizationService.translate(
            'chat.block_confirm_message',
            params: {'name': _otherUserName},
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(LocalizationService.translate('common.cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _chatBloc.add(BlockUserEvent(userId: otherUserId));
            },
            child: Text(LocalizationService.translate('common.block')),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    final otherUserId = _otherUserId;
    if (otherUserId == null || otherUserId.isEmpty) {
      HIVToast.showError(
        context: context,
        message: LocalizationService.translate('chat.action_error'),
      );
      return;
    }

    const reasons = [
      'inappropriate',
      'harassment',
      'scam',
      'other',
    ];
    var selectedReason = reasons.first;
    final detailsController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title:
              Text(LocalizationService.translate('chat.report_dialog_title')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocalizationService.translate(
                    'chat.report_dialog_message',
                    params: {'name': _otherUserName},
                  ),
                ),
                const SizedBox(height: 12),
                for (final reason in reasons)
                  RadioListTile<String>(
                    value: reason,
                    groupValue: selectedReason,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      LocalizationService.translate(
                        'chat.report_reason_$reason',
                      ),
                    ),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => selectedReason = value);
                    },
                  ),
                TextField(
                  controller: detailsController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: LocalizationService.translate(
                      'chat.report_details_label',
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(LocalizationService.translate('common.cancel')),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _chatBloc.add(
                  ReportUserEvent(
                    userId: otherUserId,
                    reason: selectedReason,
                    description: detailsController.text.trim().isEmpty
                        ? null
                        : detailsController.text.trim(),
                  ),
                );
              },
              child: Text(LocalizationService.translate('common.report')),
            ),
          ],
        ),
      ),
    ).whenComplete(detailsController.dispose);
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

enum CallType { audio, video }
