import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hivmeet/core/config/routes.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/presentation/blocs/notifications/notifications_bloc.dart';
import 'package:hivmeet/presentation/blocs/notifications/notifications_state.dart';

/// Cloche commune : elle lit toujours la même source globale de vérité que
/// le centre de notifications, quel que soit l'écran depuis lequel elle est
/// affichée.
class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsBloc, NotificationsState>(
      builder: (context, state) {
        final unread = state is NotificationsLoaded ? state.unreadCount : 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () => context.push(AppRoutes.notifications),
              tooltip: LocalizationService.translate('common.notifications'),
            ),
            if (unread > 0)
              Positioned(
                right: 6,
                top: 6,
                child: ExcludeSemantics(
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unread > 99 ? '99+' : '$unread',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
