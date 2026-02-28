// lib/presentation/pages/discovery/filters_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/core/utils/accessibility_helper.dart';
import 'package:hivmeet/domain/entities/search_filters.dart';
import 'package:hivmeet/presentation/blocs/discovery/discovery_bloc.dart';
import 'package:hivmeet/presentation/blocs/discovery/discovery_event.dart';
import 'package:hivmeet/presentation/widgets/common/app_button.dart';
import 'package:go_router/go_router.dart';

class FiltersPage extends StatefulWidget {
  const FiltersPage({super.key});

  @override
  State<FiltersPage> createState() => _FiltersPageState();
}

class _FiltersPageState extends State<FiltersPage> {
  late RangeValues _ageRange;
  late double _maxDistance;
  late String _relationshipType;
  late List<String> _genders;
  bool _verifiedOnly = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    // Charger les préférences actuelles depuis le profil ou valeurs par défaut raisonnables
    // Pour l'instant, utiliser des valeurs par défaut larges pour voir TOUS les profils
    _ageRange = const RangeValues(18, 99); // ✅ Tout le monde
    _maxDistance = 100; // ✅ 100 km
    _relationshipType = 'all'; // ✅ Tous types
    _genders = ['all']; // ✅ Tous genres
  }

  void _onChanged() {
    setState(() => _hasChanges = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryWhite,
      appBar: AppBar(
        title: Text(LocalizationService.translate('discovery.filters_title')),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: () {
                setState(() {
                  _ageRange = const RangeValues(25, 40);
                  _maxDistance = 50;
                  _relationshipType = 'all';
                  _genders = ['all'];
                  _verifiedOnly = false;
                  _hasChanges = false;
                });
              },
              child: Text(LocalizationService.translate('discovery.filters_reset')),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Age range
            Text(
              LocalizationService.translate('discovery.filters_age_range'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(LocalizationService.translate(
                  'discovery.filters_age_years',
                  params: {'age': _ageRange.start.round().toString()},
                )),
                Text(LocalizationService.translate(
                  'discovery.filters_age_years',
                  params: {'age': _ageRange.end.round().toString()},
                )),
              ],
            ),
            Semantics(
              label: AccessibilityHelper.getRangeSliderSemanticLabel(
                label: LocalizationService.translate('discovery.filters_age_range'),
                startValue: _ageRange.start,
                endValue: _ageRange.end,
                unit: LocalizationService.translate('discovery.filters_age_unit'),
              ),
              child: RangeSlider(
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
            ),

            const SizedBox(height: AppSpacing.xl),

            // Distance
            Text(
              LocalizationService.translate('discovery.filters_max_distance'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(LocalizationService.translate(
                  'discovery.filters_distance_km',
                  params: {'distance': _maxDistance.round().toString()},
                )),
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
                      LocalizationService.translate('discovery.filters_premium_badge'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            Semantics(
              label: AccessibilityHelper.getSliderSemanticLabel(
                label: LocalizationService.translate('discovery.filters_max_distance'),
                value: _maxDistance,
                unit: LocalizationService.translate('discovery.filters_distance_unit'),
                minValue: 5,
                maxValue: 100,
              ),
              child: Slider(
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
            ),

            const SizedBox(height: AppSpacing.xl),

            // Relationship type
            Text(
              LocalizationService.translate('discovery.filters_relationship_type'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildRelationshipOptions(),

            const SizedBox(height: AppSpacing.xl),

            // Gender preferences
            Text(
              LocalizationService.translate('discovery.filters_looking_for'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildGenderOptions(),

            const SizedBox(height: AppSpacing.xl),

            // Verified only
            Card(
              child: Semantics(
                label: AccessibilityHelper.getToggleSemanticLabel(
                  label: LocalizationService.translate('discovery.filters_verified_only'),
                  value: _verifiedOnly,
                ),
                hint: LocalizationService.translate('discovery.filters_verified_only_subtitle'),
                child: SwitchListTile(
                  title: Text(LocalizationService.translate('discovery.filters_verified_only')),
                  subtitle: Text(
                      LocalizationService.translate('discovery.filters_verified_only_subtitle')),
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
                  activeColor: AppColors.primaryPurple,
                  onChanged: (value) {
                    setState(() => _verifiedOnly = value);
                    _onChanged();
                  },
                ),
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
                      AppColors.primaryPurple.withOpacity(0.1),
                      AppColors.lightPurple.withOpacity(0.1),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                LocalizationService.translate('discovery.filters_premium_title'),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              Text(
                                LocalizationService.translate('discovery.filters_premium_subtitle'),
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
                        onPressed: () => context.push('/premium'),
                        child: Text(LocalizationService.translate('discovery.filters_discover_premium')),
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
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Profile count indicator
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 20,
                    color: AppColors.primaryPurple,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getEstimatedProfileCount(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryPurple,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppButton(
              text: LocalizationService.translate('discovery.filters_apply'),
              onPressed: _hasChanges ? _applyFilters : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelationshipOptions() {
    final options = [
      ('all', LocalizationService.translate('discovery.filters_relationship_all')),
      ('friendship', LocalizationService.translate('discovery.filters_relationship_friendship')),
      ('long_term_relationship', LocalizationService.translate('discovery.filters_relationship_long_term')),
      ('short_term_relationship', LocalizationService.translate('discovery.filters_relationship_short_term')),
      ('casual_dating', LocalizationService.translate('discovery.filters_relationship_casual')),
      ('networking', LocalizationService.translate('discovery.filters_relationship_networking')),
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: options.map((option) {
        final isSelected = _relationshipType == option.$1;
        return ChoiceChip(
          label: Text(option.$2),
          selected: isSelected,
          selectedColor: AppColors.primaryPurple,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.charcoal,
          ),
          onSelected: (selected) {
            if (selected) {
              setState(() => _relationshipType = option.$1);
              _onChanged();
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildGenderOptions() {
    final options = [
      ('all', LocalizationService.translate('discovery.filters_gender_all')),
      ('male', LocalizationService.translate('discovery.filters_gender_male')),
      ('female', LocalizationService.translate('discovery.filters_gender_female')),
      ('non_binary', LocalizationService.translate('discovery.filters_gender_non_binary')),
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: options.map((option) {
        final isSelected = _genders.contains(option.$1);
        return FilterChip(
          label: Text(option.$2),
          selected: isSelected,
          selectedColor: AppColors.primaryPurple,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.charcoal,
          ),
          onSelected: (selected) {
            setState(() {
              if (option.$1 == 'all') {
                _genders = ['all'];
              } else {
                _genders.remove('all');
                if (selected) {
                  _genders.add(option.$1);
                } else {
                  _genders.remove(option.$1);
                  if (_genders.isEmpty) {
                    _genders = ['all'];
                  }
                }
              }
            });
            _onChanged();
          },
        );
      }).toList(),
    );
  }

  /// Calculate estimated profile count based on filter settings
  /// Returns a localized string with the estimated count
  /// TODO: Replace with actual API call to get real-time profile count
  String _getEstimatedProfileCount() {
    // Calculate a rough estimate based on filter restrictiveness
    int baseCount = 100; // Base estimate for wide filters

    // Reduce count based on age range restrictiveness
    int ageRange = _ageRange.end.round() - _ageRange.start.round();
    if (ageRange < 10) {
      baseCount = (baseCount * 0.3).round();
    } else if (ageRange < 20) {
      baseCount = (baseCount * 0.6).round();
    }

    // Reduce count based on distance
    if (_maxDistance < 25) {
      baseCount = (baseCount * 0.4).round();
    } else if (_maxDistance < 50) {
      baseCount = (baseCount * 0.7).round();
    }

    // Reduce count if verified only
    if (_verifiedOnly) {
      baseCount = (baseCount * 0.5).round();
    }

    // Reduce count if specific relationship type
    if (_relationshipType != 'all') {
      baseCount = (baseCount * 0.6).round();
    }

    // Reduce count if specific genders selected
    if (!_genders.contains('all') && _genders.length < 3) {
      baseCount = (baseCount * 0.7).round();
    }

    // Ensure minimum of 5
    baseCount = baseCount < 5 ? 5 : baseCount;

    // Return estimate range
    int minCount = (baseCount * 0.8).round();
    int maxCount = (baseCount * 1.2).round();

    return LocalizationService.translate(
      'discovery.estimated_profiles_count',
      params: {'min': minCount.toString(), 'max': maxCount.toString()},
    );
  }

  void _applyFilters() {
    // ✅ Gérer "all" comme liste vide pour le backend
    final relationshipTypes =
        _relationshipType == 'all' ? <String>[] : [_relationshipType];
    final genders = _genders.contains('all') ? <String>[] : _genders;

    final filters = SearchFilters(
      minAge: _ageRange.start.round(),
      maxAge: _ageRange.end.round(),
      maxDistance: _maxDistance.round(),
      gender: genders.isNotEmpty ? genders.first : null,
      interests: null,
      relationshipTypes: relationshipTypes, // ✅ Maintenant envoyé
      verifiedOnly: _verifiedOnly, // ✅ Maintenant envoyé
    );

    context.read<DiscoveryBloc>().add(UpdateFilters(filters: filters));
    context.pop();
  }
}
