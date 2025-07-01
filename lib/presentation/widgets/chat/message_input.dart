// lib/presentation/widgets/chat/message_input.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final Function(bool isRecording) onRecordingStateChanged;
  final bool isPremium;

  const MessageInput({
    super.key,
    required this.onSendMessage,
    required this.onSendMediaMessage,
    required this.onStartTyping,
    required this.onStopTyping,
    required this.onRecordingStateChanged,
    this.isPremium = false,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput>
    with TickerProviderStateMixin {
  late TextEditingController _textController;
  late FocusNode _focusNode;
  late AnimationController _recordingController;
  late AnimationController _sendButtonController;
  late Animation<double> _recordingAnimation;
  late Animation<double> _sendButtonAnimation;

  bool _isRecording = false;
  bool _isTyping = false;
  bool _showEmojiPicker = false;
  final String _recordingDuration = '0:00';

  @override
  void initState() {
    super.initState();

    _textController = TextEditingController();
    _focusNode = FocusNode();

    _recordingController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _recordingAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _recordingController,
      curve: Curves.easeInOut,
    ));

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
    _textController.dispose();
    _focusNode.dispose();
    _recordingController.dispose();
    _sendButtonController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _textController.text.isNotEmpty;

    if (hasText && !_isTyping) {
      setState(() {
        _isTyping = true;
      });
      widget.onStartTyping();
      _sendButtonController.forward();
    } else if (!hasText && _isTyping) {
      setState(() {
        _isTyping = false;
      });
      widget.onStopTyping();
      _sendButtonController.reverse();
    }
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
    return Container(
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
          if (_isRecording) _buildRecordingIndicator(),
          _buildInputRow(),
          if (_showEmojiPicker) _buildEmojiPicker(),
        ],
      ),
    );
  }

  Widget _buildRecordingIndicator() {
    return AnimatedBuilder(
      animation: _recordingAnimation,
      builder: (context, child) {
        return Container(
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            border: Border(
              bottom: BorderSide(
                color: AppColors.error.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Transform.scale(
                scale: _recordingAnimation.value,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                LocalizationService.translate('chat.recording', params: {}),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const Spacer(),
              Text(
                _recordingDuration,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.charcoal,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        );
      },
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
                        tooltip: 'GIFs',
                      ),
                      IconButton(
                        icon: Icon(Icons.face_retouching_natural,
                            color: AppColors.info),
                        onPressed: _showStickerPicker,
                        tooltip: 'Stickers',
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

        return GestureDetector(
          onTap: hasText ? _sendTextMessage : null,
          onLongPressStart: hasText ? null : _startRecording,
          onLongPressEnd: hasText ? null : _stopRecording,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: hasText
                  ? AppColors.primaryPurple
                  : (_isRecording
                      ? AppColors.error
                      : AppColors.slate.withValues(alpha: 0.2)),
              shape: BoxShape.circle,
            ),
            child: Transform.scale(
              scale: hasText ? _sendButtonAnimation.value : 1.0,
              child: Icon(
                hasText ? Icons.send : (_isRecording ? Icons.stop : Icons.mic),
                color: hasText || _isRecording ? Colors.white : AppColors.slate,
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

  void _startRecording(LongPressStartDetails details) {
    if (!widget.isPremium) {
      _showPremiumDialog();
      return;
    }

    setState(() {
      _isRecording = true;
    });

    widget.onRecordingStateChanged(true);
    _recordingController.repeat(reverse: true);
    HapticFeedback.heavyImpact();

    // TODO: Démarrer l'enregistrement audio
  }

  void _stopRecording(LongPressEndDetails details) {
    if (!_isRecording) return;

    setState(() {
      _isRecording = false;
    });

    widget.onRecordingStateChanged(false);
    _recordingController.stop();
    _recordingController.reset();

    // TODO: Arrêter l'enregistrement et envoyer le message vocal
    widget.onSendMessage(_recordingDuration, MessageType.audio);
    HapticFeedback.lightImpact();
  }

  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MediaPicker(
        onMediaSelected: (file, type) {
          Navigator.pop(context);
          _sendMediaMessageFile(file, type);
        },
      ),
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
              // TODO: Naviguer vers la page premium
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
