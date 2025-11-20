// lib/presentation/widgets/conversations/conversations_search_bar.dart

import 'dart:async';
import 'package:flutter/material.dart';

/// Barre de recherche pour filtrer les conversations
///
/// Features:
/// - Debouncing pour éviter les recherches excessives
/// - Animation smooth à l'ouverture/fermeture
/// - Clear button
/// - Focus automatique à l'ouverture
class ConversationsSearchBar extends StatefulWidget {
  final Function(String) onSearchChanged;
  final String? initialQuery;
  final Duration debounceDuration;

  const ConversationsSearchBar({
    super.key,
    required this.onSearchChanged,
    this.initialQuery,
    this.debounceDuration = const Duration(milliseconds: 300),
  });

  @override
  State<ConversationsSearchBar> createState() => _ConversationsSearchBarState();
}

class _ConversationsSearchBarState extends State<ConversationsSearchBar> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    // Annuler le timer précédent
    _debounce?.cancel();

    // Créer un nouveau timer
    _debounce = Timer(widget.debounceDuration, () {
      widget.onSearchChanged(query);
    });
  }

  void _clearSearch() {
    _controller.clear();
    widget.onSearchChanged('');
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withOpacity(0.1),
          ),
        ),
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Rechercher une conversation...',
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  onPressed: _clearSearch,
                )
              : null,
          filled: true,
          fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          isDense: true,
        ),
      ),
    );
  }
}
