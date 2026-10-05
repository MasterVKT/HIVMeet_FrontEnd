// lib/presentation/widgets/chat/message_bubble.dart

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/core/services/media_download_service.dart';
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
  final MediaDownloadService? mediaDownloadService;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback? onSelectionToggle;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isOwnMessage,
    this.onDelete,
    this.onRetry,
    this.mediaDownloadService,
    this.isSelected = false,
    this.selectionMode = false,
    this.onSelectionToggle,
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
          onTap: selectionMode
              ? onSelectionToggle
              : (message.status == MessageStatus.failed
                  ? () => _showFailedMenu(context)
                  : (message.type == MessageType.image &&
                          message.mediaUrl != null
                      ? () => _openImageViewer(context)
                      : null)),
          onLongPress: onSelectionToggle ?? () => _showMessageMenu(context),
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
                DecoratedBox(
                  // The selection outline belongs to the message payload only;
                  // time and receipt icons stay outside of its boundary.
                  decoration: isSelected
                      ? BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color:
                                AppColors.primaryPurple.withValues(alpha: 0.7),
                            width: 1,
                          ),
                        )
                      : const BoxDecoration(),
                  child: _buildBubbleContent(context),
                ),
                const SizedBox(height: AppSpacing.xs),
                _buildFooter(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
    final isMedia = switch (message.type) {
      MessageType.image ||
      MessageType.video ||
      MessageType.audio ||
      MessageType.voice =>
        true,
      _ => false,
    };
    return Container(
      // A three-pixel inset keeps media frames deliberately subtle while
      // preserving the larger touch and text padding for ordinary messages.
      padding: EdgeInsets.all(isMedia ? 3.0 : AppSpacing.md),
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
    if (message.isDeletedForEveryone) {
      return Text(
        LocalizationService.translate('chat.message_deleted'),
        style: TextStyle(
          color: isOwnMessage ? Colors.white : AppColors.slate,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    switch (message.type) {
      case MessageType.text:
        return _buildTextContent(context);
      case MessageType.image:
        return _buildAttachmentWithDownload(
          context,
          _buildImageContent(context),
        );
      case MessageType.video:
        return _buildAttachmentWithDownload(
          context,
          _hasLocalUpload
              ? _LocalMediaUploadPreview(
                  type: message.type,
                  uploadProgress: message.uploadProgress,
                  foregroundColor:
                      isOwnMessage ? Colors.white : AppColors.charcoal,
                )
              : _InlineVideoPlayer(
                  key: ValueKey('${message.id}:${message.mediaUrl}'),
                  url: message.mediaUrl,
                  foregroundColor:
                      isOwnMessage ? Colors.white : AppColors.charcoal,
                ),
        );
      case MessageType.voice:
        return _buildAttachmentWithDownload(
          context,
          _hasLocalUpload
              ? _LocalMediaUploadPreview(
                  type: message.type,
                  uploadProgress: message.uploadProgress,
                  foregroundColor:
                      isOwnMessage ? Colors.white : AppColors.charcoal,
                )
              : _InlineAudioPlayer(
                  key: ValueKey('${message.id}:${message.mediaUrl}'),
                  url: message.mediaUrl,
                  icon: Icons.mic,
                  label:
                      LocalizationService.translate('chat.media_voice_label'),
                  foregroundColor:
                      isOwnMessage ? Colors.white : AppColors.charcoal,
                ),
        );
      case MessageType.audio:
        return _buildAttachmentWithDownload(
          context,
          _hasLocalUpload
              ? _LocalMediaUploadPreview(
                  type: message.type,
                  uploadProgress: message.uploadProgress,
                  foregroundColor:
                      isOwnMessage ? Colors.white : AppColors.charcoal,
                )
              : _InlineAudioPlayer(
                  key: ValueKey('${message.id}:${message.mediaUrl}'),
                  url: message.mediaUrl,
                  icon: Icons.audiotrack,
                  label: LocalizationService.translate('chat.media_audio'),
                  foregroundColor:
                      isOwnMessage ? Colors.white : AppColors.charcoal,
                ),
        );
      case MessageType.callLog:
      case MessageType.system:
        return const SizedBox.shrink();
    }
  }

  bool get _hasLocalUpload =>
      message.localMediaPath != null &&
      message.localMediaPath!.trim().isNotEmpty;

  Widget _buildAttachmentWithDownload(BuildContext context, Widget attachment) {
    final downloadUrl = message.mediaDownloadUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        attachment,
        if (downloadUrl != null &&
            downloadUrl.isNotEmpty &&
            mediaDownloadService != null) ...[
          const SizedBox(height: 4),
          _MediaDownloadButton(
            service: mediaDownloadService!,
            downloadUrl: downloadUrl,
            conversationId: message.conversationId,
            messageId: message.id,
            fileName: message.mediaFileName,
            expectedSizeBytes: message.mediaSizeBytes,
            mimeType: message.mediaMimeType,
            mediaType: message.mediaType,
            foregroundColor: isOwnMessage ? Colors.white : AppColors.charcoal,
          ),
        ],
      ],
    );
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
      TextSpan(
          children: spans.isEmpty
              ? [TextSpan(text: message.content, style: baseStyle)]
              : spans),
    );
  }

  Widget _buildImageContent(BuildContext context) {
    final localPath = message.localMediaPath;
    if (localPath != null &&
        localPath.isNotEmpty &&
        (message.isSending || message.status == MessageStatus.failed)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            Image.file(
              File(localPath),
              width: 200,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _LocalMediaUploadPreview(
                type: MessageType.image,
                uploadProgress: message.uploadProgress,
                foregroundColor:
                    isOwnMessage ? Colors.white : AppColors.charcoal,
              ),
            ),
            if (message.isSending)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.25),
                  child: Center(
                    child: _UploadProgressIndicator(
                      progress: message.uploadProgress,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }
    final url = message.mediaUrl;
    if (url == null || url.isEmpty) {
      return _LocalMediaUploadPreview(
        type: MessageType.image,
        uploadProgress: message.uploadProgress,
        foregroundColor: isOwnMessage ? Colors.white : AppColors.charcoal,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: url,
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
        if (message.editedAt != null && !message.isDeletedForEveryone) ...[
          const SizedBox(width: AppSpacing.xs),
          Text(
            LocalizationService.translate('chat.message_edited'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.slate,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
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
    final time = DateFormat.jm(LocalizationService.instance.currentLocale)
        .format(message.createdAt);
    final statusLabel = switch (message.status) {
      MessageStatus.sending =>
        LocalizationService.translate('chat.message_sending'),
      MessageStatus.failed =>
        LocalizationService.translate('chat.message_failed'),
      _ => '',
    };
    final base = message.isDeletedForEveryone
        ? LocalizationService.translate('chat.message_deleted')
        : (message.type == MessageType.text
            ? message.content
            : message.type.name);
    return statusLabel.isEmpty ? '$base, $time' : '$base, $time, $statusLabel';
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
    final fullDate =
        DateFormat.yMMMd(LocalizationService.instance.currentLocale)
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
                title: Text(LocalizationService.translate('chat.copy_message')),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await Clipboard.setData(ClipboardData(text: message.content));
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

/// Safe attachment placeholder used while a local upload has no server URL
/// yet. It prevents a null URL from reaching network image/video/audio APIs.
class _LocalMediaUploadPreview extends StatelessWidget {
  const _LocalMediaUploadPreview({
    required this.type,
    required this.foregroundColor,
    this.uploadProgress,
  });

  final MessageType type;
  final Color foregroundColor;
  final int? uploadProgress;

  @override
  Widget build(BuildContext context) {
    final icon = switch (type) {
      MessageType.image => Icons.image_outlined,
      MessageType.video => Icons.videocam_outlined,
      MessageType.audio || MessageType.voice => Icons.audiotrack_outlined,
      _ => Icons.attach_file,
    };
    return SizedBox(
      width: 200,
      height: type == MessageType.image ? 160 : 112,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: foregroundColor),
              const SizedBox(height: 6),
              _UploadProgressIndicator(
                progress: uploadProgress,
                foregroundColor: foregroundColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadProgressIndicator extends StatelessWidget {
  const _UploadProgressIndicator({
    required this.progress,
    required this.foregroundColor,
  });

  final int? progress;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final value = progress == null ? null : progress!.clamp(0, 100) / 100;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            value: value,
            color: foregroundColor,
          ),
        ),
        if (progress != null) ...[
          const SizedBox(height: 4),
          Text(
            '${progress!.clamp(0, 100)}%',
            style: TextStyle(fontSize: 11, color: foregroundColor),
          ),
        ],
      ],
    );
  }
}

enum _MediaDownloadState {
  checking,
  idle,
  downloading,
  completed,
  failed,
  cancelled,
}

/// Explicit, cancellable download control. Files are written only after this
/// button is pressed, into application-private storage rather than the gallery.
class _MediaDownloadButton extends StatefulWidget {
  const _MediaDownloadButton({
    required this.service,
    required this.downloadUrl,
    required this.conversationId,
    required this.messageId,
    required this.fileName,
    required this.expectedSizeBytes,
    required this.mimeType,
    required this.mediaType,
    required this.foregroundColor,
  });

  final MediaDownloadService service;
  final String downloadUrl;
  final String conversationId;
  final String messageId;
  final String? fileName;
  final int? expectedSizeBytes;
  final String? mimeType;
  final String? mediaType;
  final Color foregroundColor;

  @override
  State<_MediaDownloadButton> createState() => _MediaDownloadButtonState();
}

class _MediaDownloadButtonState extends State<_MediaDownloadButton> {
  CancelToken? _cancelToken;
  _MediaDownloadState _state = _MediaDownloadState.checking;
  File? _completedFile;
  int _received = 0;
  int _total = -1;
  int _restoreGeneration = 0;

  String get _fileName => mediaDownloadFileName(
        fileName: widget.fileName,
        mediaType: widget.mediaType,
        mimeType: widget.mimeType,
      );

  String? get _mimeType => mediaDownloadMimeType(
        mediaType: widget.mediaType,
        mimeType: widget.mimeType,
      );

  @override
  void initState() {
    super.initState();
    _restoreCompletedFile();
  }

  @override
  void didUpdateWidget(covariant _MediaDownloadButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    final identityChanged = oldWidget.downloadUrl != widget.downloadUrl ||
        oldWidget.conversationId != widget.conversationId ||
        oldWidget.messageId != widget.messageId ||
        oldWidget.fileName != widget.fileName ||
        oldWidget.mimeType != widget.mimeType ||
        oldWidget.mediaType != widget.mediaType ||
        oldWidget.expectedSizeBytes != widget.expectedSizeBytes;
    if (!identityChanged) return;
    _cancelToken?.cancel();
    _completedFile = null;
    _state = _MediaDownloadState.checking;
    _restoreCompletedFile();
  }

  Future<void> _restoreCompletedFile() async {
    final generation = ++_restoreGeneration;
    try {
      final file = await widget.service.findCompleted(
        conversationId: widget.conversationId,
        messageId: widget.messageId,
        fileName: _fileName,
        expectedSizeBytes: widget.expectedSizeBytes,
      );
      if (!mounted || generation != _restoreGeneration) return;
      setState(() {
        _completedFile = file;
        _state = file == null
            ? _MediaDownloadState.idle
            : _MediaDownloadState.completed;
      });
    } catch (_) {
      if (!mounted || generation != _restoreGeneration) return;
      setState(() => _state = _MediaDownloadState.idle);
    }
  }

  Future<void> _start() async {
    if (_state == _MediaDownloadState.downloading) return;
    final cancelToken = CancelToken();
    setState(() {
      _cancelToken = cancelToken;
      _state = _MediaDownloadState.downloading;
      _received = 0;
      _total = -1;
    });
    try {
      final result = await widget.service.download(
        mediaDownloadUrl: widget.downloadUrl,
        conversationId: widget.conversationId,
        messageId: widget.messageId,
        fileName: _fileName,
        expectedSizeBytes: widget.expectedSizeBytes,
        cancelToken: cancelToken,
        onProgress: (received, total) {
          if (!mounted || _cancelToken != cancelToken) return;
          setState(() {
            _received = received;
            _total = total;
          });
        },
      );
      if (!mounted || _cancelToken != cancelToken) return;
      setState(() {
        _completedFile = result.file;
        _state = _MediaDownloadState.completed;
      });
      HIVToast.showSuccess(
        context: context,
        message: LocalizationService.translate('chat.download_saved_in_app'),
      );
    } on DioException catch (error) {
      if (!mounted || _cancelToken != cancelToken) return;
      final cancelled = error.type == DioExceptionType.cancel;
      setState(() => _state = cancelled
          ? _MediaDownloadState.cancelled
          : _MediaDownloadState.failed);
      if (!cancelled) {
        HIVToast.showError(
          context: context,
          message: LocalizationService.translate('chat.download_failed'),
        );
      }
    } catch (_) {
      if (!mounted || _cancelToken != cancelToken) return;
      setState(() => _state = _MediaDownloadState.failed);
      HIVToast.showError(
        context: context,
        message: LocalizationService.translate('chat.download_failed'),
      );
    } finally {
      if (mounted && _cancelToken == cancelToken) {
        setState(() => _cancelToken = null);
      }
    }
  }

  void _cancel() => _cancelToken?.cancel();

  Future<File?> _completedFileOrNull() async {
    final file = _completedFile;
    if (file != null && await file.exists()) return file;
    final restored = await widget.service.findCompleted(
      conversationId: widget.conversationId,
      messageId: widget.messageId,
      fileName: _fileName,
      expectedSizeBytes: widget.expectedSizeBytes,
    );
    if (mounted) {
      setState(() {
        _completedFile = restored;
        _state = restored == null
            ? _MediaDownloadState.idle
            : _MediaDownloadState.completed;
      });
    }
    return restored;
  }

  Future<void> _open() async {
    try {
      final file = await _completedFileOrNull();
      if (file == null) return;
      final result = await OpenFilex.open(file.path, type: _mimeType);
      if (mounted && result.type != ResultType.done) {
        HIVToast.showError(
          context: context,
          message: LocalizationService.translate('chat.download_open_failed'),
        );
      }
    } catch (_) {
      if (!mounted) return;
      HIVToast.showError(
        context: context,
        message: LocalizationService.translate('chat.download_open_failed'),
      );
    }
  }

  Future<void> _share() async {
    try {
      final file = await _completedFileOrNull();
      if (file == null) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          fileNameOverrides: [_fileName],
          subject: _fileName,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      HIVToast.showError(
        context: context,
        message: LocalizationService.translate('chat.download_share_failed'),
      );
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_state == _MediaDownloadState.checking) {
      return Semantics(
        label: LocalizationService.translate('chat.download_checking'),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: widget.foregroundColor,
          ),
        ),
      );
    }
    if (_state == _MediaDownloadState.downloading) {
      final percent = _total > 0
          ? ((_received / _total) * 100).clamp(0, 100).round()
          : null;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 15,
            width: 15,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: _total > 0 ? _received / _total : null,
              color: widget.foregroundColor,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            LocalizationService.translate(
              'chat.download_progress',
              params: {'percent': percent?.toString() ?? '…'},
            ),
            style: TextStyle(fontSize: 12, color: widget.foregroundColor),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: LocalizationService.translate('chat.download_cancel'),
            onPressed: _cancel,
            icon: Icon(Icons.close, color: widget.foregroundColor, size: 18),
          ),
        ],
      );
    }
    if (_state == _MediaDownloadState.completed) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                color: widget.foregroundColor,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                LocalizationService.translate('chat.download_saved_in_app'),
                style: TextStyle(fontSize: 12, color: widget.foregroundColor),
              ),
            ],
          ),
          Wrap(
            spacing: 2,
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: widget.foregroundColor,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                onPressed: _open,
                icon: const Icon(Icons.open_in_new, size: 18),
                label:
                    Text(LocalizationService.translate('chat.download_open')),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: widget.foregroundColor,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                onPressed: _share,
                icon: const Icon(Icons.ios_share_outlined, size: 18),
                label: Text(
                  LocalizationService.translate('chat.download_share_export'),
                ),
              ),
            ],
          ),
        ],
      );
    }
    final retry = _state == _MediaDownloadState.failed ||
        _state == _MediaDownloadState.cancelled;
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: widget.foregroundColor,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
      onPressed: _start,
      icon: Icon(retry ? Icons.refresh : Icons.download_outlined, size: 18),
      label: Text(
        LocalizationService.translate(
          retry ? 'chat.download_retry' : 'chat.download_media',
        ),
      ),
    );
  }
}

/// A compact, lifecycle-safe in-conversation video player.  The controller is
/// owned by the tile so scrolling a message out of view frees its decoder.
class _InlineVideoPlayer extends StatefulWidget {
  const _InlineVideoPlayer({
    super.key,
    required this.url,
    required this.foregroundColor,
  });

  final String? url;
  final Color foregroundColor;

  @override
  State<_InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<_InlineVideoPlayer> {
  VideoPlayerController? _controller;
  bool _failed = false;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _loadUrl();
  }

  @override
  void didUpdateWidget(covariant _InlineVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _loadUrl();
    }
  }

  Future<void> _loadUrl() async {
    final generation = ++_loadGeneration;
    final previous = _controller;
    _controller = null;
    await previous?.dispose();
    if (!mounted || generation != _loadGeneration) return;
    setState(() => _failed = false);

    final url = widget.url?.trim();
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      if (mounted && generation == _loadGeneration) {
        setState(() => _failed = true);
      }
      return;
    }
    final controller = VideoPlayerController.networkUrl(uri);
    try {
      await controller.initialize();
      if (!mounted || generation != _loadGeneration) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      await controller.dispose();
      if (mounted && generation == _loadGeneration) {
        setState(() => _failed = true);
      }
    }
  }

  Future<void> _togglePlayback() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _loadGeneration++;
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_failed) return _MediaUnavailable(color: widget.foregroundColor);
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox(
        width: 200,
        height: 112,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    final aspectRatio = controller.value.aspectRatio <= 0
        ? 16 / 9
        : controller.value.aspectRatio;
    return SizedBox(
      width: 220,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              VideoPlayer(controller),
              ColoredBox(color: Colors.black.withValues(alpha: 0.08)),
              Center(
                child: IconButton.filled(
                  onPressed: _togglePlayback,
                  icon: Icon(
                    controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Inline player used by audio and voice messages. It keeps playback inside
/// the conversation and reports a safe, translated fallback when the media is
/// no longer accessible.
class _InlineAudioPlayer extends StatefulWidget {
  const _InlineAudioPlayer({
    super.key,
    required this.url,
    required this.icon,
    required this.label,
    required this.foregroundColor,
  });

  final String? url;
  final IconData icon;
  final String label;
  final Color foregroundColor;

  @override
  State<_InlineAudioPlayer> createState() => _InlineAudioPlayerState();
}

class _InlineAudioPlayerState extends State<_InlineAudioPlayer> {
  late final AudioPlayer _player;
  bool _ready = false;
  bool _failed = false;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    // No authenticated headers are needed for the public media URLs. Avoid
    // just_audio's local HTTP proxy so iOS does not require an ATS exception.
    _player = AudioPlayer(useProxyForRequestHeaders: false);
    _load();
  }

  @override
  void didUpdateWidget(covariant _InlineAudioPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _load();
    }
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    if (mounted) {
      setState(() {
        _ready = false;
        _failed = false;
      });
    }
    final url = widget.url?.trim();
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      if (mounted && generation == _loadGeneration) {
        setState(() => _failed = true);
      }
      return;
    }
    try {
      await _player.stop();
      await _player.setUrl(uri.toString());
      if (mounted && generation == _loadGeneration) {
        setState(() => _ready = true);
      }
    } catch (_) {
      if (mounted && generation == _loadGeneration) {
        setState(() => _failed = true);
      }
    }
  }

  Future<void> _togglePlayback() async {
    if (!_ready) return;
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  @override
  void dispose() {
    _loadGeneration++;
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return _MediaUnavailable(color: widget.foregroundColor);
    return SizedBox(
      width: 220,
      child: StreamBuilder<PlayerState>(
        stream: _player.playerStateStream,
        builder: (context, stateSnapshot) {
          final isPlaying = stateSnapshot.data?.playing ?? false;
          return Row(
            children: [
              IconButton(
                onPressed: _ready ? _togglePlayback : null,
                icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                color: widget.foregroundColor,
              ),
              Icon(widget.icon, color: widget.foregroundColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.label,
                        style: TextStyle(color: widget.foregroundColor)),
                    StreamBuilder<Duration>(
                      stream: _player.positionStream,
                      builder: (context, positionSnapshot) => Text(
                        _formatDuration(positionSnapshot.data ?? Duration.zero),
                        style: TextStyle(
                          color: widget.foregroundColor.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDuration(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _MediaUnavailable extends StatelessWidget {
  const _MediaUnavailable({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            LocalizationService.translate('chat.media_unavailable'),
            style: TextStyle(color: color),
          ),
        ],
      );
}
