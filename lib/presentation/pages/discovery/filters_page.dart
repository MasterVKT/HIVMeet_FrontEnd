// lib/presentation/pages/discovery/filters_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:hivmeet/core/config/routes.dart';
import 'package:hivmeet/core/config/premium_navigation.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/domain/entities/discovery_preference_catalog.dart';
import 'package:hivmeet/domain/entities/search_filters.dart';
import 'package:hivmeet/domain/usecases/match/get_search_filters.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/injection.dart';
import 'package:hivmeet/presentation/blocs/discovery/discovery_bloc.dart';
import 'package:hivmeet/presentation/blocs/discovery/discovery_event.dart';
import 'package:hivmeet/presentation/blocs/auth/auth_bloc_simple.dart';
import 'package:hivmeet/presentation/blocs/auth/auth_state.dart';
import 'package:hivmeet/presentation/widgets/common/app_button.dart';
import 'package:go_router/go_router.dart';

class FiltersPage extends StatefulWidget {
  const FiltersPage({super.key});

  @override
  State<FiltersPage> createState() => _FiltersPageState();
}

class _FiltersPageState extends State<FiltersPage> {
  RangeValues _ageRange = const RangeValues(18, 99);
  double _maxDistance = 100;
  String _relationshipType = DiscoveryPreferenceCatalog.everyone;
  String _gender = DiscoveryPreferenceCatalog.everyone;
  bool _verifiedOnly = false;
  bool _onlineOnly = false;
  bool _hasChanges = false;
  bool _isLoading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadFilters();
  }

  Future<void> _loadFilters() async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    final result = await getIt<GetSearchFilters>()(NoParams());
    if (!mounted) return;
    result.fold(
      (_) => setState(() {
        _isLoading = false;
        _loadFailed = true;
      }),
      (filters) => setState(() {
        _ageRange = RangeValues(
          filters.minAge.toDouble(),
          filters.maxAge.toDouble(),
        );
        _maxDistance = filters.maxDistance;
        _gender = DiscoveryPreferenceCatalog.genderSelection(
          filters.interestedIn,
        );
        _relationshipType = DiscoveryPreferenceCatalog.relationshipSelection(
          filters.relationshipTypes,
        );
        _verifiedOnly = filters.showVerifiedOnly;
        _onlineOnly = filters.showOnlineOnly;
        _isLoading = false;
      }),
    );
  }

  void _onChanged() {
    setState(() => _hasChanges = true);
  }

  String _tr(String key, {Map<String, dynamic>? params}) =>
      LocalizationService.translate(key, params: params);

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBlocSimple>().state;
    final isPremium =
        authState is Authenticated && authState.user.isPremiumActive;
    return Scaffold(
      backgroundColor: AppColors.primaryWhite,
      appBar: AppBar(
        title: Text(_tr('discovery.filters_title')),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: () {
                setState(() {
                  _ageRange = const RangeValues(18, 99);
                  _maxDistance = 100;
                  _relationshipType = DiscoveryPreferenceCatalog.everyone;
                  _gender = DiscoveryPreferenceCatalog.everyone;
                  _verifiedOnly = false;
                  _onlineOnly = false;
                  _hasChanges = false;
                });
              },
              child: Text(_tr('common.reset')),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadFailed
              ? Center(
                  child: TextButton.icon(
                    onPressed: _loadFilters,
                    icon: const Icon(Icons.refresh),
                    label: Text(_tr('discovery.filters_load_error')),
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Age range
                      Text(
                        _tr('discovery.age_range_title'),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _tr('discovery.age_value',
                                params: {'age': '${_ageRange.start.round()}'}),
                          ),
                          Text(
                            _tr('discovery.age_value',
                                params: {'age': '${_ageRange.end.round()}'}),
                          ),
                        ],
                      ),
                      RangeSlider(
                        values: _ageRange,
                        min: 18,
                        max: 99,
                        divisions: 81,
                        activeColor: AppColors.primaryPurple,
                        onChanged: (values) {
                          setState(() => _ageRange = values);
                          _onChanged();
                        },
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Distance
                      Text(
                        _tr('discovery.distance_title'),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _tr('discovery.distance_value', params: {
                              'distance': '${_maxDistance.round()}'
                            }),
                          ),
                          if (_maxDistance >= 100)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryPurple,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _tr('premium.premium_label'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Slider(
                        value: _maxDistance,
                        min: 5,
                        max: 100,
                        divisions: 19,
                        activeColor: AppColors.primaryPurple,
                        onChanged: (value) {
                          setState(() => _maxDistance = value);
                          _onChanged();
                        },
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Relationship type
                      Text(
                        _tr('discovery.relationship_title'),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildRelationshipOptions(),

                      const SizedBox(height: AppSpacing.xl),

                      // Gender preferences
                      Text(
                        _tr('discovery.gender_title'),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildGenderOptions(),

                      const SizedBox(height: AppSpacing.xl),

                      // Verified only
                      if (!isPremium)
                        Card(
                          child: SwitchListTile(
                            title: Text(_tr('discovery.verified_only')),
                            subtitle:
                                Text(_tr('discovery.verified_only_subtitle')),
                            secondary: Container(
                              padding: EdgeInsets.all(AppSpacing.sm),
                              decoration: const BoxDecoration(
                                color: AppColors.primaryPurple,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                            value: _verifiedOnly,
                            thumbColor: WidgetStateProperty.all(
                                AppColors.primaryPurple),
                            onChanged: (value) {
                              setState(() => _verifiedOnly = value);
                              _onChanged();
                            },
                          ),
                        ),

                      const SizedBox(height: AppSpacing.md),

                      Card(
                        child: SwitchListTile(
                          title: Text(_tr('discovery.online_only')),
                          subtitle: Text(_tr('discovery.online_only_subtitle')),
                          secondary: Container(
                            padding: EdgeInsets.all(AppSpacing.sm),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryPurple,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.circle,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                          value: _onlineOnly,
                          thumbColor:
                              WidgetStateProperty.all(AppColors.primaryPurple),
                          onChanged: (value) {
                            setState(() => _onlineOnly = value);
                            _onChanged();
                          },
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Premium filters
                      Card(
                        child: Container(
                          padding: EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryPurple.withOpacityValues(0.1),
                                AppColors.lightPurple.withOpacityValues(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(AppSpacing.sm),
                                    decoration: BoxDecoration(
                                      gradient: AppColors.primaryGradient,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.star,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _tr('discovery.premium_filters_title'),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        Text(
                                          _tr('discovery.premium_filters_subtitle'),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: AppColors.slate,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () => context.push(
                                    PremiumNavigation.location(
                                      returnTo: AppRoutes.discovery,
                                    ),
                                  ),
                                  child:
                                      Text(_tr('discovery.discover_premium')),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacityValues(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: AppButton(
          text: _tr('discovery.apply_filters'),
          onPressed: _hasChanges ? _applyFilters : null,
        ),
      ),
    );
  }

  Widget _buildRelationshipOptions() {
    const options = <String>[
      DiscoveryPreferenceCatalog.everyone,
      ...DiscoveryPreferenceCatalog.relationshipValues,
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: options.map((option) {
        final isSelected = _relationshipType == option;
        return ChoiceChip(
          label: Text(
            _tr(DiscoveryPreferenceCatalog.relationshipLabelKey(option)),
          ),
          selected: isSelected,
          selectedColor: AppColors.primaryPurple,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.charcoal,
          ),
          onSelected: (selected) {
            if (selected) {
              setState(() => _relationshipType = option);
              _onChanged();
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildGenderOptions() {
    const options = <String>[
      DiscoveryPreferenceCatalog.everyone,
      ...DiscoveryPreferenceCatalog.genderValues,
    ];

    return Column(
      children: options.map((option) {
        final isSelected = _gender == option;
        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: ListTile(
            leading: Icon(
              option == DiscoveryPreferenceCatalog.everyone
                  ? Icons.people
                  : Icons.person,
              color: isSelected ? AppColors.primaryPurple : AppColors.slate,
            ),
            title: Text(
              _tr(DiscoveryPreferenceCatalog.genderLabelKey(option)),
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primaryPurple : null,
              ),
            ),
            trailing: isSelected
                ? const Icon(Icons.check_circle, color: AppColors.primaryPurple)
                : const Icon(Icons.circle_outlined, color: AppColors.slate),
            onTap: () {
              setState(() => _gender = option);
              _onChanged();
            },
          ),
        );
      }).toList(),
    );
  }

  void _applyFilters() {
    final relationshipTypes =
        DiscoveryPreferenceCatalog.relationshipPayload(_relationshipType);
    final genders = DiscoveryPreferenceCatalog.genderPayload(_gender);

    final filters = SearchFilters(
      minAge: _ageRange.start.round(),
      maxAge: _ageRange.end.round(),
      maxDistance: _maxDistance.round(),
      genders: genders,
      interests: null,
      relationshipTypes: relationshipTypes, // ✅ Maintenant envoyé
      verifiedOnly: _verifiedOnly, // ✅ Maintenant envoyé
      onlineOnly: _onlineOnly,
    );

    final validationError = filters.validate();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    context
        .read<DiscoveryBloc>()
        .add(UpdateFilters(filters: filters.normalized()));
    context.pop();
  }
}
