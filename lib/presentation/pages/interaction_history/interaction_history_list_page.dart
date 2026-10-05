import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hivmeet/core/config/routes.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/events/app_events.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/domain/entities/interaction_history.dart';
import 'package:hivmeet/presentation/blocs/interaction_history/interaction_history_bloc.dart';
import 'package:hivmeet/presentation/blocs/interaction_history/interaction_history_event.dart';
import 'package:hivmeet/presentation/blocs/interaction_history/interaction_history_state.dart';
import 'package:hivmeet/presentation/widgets/loaders/hiv_loader.dart';

class InteractionHistoryListPage extends StatefulWidget {
  final bool isLike;

  const InteractionHistoryListPage({super.key, required this.isLike});

  @override
  State<InteractionHistoryListPage> createState() =>
      _InteractionHistoryListPageState();
}

class _InteractionHistoryListPageState
    extends State<InteractionHistoryListPage> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  InteractionMatchFilter _filter = InteractionMatchFilter.all;
  late final StreamSubscription<void> _historyChangedSubscription;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _historyChangedSubscription =
        AppEvents().onInteractionHistoryChanged.listen((_) {
      if (mounted) _load(refresh: true);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _historyChangedSubscription.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        _scrollController.position.pixels <
            _scrollController.position.maxScrollExtent * .9) {
      return;
    }
    context.read<InteractionHistoryBloc>().add(
          widget.isLike ? LoadMoreLikes() : LoadMorePasses(),
        );
  }

  void _load({bool refresh = false}) {
    context.read<InteractionHistoryBloc>().add(
          widget.isLike
              ? LoadLikes(
                  refresh: refresh,
                  query: _searchController.text,
                  matchFilter: _filter,
                )
              : LoadPasses(
                  refresh: refresh,
                  query: _searchController.text,
                  matchFilter: _filter,
                ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InteractionHistoryBloc, InteractionHistoryState>(
      listenWhen: (previous, current) =>
          (current is LikesLoaded || current is PassesLoaded) &&
          _actionSequence(current) != _actionSequence(previous),
      listener: (context, state) {
        final message = _actionMessage(state);
        if (message == null) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      },
      builder: (context, state) {
        final view = _viewFor(state);
        return Scaffold(
          backgroundColor: AppColors.primaryWhite,
          appBar: _appBar(context, view),
          body: Column(
            children: [
              _searchAndFilters(context, view),
              Expanded(child: _body(context, state, view)),
            ],
          ),
          bottomNavigationBar: view != null && view.selectedCount > 0
              ? SafeArea(child: _selectionBar(context, view))
              : null,
        );
      },
    );
  }

  AppBar _appBar(BuildContext context, _HistoryView? view) {
    final selecting = view != null && view.selectedCount > 0;
    return AppBar(
      title: Text(
        selecting
            ? _tr('history.selection_count', {'count': view.selectedCount})
            : _tr(
                widget.isLike ? 'history.likes_title' : 'history.passes_title'),
      ),
      actions: [
        if (selecting)
          IconButton(
            tooltip: _tr('history.cancel_selection'),
            icon: const Icon(Icons.close),
            onPressed: () => context
                .read<InteractionHistoryBloc>()
                .add(ClearHistorySelection(isLike: widget.isLike)),
          )
        else if (view != null && view.items.any((item) => item.canRevoke))
          PopupMenuButton<String>(
            onSelected: (value) {
              final bloc = context.read<InteractionHistoryBloc>();
              if (value == 'page') {
                bloc.add(
                    SelectHistoryPage(isLike: widget.isLike, selected: true));
              } else if (value == 'all') {
                bloc.add(SelectAllHistoryResults(isLike: widget.isLike));
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'page',
                child: Text(_tr('history.select_page')),
              ),
              if (view.selectableCount >
                  view.items.where((item) => item.canRevoke).length)
                PopupMenuItem(
                  value: 'all',
                  child: Text(_tr('history.select_all_results', {
                    'count': view.selectableCount,
                  })),
                ),
            ],
          ),
      ],
    );
  }

  Widget _searchAndFilters(BuildContext context, _HistoryView? view) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _load(refresh: true),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: _tr('history.search_hint'),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _load(refresh: true);
                      },
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: InteractionMatchFilter.values.map((filter) {
              final label = switch (filter) {
                InteractionMatchFilter.all => _tr('history.filter_all'),
                InteractionMatchFilter.matched => _tr('history.filter_matched'),
                InteractionMatchFilter.unmatched =>
                  _tr('history.filter_unmatched'),
              };
              return ChoiceChip(
                label: Text(label),
                selected: _filter == filter,
                onSelected: (_) {
                  setState(() => _filter = filter);
                  _load(refresh: true);
                },
              );
            }).toList(growable: false),
          ),
          if (view?.selectAllResults == true)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _tr('history.select_all_results', {
                  'count': view!.selectableCount,
                }),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }

  Widget _body(
    BuildContext context,
    InteractionHistoryState state,
    _HistoryView? view,
  ) {
    if (state is LikesLoading || state is PassesLoading) {
      return const Center(child: HIVLoader());
    }
    if (state is InteractionHistoryError) {
      return Center(
        child: FilledButton(
          onPressed: () => _load(refresh: true),
          child: Text(_tr('history.retry')),
        ),
      );
    }
    if (view == null || view.items.isEmpty) {
      return Center(
          child: Text(_tr(
              widget.isLike ? 'history.empty_likes' : 'history.empty_passes')));
    }
    return RefreshIndicator(
      onRefresh: () async => _load(refresh: true),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: view.items.length + (view.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index >= view.items.length) {
            return const Center(
                child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ));
          }
          return _card(context, view, view.items[index]);
        },
      ),
    );
  }

  Widget _card(
      BuildContext context, _HistoryView view, InteractionHistory item) {
    final selected =
        view.selectAllResults || view.selectedIds.contains(item.id);
    final title = item.profile.displayName;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: item.canRevoke
            ? Checkbox(
                value: selected,
                onChanged: view.selectAllResults
                    ? null
                    : (value) => context.read<InteractionHistoryBloc>().add(
                          ToggleInteractionSelection(
                            isLike: widget.isLike,
                            interactionId: item.id,
                            selected: value ?? false,
                          ),
                        ),
              )
            : const Icon(Icons.lock_outline),
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.type == InteractionType.superLike)
              Semantics(
                label: _tr('history.super_like'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 16),
                    const SizedBox(width: 4),
                    Text(_tr('history.super_like')),
                  ],
                ),
              ),
            Text(item.isMatched ? _tr('history.matched') : item.profile.city),
          ],
        ),
        trailing: item.isMatched
            ? TextButton(
                onPressed: () => context.go(AppRoutes.matches),
                child: Text(_tr('history.manage_match')),
              )
            : IconButton(
                tooltip: _tr(widget.isLike
                    ? 'history.revoke_like'
                    : 'history.revoke_pass'),
                icon: const Icon(Icons.undo),
                onPressed: item.canRevoke
                    ? () => _confirmRevoke(context, singleId: item.id)
                    : null,
              ),
        onTap: item.isMatched
            ? () => context.go(AppRoutes.matches)
            : () => context.push(AppRoutes.profileDetail, extra: item.profile),
      ),
    );
  }

  Widget _selectionBar(BuildContext context, _HistoryView view) {
    return Material(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: FilledButton.icon(
          icon: view.isBulkRevoking
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.undo),
          label: Text(_tr('history.revoke_selection')),
          onPressed: view.isBulkRevoking ? null : () => _confirmRevoke(context),
        ),
      ),
    );
  }

  Future<void> _confirmRevoke(BuildContext context, {String? singleId}) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_tr('history.confirm_revoke_title')),
        content: Text(_tr('history.confirm_revoke_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(_tr('history.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(_tr('history.confirm')),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    final bloc = context.read<InteractionHistoryBloc>();
    if (singleId != null) {
      bloc.add(RevokeInteractionEvent(
          interactionId: singleId, isLike: widget.isLike));
    } else {
      bloc.add(RevokeSelectedInteractions(isLike: widget.isLike));
    }
  }

  _HistoryView? _viewFor(InteractionHistoryState state) {
    if (widget.isLike && state is LikesLoaded) {
      return _HistoryView(
        items: state.likes,
        hasMore: state.hasMore,
        isLoadingMore: state.isLoadingMore,
        totalCount: state.totalCount,
        selectableCount: state.selectableCount,
        selectedIds: state.selectedIds,
        selectAllResults: state.selectAllResults,
        isBulkRevoking: state.isBulkRevoking,
      );
    }
    if (!widget.isLike && state is PassesLoaded) {
      return _HistoryView(
        items: state.passes,
        hasMore: state.hasMore,
        isLoadingMore: state.isLoadingMore,
        totalCount: state.totalCount,
        selectableCount: state.selectableCount,
        selectedIds: state.selectedIds,
        selectAllResults: state.selectAllResults,
        isBulkRevoking: state.isBulkRevoking,
      );
    }
    return null;
  }

  int _actionSequence(InteractionHistoryState state) => switch (state) {
        LikesLoaded value => value.actionSequence,
        PassesLoaded value => value.actionSequence,
        _ => -1,
      };

  String? _actionMessage(InteractionHistoryState state) => switch (state) {
        LikesLoaded value => value.actionMessage,
        PassesLoaded value => value.actionMessage,
        _ => null,
      };
}

class _HistoryView {
  final List<InteractionHistory> items;
  final bool hasMore;
  final bool isLoadingMore;
  final int totalCount;
  final int selectableCount;
  final Set<String> selectedIds;
  final bool selectAllResults;
  final bool isBulkRevoking;

  const _HistoryView({
    required this.items,
    required this.hasMore,
    required this.isLoadingMore,
    required this.totalCount,
    required this.selectableCount,
    required this.selectedIds,
    required this.selectAllResults,
    required this.isBulkRevoking,
  });

  int get selectedCount =>
      selectAllResults ? selectableCount : selectedIds.length;
}

String _tr(String key, [Map<String, dynamic>? params]) =>
    LocalizationService.translate(key, params: params);
