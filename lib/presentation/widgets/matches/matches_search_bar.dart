// lib/presentation/widgets/matches/matches_search_bar.dart

import 'dart:async';
import 'package:flutter/material.dart';

/// Barre de recherche pour filtrer les matches par nom
///
/// Features:
/// - Debouncing pour éviter les recherches excessives
/// - Animation smooth à l'ouverture/fermeture
/// - Clear button
/// - Focus automatique à l'ouverture
class MatchesSearchBar extends StatefulWidget {
  final Function(String) onSearchChanged;
  final String? initialQuery;
  final Duration debounceDuration;

  const MatchesSearchBar({
    super.key,
    required this.onSearchChanged,
    this.initialQuery,
    this.debounceDuration = const Duration(milliseconds: 300),
  });

  @override
  State<MatchesSearchBar> createState() => _MatchesSearchBarState();
}

class _MatchesSearchBarState extends State<MatchesSearchBar> {
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
          hintText: 'Rechercher un match...',
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

/// Version compacte de la barre de recherche (icône + expansion)
class ExpandableSearchBar extends StatefulWidget {
  final Function(String) onSearchChanged;
  final String? initialQuery;

  const ExpandableSearchBar({
    super.key,
    required this.onSearchChanged,
    this.initialQuery,
  });

  @override
  State<ExpandableSearchBar> createState() => _ExpandableSearchBarState();
}

class _ExpandableSearchBarState extends State<ExpandableSearchBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _widthAnimation;
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  Timer? _debounce;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _focusNode = FocusNode();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _widthAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.initialQuery?.isNotEmpty ?? false) {
      _expand();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _expand() {
    setState(() => _isExpanded = true);
    _animationController.forward();
    _focusNode.requestFocus();
  }

  void _collapse() {
    _controller.clear();
    widget.onSearchChanged('');
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() => _isExpanded = false);
      }
    });
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onSearchChanged(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _widthAnimation,
      builder: (context, child) {
        return Container(
          width: _isExpanded
              ? MediaQuery.of(context).size.width - 32
              : 48,
          height: 48,
          decoration: BoxDecoration(
            color: _isExpanded
                ? theme.colorScheme.surfaceVariant.withOpacity(0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              // Bouton search/back
              IconButton(
                icon: Icon(
                  _isExpanded ? Icons.arrow_back : Icons.search,
                  color: theme.colorScheme.onSurface,
                ),
                onPressed: _isExpanded ? _collapse : _expand,
              ),

              // Champ de recherche (visible uniquement si expanded)
              if (_isExpanded)
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Rechercher...',
                      hintStyle: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      border: InputBorder.none,
                      suffixIcon: _controller.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _controller.clear();
                                widget.onSearchChanged('');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
