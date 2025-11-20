// lib/presentation/pages/conversations/conversations_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hivmeet/presentation/blocs/conversations/conversations_bloc.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/injection.dart';
import 'package:hivmeet/domain/entities/message.dart'; // Ajout pour Conversation

class ConversationsPage extends StatelessWidget {
  const ConversationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ConversationsBloc>()..add(LoadConversations()),
      child: Scaffold(
        backgroundColor: AppColors.primaryWhite,
        appBar: AppBar(
          title: Text(
            'Messages',
            style: GoogleFonts.openSans(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryPurple,
            ),
          ),
          backgroundColor: AppColors.primaryWhite,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.search, color: AppColors.primaryPurple),
              onPressed: () {
                // TODO: Implémenter la recherche de conversations
              },
            ),
            IconButton(
              icon: Icon(Icons.more_vert, color: AppColors.primaryPurple),
              onPressed: () {
                // TODO: Implémenter le menu des options
              },
            ),
          ],
        ),
        body: BlocBuilder<ConversationsBloc, ConversationsState>(
          builder: (context, state) {
            if (state is ConversationsLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryPurple),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Chargement des conversations...',
                      style: GoogleFonts.openSans(
                        fontSize: 16,
                        color: AppColors.slate,
                      ),
                    ),
                  ],
                ),
              );
            }
            if (state is ConversationsError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.primaryPurple.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur: ${state.message}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.openSans(
                        fontSize: 16,
                        color: AppColors.slate,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context
                            .read<ConversationsBloc>()
                            .add(LoadConversations());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: Text(
                        'Réessayer',
                        style: GoogleFonts.openSans(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            if (state is ConversationsLoaded) {
              return StreamBuilder<List<Conversation>>(
                stream: state.stream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primaryPurple),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Chargement des conversations...',
                            style: GoogleFonts.openSans(
                              fontSize: 16,
                              color: AppColors.slate,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: AppColors.primaryPurple.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Erreur de chargement: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.openSans(
                              fontSize: 16,
                              color: AppColors.slate,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context
                                  .read<ConversationsBloc>()
                                  .add(LoadConversations());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                            child: Text(
                              'Réessayer',
                              style: GoogleFonts.openSans(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final conversations = snapshot.data ?? [];

                  if (conversations.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 80,
                            color: AppColors.primaryPurple.withOpacity(0.5),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Aucune conversation',
                            style: GoogleFonts.openSans(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryPurple,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Commencez une conversation avec quelqu\'un !',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.openSans(
                              fontSize: 16,
                              color: AppColors.slate,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context
                          .read<ConversationsBloc>()
                          .add(RefreshConversations());
                    },
                    color: AppColors.primaryPurple,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: conversations.length,
                      itemBuilder: (context, index) {
                        final conv = conversations[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppColors.primaryPurple.withOpacity(0.1),
                              radius: 24,
                              child: Icon(
                                Icons.person,
                                color: AppColors.primaryPurple,
                                size: 24,
                              ),
                            ),
                            title: Text(
                              'Conversation ${conv.id}',
                              style: GoogleFonts.openSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.charcoal,
                              ),
                            ),
                            subtitle: Text(
                              conv.lastMessage?.content ?? 'Aucun message',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.openSans(
                                fontSize: 14,
                                color: AppColors.slate,
                              ),
                            ),
                            trailing: conv.unreadCount > 0
                                ? Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryPurple,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      conv.unreadCount.toString(),
                                      style: GoogleFonts.openSans(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  )
                                : null,
                            onTap: () => context.push('/chat/${conv.id}'),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primaryPurple,
          unselectedItemColor: AppColors.slate,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore),
              label: 'Découverte',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: 'Matches',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
          currentIndex: 2,
          onTap: (index) {
            switch (index) {
              case 0:
                context.go('/discovery');
                break;
              case 1:
                context.go('/matches');
                break;
              case 2:
                // Déjà sur conversations
                break;
              case 3:
                context.go('/profile');
                break;
            }
          },
        ),
      ),
    );
  }
}
