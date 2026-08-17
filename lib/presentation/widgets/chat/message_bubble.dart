// lib/presentation/widgets/chat/message_bubble.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/presentation/widgets/common/hiv_toast.dart';
import 'package:intl/intl.dart';

/// Détecte les URLs dans un texte pour les rendre cliquables (F22).
final RegExp _urlPattern = RegExp(
  r'((https?://)[^\s<>"]+)',
  caseSensitive: false,
);

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isOwnMessage;
  final VoidCallback? onDelete;
  final VoidCallback? onRetry;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isOwnMessage,
    this.onDelete,
    this.onRetry,
  });

  /// Cas d'une bulle texte optimiste vide, créée le temps qu'un envoi média
  /// soit confirmé (F65) — ne rien afficher plutôt qu'une bulle vide qui
  /// clignote une fraction de seconde.
  bool get _isEmptyOptimisticText =>
      message.type == MessageType.text && message.content.trim().isEmpty;

  @override
  Widget build(BuildContext context) {
    if (_isEmptyOptimisticText) {
      return const SizedBox.shrink();
    }

    return Semantics(
      // F59: le lecteur d'écran doit annoncer expéditeur/heure/statut, pas
      // seulement le contenu brut de la bulle.
      label: _semanticsLabel(context),
      button: true,
      child: Align(
        alignment: isOwnMessage ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onTap: message.status == MessageStatus.failed
              ? () => _showFailedMenu(context)
              : (message.type == MessageType.image && message.mediaUrl != null
                  ? () => _openImageViewer(context)
                  : (_isExternalMediaType
                      ? () => _openExternalMedia(context)
                      : null)),
          onLongPress: () => _showMessageMenu(context),
          child: Container(
            margin: EdgeInsets.symmetric(
              vertical: AppSpacing.xs,
              horizontal: AppSpacing.md,
            ),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: Column(
              crossAxisAlignment: isOwnMessage
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                _buildBubbleContent(context),
                const SizedBox(height: AppSpacing.xs),
                _buildFooter(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _isExternalMediaType =>
      (message.type == MessageType.video ||
          message.type == MessageType.audio ||
          message.type == MessageType.voice) &&
      (message.mediaUrl?.isNotEmpty ?? false);

  Widget _buildBubbleContent(BuildContext context) {
    switch (message.type) {
      case MessageType.callLog:
        return _buildCallLogBubble(context);
      case MessageType.system:
        return _buildSystemBubble(context);
      default:
        return _buildStandardBubble(context);
    }
  }

  /// Bulle standard (fond coloré + coins arrondis) pour text/image/video/
  /// audio/voice — callLog et system ont un rendu neutre dédié.
  Widget _buildStandardBubble(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isOwnMessage ? AppColors.primaryPurple : AppColors.platinum,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isOwnMessage ? 16 : 4),
          bottomRight: Radius.circular(isOwnMessage ? 4 : 16),
        ),
      ),
      child: _buildContentByType(context),
    );
  }

  Widget _buildContentByType(BuildContext context) {
    switch (message.type) {
      case MessageType.text:
        return _buildTextContent(context);
      case MessageType.image:
        return _buildImageContent(context);
      case MessageType.video:
        return _buildMediaPlaceholder(
          context,
          icon: Icons.play_circle_fill,
          label: LocalizationService.translate('chat.media_video'),
        );
      case MessageType.voice:
        return _buildMediaPlaceholder(
          context,
          icon: Icons.mic,
          label: LocalizationService.translate('chat.media_voice_label'),
        );
      case MessageType.audio:
        return _buildMediaPlaceholder(
          context,
          icon: Icons.audiotrack,
          label: LocalizationService.translate('chat.media_audio'),
        );
      // callLog/system ne passent jamais par ici: _buildBubbleContent les
      // route directement vers leur rendu dédié (bulle neutre, pas de fond
      // coloré). Ce switch ne couvre donc que les types "standard".
      case MessageType.callLog:
      case MessageType.system:
        return const SizedBox.shrink();
    }
  }

  /// F22/F23: liens cliquables + texte sélectionnable (gratuit avec
  /// SelectableText). Les messages reçus ET envoyés sont sélectionnables —
  /// seul le long-press (menu contextuel) diffère du comportement natif de
  /// sélection, pas de conflit constaté en pratique.
  Widget _buildTextContent(BuildContext context) {
    final baseColor = isOwnMessage ? Colors.white : AppColors.charcoal;
    final baseStyle = TextStyle(color: baseColor);
    final linkStyle = baseStyle.copyWith(
      decoration: TextDecoration.underline,
      fontWeight: FontWeight.w600,
    );

    final spans = <InlineSpan>[];
    var lastEnd = 0;
    for (final match in _urlPattern.allMatches(message.content)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: message.content.substring(lastEnd, match.start),
          style: baseStyle,
        ));
      }
      final url = match.group(0)!;
      spans.add(TextSpan(
        text: url,
        style: linkStyle,
        recognizer: TapGestureRecognizer()..onTap = () => _openUrl(url),
      ));
      lastEnd = match.end;
    }
    if (lastEnd < message.content.length) {
      spans.add(TextSpan(
        text: message.content.substring(lastEnd),
        style: baseStyle,
      ));
    }

    return SelectableText.rich(
      TextSpan(children: spans.isEmpty ? [TextSpan(text: message.content, style: baseStyle)] : spans),
    );
  }

  Widget _buildImageContent(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: message.mediaUrl!,
        width: 200,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: 200,
          height: 200,
          color: Colors.black12,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: 200,
          height: 120,
          color: Colors.black12,
          child: const Center(
            child: Icon(Icons.broken_image_outlined, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  /// Rendu riche sans lecture inline pour video/voice/audio (F21) — aucun
  /// lecteur média n'est présent dans le projet (pas de video_player /
  /// audioplayers). Icône + libellé + tap-to-open externe si une URL existe.
  Widget _buildMediaPlaceholder(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final color = isOwnMessage ? Colors.white : AppColors.charcoal;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: TextStyle(color: color),
          ),
        ),
      ],
    );
  }

  Widget _buildCallLogBubble(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.slate.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.call_end, size: 16, color: AppColors.slate),
          const SizedBox(width: 6),
          Text(
            message.content.isNotEmpty
                ? message.content
                : LocalizationService.translate('chat.call_log_generic'),
            style: TextStyle(color: AppColors.slate, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemBubble(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(
        message.content.isNotEmpty
            ? message.content
            : LocalizationService.translate('chat.system_message'),
        style: TextStyle(
          color: AppColors.slate,
          fontStyle: FontStyle.italic,
          fontSize: 13,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          // F25: heure localisée (24h FR / 12h AM-PM EN) au lieu d'un format
          // HH:mm fixe.
          DateFormat.jm(LocalizationService.instance.currentLocale)
              .format(message.createdAt),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.slate,
              ),
        ),
        if (isOwnMessage) ...[
          const SizedBox(width: AppSpacing.xs),
          _buildStatusIcon(),
        ],
      ],
    );
  }

  /// F14: distingue visuellement sending/failed/sent/read — auparavant seul
  /// `read` était différent, un message resté "sending" ou "failed" avait
  /// exactement la même icône qu'un message correctement envoyé.
  Widget _buildStatusIcon() {
    switch (message.status) {
      case MessageStatus.sending:
        return const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: AppColors.slate,
          ),
        );
      case MessageStatus.failed:
        return Icon(Icons.error_outline, size: 16, color: AppColors.error);
      case MessageStatus.read:
        return Icon(Icons.done_all, size: 16, color: AppColors.primaryPurple);
      case MessageStatus.delivered:
        return Icon(Icons.done_all, size: 16, color: AppColors.slate);
      case MessageStatus.sent:
        return Icon(Icons.done, size: 16, color: AppColors.slate);
    }
  }

  String _semanticsLabel(BuildContext context) {
    final time =
        DateFormat.jm(LocalizationService.instance.currentLocale)
            .format(message.createdAt);
    final statusLabel = switch (message.status) {
      MessageStatus.sending =>
        LocalizationService.translate('chat.message_sending'),
      MessageStatus.failed =>
        LocalizationService.translate('chat.message_failed'),
      _ => '',
    };
    final base = message.type == MessageType.text
        ? message.content
        : message.type.name;
    return statusLabel.isEmpty ? '$base, $time' : '$base, $time, $statusLabel';
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openExternalMedia(BuildContext context) async {
    final url = message.mediaUrl;
    if (url == null || url.isEmpty) return;
    await _openUrl(url);
  }

  void _openImageViewer(BuildContext context) {
    final url = message.mediaUrl;
    if (url == null || url.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: PhotoView(
            imageProvider: CachedNetworkImageProvider(url),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
          ),
        ),
      ),
    );
  }

  /// F15: menu dédié aux messages `failed` (réessayer / supprimer) —
  /// auparavant un message échoué semblait envoyé, sans aucun moyen de le
  /// renvoyer ou de le supprimer autrement qu'en devinant.
  void _showFailedMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onRetry != null)
              ListTile(
                leading: const Icon(Icons.refresh),
                title: Text(LocalizationService.translate('chat.retry_send')),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onRetry?.call();
                },
              ),
            if (onDelete != null)
              ListTile(
                leading: Icon(Icons.delete_outline, color: AppColors.error),
                title: Text(
                  LocalizationService.translate('common.delete'),
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onDelete?.call();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// F16/F18: long-press → copier / (supprimer si message propre) + affiche
  /// la date complète (un `HH:mm` seul devient ambigu après 24h).
  void _showMessageMenu(BuildContext context) {
    final fullDate = DateFormat.yMMMd(LocalizationService.instance.currentLocale)
        .add_Hm()
        .format(message.createdAt);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                fullDate,
                style: TextStyle(color: AppColors.slate, fontSize: 13),
              ),
            ),
            if (message.type == MessageType.text)
              ListTile(
                leading: const Icon(Icons.copy),
                title:
                    Text(LocalizationService.translate('chat.copy_message')),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await Clipboard.setData(
                      ClipboardData(text: message.content));
                  if (context.mounted) {
                    HIVToast.showSuccess(
                      context: context,
                      message: LocalizationService.translate(
                          'chat.copied_to_clipboard'),
                    );
                  }
                },
              ),
            if (isOwnMessage && onDelete != null)
              ListTile(
                leading: Icon(Icons.delete_outline, color: AppColors.error),
                title: Text(
                  LocalizationService.translate('common.delete'),
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onDelete?.call();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
