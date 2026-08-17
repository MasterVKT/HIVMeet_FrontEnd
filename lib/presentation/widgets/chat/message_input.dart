// lib/presentation/widgets/chat/message_input.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/presentation/widgets/media/media_picker.dart';
import 'package:hivmeet/presentation/widgets/common/hiv_toast.dart';

class MessageInput extends StatefulWidget {
  final Function(String content, MessageType type) onSendMessage;
  final Function(File file, MessageType type) onSendMediaMessage;
  final VoidCallback onStartTyping;
  final VoidCallback onStopTyping;
  final bool isPremium;

  const MessageInput({
    super.key,
    required this.onSendMessage,
    required this.onSendMediaMessage,
    required this.onStartTyping,
    required this.onStopTyping,
    this.isPremium = false,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput>
    with TickerProviderStateMixin {
  late TextEditingController _textController;
  late FocusNode _focusNode;
  late AnimationController _sendButtonController;
  late Animation<double> _sendButtonAnimation;

  bool _isTyping = false;
  bool _showEmojiPicker = false;

  /// Timeout d'inactivité de saisie (F6): si l'utilisateur arrête de taper
  /// sans vider le champ ni envoyer, le TTL cache backend (10s) expire en
  /// silence — sans notification WS explicite à l'interlocuteur, qui
  /// resterait affiché "en train d'écrire..." indéfiniment. On envoie donc
  /// nous-même un stop après une courte pause.
  static const _typingIdleTimeout = Duration(seconds: 3);
  Timer? _typingIdleTimer;

  @override
  void initState() {
    super.initState();

    _textController = TextEditingController();
    _focusNode = FocusNode();

    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _sendButtonAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sendButtonController,
      curve: Curves.elasticOut,
    ));

    _textController.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _typingIdleTimer?.cancel();
    _textController.dispose();
    _focusNode.dispose();
    _sendButtonController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _textController.text.isNotEmpty;

    if (hasText) {
      if (!_isTyping) {
        setState(() {
          _isTyping = true;
        });
        widget.onStartTyping();
        _sendButtonController.forward();
      }
      _typingIdleTimer?.cancel();
      _typingIdleTimer = Timer(_typingIdleTimeout, _stopTypingIfIdle);
    } else if (_isTyping) {
      _typingIdleTimer?.cancel();
      setState(() {
        _isTyping = false;
      });
      widget.onStopTyping();
      _sendButtonController.reverse();
    }
  }

  void _stopTypingIfIdle() {
    if (!mounted || !_isTyping) return;
    setState(() {
      _isTyping = false;
    });
    widget.onStopTyping();
    _sendButtonController.reverse();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus && _showEmojiPicker) {
      setState(() {
        _showEmojiPicker = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      // F9: ferme le picker emoji au tap en dehors de tout ce groupe
      // (bouton + panneau + champ de saisie) — sans ça il fallait rouvrir le
      // clavier manuellement pour le faire disparaître.
      onTapOutside: (_) {
        if (_showEmojiPicker) {
          setState(() => _showEmojiPicker = false);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInputRow(),
            if (_showEmojiPicker) _buildEmojiPicker(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Media button
            _buildMediaButton(),
            const SizedBox(width: 8),

            // Text input
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: AppColors.slate.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.slate.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Emoji button
                    IconButton(
                      icon: Icon(
                        _showEmojiPicker
                            ? Icons.keyboard
                            : Icons.emoji_emotions,
                        color: AppColors.slate,
                      ),
                      onPressed: _toggleEmojiPicker,
                    ),

                    // Text field
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        maxLines: null,
                        // F48: limite alignée sur AppLimits.maxMessageLength
                        // (déjà la limite serveur) — auparavant l'utilisateur
                        // pouvait taper un texte trop long et se le voir
                        // rejeté (400) sans explication au moment d'envoyer.
                        maxLength: AppLimits.maxMessageLength,
                        buildCounter: (
                          context, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) {
                          if (!isFocused || maxLength == null) return null;
                          final remaining = maxLength - currentLength;
                          if (remaining > 100) return null;
                          return Text(
                            '$currentLength/$maxLength',
                            style: TextStyle(
                              fontSize: 11,
                              color: remaining <= 0
                                  ? AppColors.error
                                  : AppColors.slate,
                            ),
                          );
                        },
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: LocalizationService.translate(
                              'chat.type_message',
                              params: {}),
                          hintStyle: TextStyle(color: AppColors.slate),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 12,
                          ),
                        ),
                        style: Theme.of(context).textTheme.bodyMedium,
                        onSubmitted: (_) => _sendTextMessage(),
                      ),
                    ),

                    // Premium features (GIF, stickers)
                    if (widget.isPremium) ...[
                      IconButton(
                        icon: Icon(Icons.gif, color: AppColors.warning),
                        onPressed: _showGifPicker,
                        tooltip: LocalizationService.translate('chat.gifs'),
                      ),
                      IconButton(
                        icon: Icon(Icons.face_retouching_natural,
                            color: AppColors.info),
                        onPressed: _showStickerPicker,
                        tooltip: LocalizationService.translate('chat.stickers'),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Send/Voice button
            _buildSendButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaButton() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(
          Icons.attach_file,
          color: AppColors.primaryPurple,
          size: 20,
        ),
        onPressed: _showMediaPicker,
        tooltip: LocalizationService.translate('chat.attach_media', params: {}),
      ),
    );
  }

  Widget _buildSendButton() {
    return AnimatedBuilder(
      animation: _sendButtonAnimation,
      builder: (context, child) {
        final hasText = _textController.text.isNotEmpty;

        // Enregistrement vocal désactivé proprement (décision produit): le
        // flux précédent était cassé (envoyait la chaîne littérale "0:00"
        // comme contenu du message). Plutôt que de laisser un bouton qui
        // semble fonctionner mais ne fait rien d'utile, le bouton micro
        // affiche un message "bientôt disponible" — même traitement que
        // GIF/stickers.
        return GestureDetector(
          onTap: hasText ? _sendTextMessage : _showVoiceComingSoon,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: hasText
                  ? AppColors.primaryPurple
                  : AppColors.slate.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Transform.scale(
              scale: hasText ? _sendButtonAnimation.value : 1.0,
              child: Icon(
                hasText ? Icons.send : Icons.mic,
                color: hasText ? Colors.white : AppColors.slate,
                size: 20,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmojiPicker() {
    return Container(
      height: 250,
      color: Colors.grey.shade100,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          childAspectRatio: 1,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _getEmojis().length,
        itemBuilder: (context, index) {
          final emoji = _getEmojis()[index];
          return GestureDetector(
            onTap: () => _insertEmoji(emoji),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
    });

    if (_showEmojiPicker) {
      _focusNode.unfocus();
    } else {
      _focusNode.requestFocus();
    }
  }

  void _insertEmoji(String emoji) {
    final currentText = _textController.text;
    final selection = _textController.selection;

    final newText = currentText.replaceRange(
      selection.start,
      selection.end,
      emoji,
    );

    _textController.text = newText;
    _textController.selection = TextSelection.collapsed(
      offset: selection.start + emoji.length,
    );
  }

  void _sendTextMessage() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      widget.onSendMessage(text, MessageType.text);
      _textController.clear();
      HapticFeedback.lightImpact();
    }
  }

  void _showVoiceComingSoon() {
    HIVToast.showInfo(
      context: context,
      message:
          LocalizationService.translate('chat.feature_coming_soon', params: {}),
    );
  }

  void _showMediaPicker() {
    MediaPicker.show(
      context: context,
      onMediaSelected: _sendMediaMessageFile,
    );
  }

  void _sendMediaMessageFile(File file, MessageType type) {
    if (!widget.isPremium && type != MessageType.image) {
      _showPremiumDialog();
      return;
    }

    // Envoyer le fichier média via le callback approprié
    widget.onSendMediaMessage(file, type);
  }

  void _showGifPicker() {
    // TODO: Implémenter le sélecteur de GIFs
    HIVToast.showInfo(
      context: context,
      message:
          LocalizationService.translate('chat.feature_coming_soon', params: {}),
    );
  }

  void _showStickerPicker() {
    // TODO: Implémenter le sélecteur de stickers
    HIVToast.showInfo(
      context: context,
      message:
          LocalizationService.translate('chat.feature_coming_soon', params: {}),
    );
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocalizationService.translate('premium.upgrade_required',
            params: {})),
        content: Text(LocalizationService.translate(
            'chat.premium_media_message',
            params: {})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
                LocalizationService.translate('common.cancel', params: {})),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/premium');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
            ),
            child: Text(
                LocalizationService.translate('premium.upgrade', params: {})),
          ),
        ],
      ),
    );
  }

  List<String> _getEmojis() {
    return [
      '😀',
      '😃',
      '😄',
      '😁',
      '😆',
      '😅',
      '😂',
      '🤣',
      '😊',
      '😇',
      '🙂',
      '🙃',
      '😉',
      '😌',
      '😍',
      '🥰',
      '😘',
      '😗',
      '😙',
      '😚',
      '😋',
      '😛',
      '😝',
      '😜',
      '🤪',
      '🤨',
      '🧐',
      '🤓',
      '😎',
      '🤩',
      '🥳',
      '😏',
      '😒',
      '😞',
      '😔',
      '😟',
      '😕',
      '🙁',
      '☹️',
      '😣',
      '😖',
      '😫',
      '😩',
      '🥺',
      '😢',
      '😭',
      '😤',
      '😠',
      '😡',
      '🤬',
      '🤯',
      '😳',
      '🥵',
      '🥶',
      '😱',
      '😨',
      '😰',
      '😥',
      '😓',
      '🤗',
      '🤔',
      '🤭',
      '🤫',
      '🤥',
      '😶',
      '😐',
      '😑',
      '😬',
      '🙄',
      '😯',
      '😦',
      '😧',
      '😮',
      '😲',
      '🥱',
      '😴',
      '🤤',
      '😪',
      '😵',
      '🤐',
      '🥴',
      '🤢',
      '🤮',
      '🤧',
      '😷',
      '🤒',
      '🤕',
      '🤑',
      '🤠',
      '😈',
      '👿',
      '👹',
      '👺',
      '🤡',
      '💩',
      '👻',
      '💀',
      '☠️',
      '👽',
      '👾',
      '🤖',
      '🎃',
      '😺',
      '😸',
      '😹',
      '😻',
      '😼',
      '😽',
      '🙀',
      '😿',
      '😾',
      '❤️',
      '🧡',
      '💛',
      '💚',
      '💙',
      '💜',
      '🤎',
      '🖤',
      '🤍',
      '💔',
      '❣️',
      '💕',
      '💞',
      '💓',
      '💗',
      '💖',
      '💘',
      '💝',
      '💟',
      '☮️',
      '✝️',
      '☪️',
      '🕉️',
      '☸️',
      '✡️',
      '🔯',
      '🕎',
      '☯️',
      '☦️',
      '🛐',
      '⛎',
      '♈',
      '♉',
      '♊',
      '♋',
      '♌',
      '♍',
      '♎',
      '♏',
      '♐',
      '♑',
      '♒',
      '♓',
      '🆔',
      '⚛️',
      '🉑',
      '☢️',
      '☣️',
      '📴',
    ];
  }
}
