// lib/presentation/pages/conversations/conversations_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hivmeet/injection.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/presentation/blocs/conversations/conversations_bloc.dart';
import 'package:hivmeet/presentation/widgets/conversations/conversations_widgets.dart';
import 'package:hivmeet/presentation/widgets/navigation/app_scaffold.dart';
import 'package:hivmeet/presentation/widgets/notifications/notification_bell_button.dart';

/// Page principale des conversations
///
/// Features:
/// - Liste des conversations triées par dernière activité
/// - Recherche par nom de participant
/// - Pull-to-refresh
/// - Infinite scroll (pagination)
/// - Badge du nombre total de messages non lus
/// - Navigation vers le chat
/// - Bottom navigation bar
///
/// TODO CRITIQUE: Conversation entity ne contient que participantIds, pas les profils.
/// Pour afficher les noms/photos, il faut soit:
/// 1. Enrichir Conversation avec les profils dans le repository
/// 2. Créer un ConversationWithProfile entity
/// 3. Fetch profiles séparément (impacte les performances)
/// Pour l'instant, on affiche "Participant {id}" en attendant la vraie solution.
class ConversationsPage extends StatelessWidget {
  const ConversationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ConversationsBloc>()..add(LoadConversations()),
      child: const _ConversationsPageContent(),
    );
  }
}

class _ConversationsPageContent extends StatefulWidget {
  const _ConversationsPageContent();

  @override
  State<_ConversationsPageContent> createState() =>
      _ConversationsPageContentState();
}

class _ConversationsPageContentState extends State<_ConversationsPageContent> {
  final _scrollController = ScrollController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<ConversationsBloc>().add(LoadMoreConversations());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  void _onConversationTap(Conversation conversation) {
    // Marquer comme lu avant de naviguer
    context.read<ConversationsBloc>().add(
          MarkConversationAsRead(conversationId: conversation.id),
        );

    // Naviguer vers le chat, puis resynchroniser la liste au retour: le
    // badge non-lu total et les cards doivent refléter les messages
    // échangés pendant que le chat était ouvert (F39/F85).
    context.push('/chat/${conversation.id}', extra: conversation).then((_) {
      if (!mounted) return;
      context.read<ConversationsBloc>().add(LoadConversations(refresh: true));
    });
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        context
            .read<ConversationsBloc>()
            .add(const SearchConversations(query: ''));
      }
    });
  }

  /// Obtenir le nom du participant (temporaire - voir TODO)
  String _getParticipantName(Conversation conversation) {
    final name = conversation.otherUserName?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    return LocalizationService.translate('chat.default_user');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      currentIndex: 2, // Messages tab
      appBar: AppBar(
        title: _showSearch
            ? null
            : BlocBuilder<ConversationsBloc, ConversationsState>(
                builder: (context, state) {
                  final totalUnread =
                      state is ConversationsLoaded ? state.totalUnreadCount : 0;

                  return Row(
                    children: [
                      Text(
                        LocalizationService.translate('navigation.messages'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (totalUnread > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$totalUnread',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
        actions: [
          if (!_showSearch) const NotificationBellButton(),
          if (!_showSearch)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _toggleSearch,
              tooltip: LocalizationService.translate('conversations.search'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche (visible si activée)
          if (_showSearch)
            ConversationsSearchBar(
              onSearchChanged: (query) {
                context
                    .read<ConversationsBloc>()
                    .add(SearchConversations(query: query));
              },
            ),

          BlocBuilder<ConversationsBloc, ConversationsState>(
            builder: (context, state) {
              final activeFilter = state is ConversationsLoaded
                  ? state.activeFilter
                  : state is ConversationsLoading
                      ? state.activeFilter
                      : ConversationFilter.all;
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Semantics(
                  label: LocalizationService.translate(
                    'conversations.filter_label',
                  ),
                  child: SegmentedButton<ConversationFilter>(
                    segments: [
                      ButtonSegment(
                        value: ConversationFilter.all,
                        label: Text(LocalizationService.translate(
                          'conversations.filter_all',
                        )),
                      ),
                      ButtonSegment(
                        value: ConversationFilter.unread,
                        label: Text(LocalizationService.translate(
                          'conversations.filter_unread',
                        )),
                      ),
                    ],
                    selected: {activeFilter},
                    onSelectionChanged: (selection) {
                      context.read<ConversationsBloc>().add(
                            ChangeConversationFilter(
                              filter: selection.first,
                            ),
                          );
                    },
                  ),
                ),
              );
            },
          ),

          // Liste des conversations
          Expanded(
            child: BlocConsumer<ConversationsBloc, ConversationsState>(
              listener: (context, state) {
                if (state is ConversationsError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: theme.colorScheme.error,
                      action: SnackBarAction(
                        label: LocalizationService.translate('common.retry'),
                        textColor: Colors.white,
                        onPressed: () {
                          context
                              .read<ConversationsBloc>()
                              .add(LoadConversations(refresh: true));
                        },
                      ),
                    ),
                  );
                }
                if (state is ConversationsLoaded && state.actionError != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.actionError!),
                      backgroundColor: theme.colorScheme.error,
                    ),
                  );
                  context
                      .read<ConversationsBloc>()
                      .add(ClearConversationActionError());
                }
              },
              builder: (context, state) {
                if (state is ConversationsLoading) {
                  return const ConversationsLoadingView();
                }

                if (state is ConversationsError) {
                  return ConversationsErrorView(
                    message: state.message,
                    onRetry: () {
                      context
                          .read<ConversationsBloc>()
                          .add(LoadConversations(refresh: true));
                    },
                  );
                }

                if (state is ConversationsLoaded) {
                  final conversations = state.conversations;

                  if (conversations.isEmpty) {
                    return EmptyConversationsView(
                      searchQuery: state.searchQuery,
                      onMatchesTap: () {
                        context.go('/matches');
                      },
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context
                          .read<ConversationsBloc>()
                          .add(LoadConversations(refresh: true));
                      // Attendre que le chargement soit terminé
                      await Future.delayed(const Duration(milliseconds: 500));
                    },
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: conversations.length + (state.hasMore ? 1 : 0),
                      separatorBuilder: (context, index) {
                        return const Divider(height: 1, indent: 88);
                      },
                      itemBuilder: (context, index) {
                        // Loading indicator à la fin
                        if (index >= conversations.length) {
                          return _buildLoadingMoreIndicator(state);
                        }

                        final conversation = conversations[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: ConversationCard(
                            conversation: conversation,
                            participantName: _getParticipantName(conversation),
                            participantPhotoUrl: conversation.otherUserPhotoUrl,
                            currentUserId: '',
                            onTap: () => _onConversationTap(conversation),
                            onLongPress: () =>
                                _showConversationOptions(context, conversation),
                          ),
                        );
                      },
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMoreIndicator(ConversationsLoaded state) {
    if (!state.isLoadingMore) return const SizedBox.shrink();

    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  void _showConversationOptions(
      BuildContext context, Conversation conversation) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.chat),
              title: Text(
                LocalizationService.translate('conversations.open'),
              ),
              onTap: () {
                Navigator.pop(context);
                _onConversationTap(conversation);
              },
            ),
            if (conversation.unreadCount > 0)
              ListTile(
                leading: Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  LocalizationService.translate('conversations.mark_read'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.read<ConversationsBloc>().add(
                        MarkConversationAsRead(
                          conversationId: conversation.id,
                        ),
                      );
                },
              ),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(LocalizationService.translate('common.view_profile')),
              onTap: () {
                Navigator.pop(context);
                // otherUserId est la source de vérité; participantIds.first
                // n'est qu'un fallback défensif (ordre non garanti côté
                // backend — l'utiliser en priorité pouvait ouvrir le mauvais
                // profil, y compris le sien propre).
                final participantId = conversation.otherUserId ??
                    (conversation.participantIds.isNotEmpty
                        ? conversation.participantIds.first
                        : null);
                if (participantId != null && participantId.isNotEmpty) {
                  context.push('/profile/$participantId');
                }
              },
            ),
            // Pas d'option "Supprimer": le backend n'expose aucun endpoint
            // DELETE /conversations/{id}/ (voir
            // BACKEND_MESSAGING_DELETE_CONVERSATION.md). Une action qui
            // affiche juste "indisponible" est une UI morte trompeuse —
            // mieux vaut ne pas la proposer tant qu'elle ne fonctionne pas
            // réellement.
            ListTile(
              leading: Icon(
                Icons.visibility_off_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                LocalizationService.translate('conversations.hide'),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmHideConversation(context, conversation);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmHideConversation(
    BuildContext context,
    Conversation conversation,
  ) async {
    final shouldHide = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(LocalizationService.translate('conversations.hide_title')),
        content: Text(
          LocalizationService.translate('conversations.hide_message'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(LocalizationService.translate('common.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(LocalizationService.translate('conversations.hide')),
          ),
        ],
      ),
    );
    if (shouldHide == true && context.mounted) {
      context.read<ConversationsBloc>().add(
            DeleteConversation(conversationId: conversation.id),
          );
    }
  }
}
