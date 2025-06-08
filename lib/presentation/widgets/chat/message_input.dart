// lib/presentation/widgets/chat/message_input.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/config/constants.dart';

class MessageInput extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSend;
  final Function(bool)? onTypingChanged;

  const MessageInput({
    Key? key,
    required this.controller,
    required this.onSend,
    this.onTypingChanged,
  }) : super(key: key);

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  Timer? _typingTimer;
  bool _isTyping = false;

  void _handleTextChanged(String text) {
    if (!_isTyping) {
      _isTyping = true;
      widget.onTypingChanged?.call(true);
    }
    
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        widget.onTypingChanged?.call(false);
      }
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: () {
              // TODO: Media picker
            },
            color: AppColors.slate,
          ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              onChanged: _handleTextChanged,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Écrire un message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.platinum,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: widget.controller.text.trim().isEmpty
                ? null
                : () => widget.onSend(widget.controller.text.trim()),
            color: AppColors.primaryPurple,
          ),
        ],
      ),
    );
  }
}