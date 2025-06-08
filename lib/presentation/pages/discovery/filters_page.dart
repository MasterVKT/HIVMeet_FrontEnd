// lib/presentation/pages/discovery/filters_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:hivmeet/domain/entities/profile.dart';
import 'package:hivmeet/presentation/blocs/discovery/discovery_bloc.dart';
import 'package:hivmeet/presentation/blocs/discovery/discovery_event.dart';
import 'package:hivmeet/presentation/widgets/common/app_button.dart';
import 'package:go_router/go_router.dart';

class FiltersPage extends StatefulWidget {
  const FiltersPage({Key? key}) : super(key: key);

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
    // TODO: Charger les préférences actuelles
    _ageRange = const RangeValues(25, 40);
    _maxDistance = 50;
    _relationshipType = 'all';
    _genders = ['all'];
  }

  void _onChanged() {
    setState(() => _hasChanges = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryWhite,
      appBar: AppBar(
        title: const Text('Filtres de recherche'),
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
              child: const Text('Réinitialiser'),
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
              'Tranche d\'âge',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_ageRange.start.round()} ans'),
                Text('${_ageRange.end.round()} ans'),
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
              'Distance maximale',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_maxDistance.round()} km'),
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
                    child: const Text(
                      'Premium',
                      style: TextStyle(
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
              'Type de relation recherchée',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildRelationshipOptions(),

            const SizedBox(height: AppSpacing.xl),

            // Gender preferences
            Text(
              'Je recherche',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildGenderOptions(),

            const SizedBox(height: AppSpacing.xl),

            // Verified only
            Card(
              child: SwitchListTile(
                title: const Text('Profils vérifiés uniquement'),
                subtitle: const Text('Ne voir que les profils avec badge de vérification'),
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
                                'Filtres Premium',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Débloquez plus d\'options de filtrage',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                        child: const Text('Découvrir Premium'),
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
        child: AppButton(
          text: 'Appliquer les filtres',
          onPressed: _hasChanges ? _applyFilters : null,
        ),
      ),
    );
  }

  Widget _buildRelationshipOptions() {
    final options = [
      ('all', 'Tout'),
      ('friendship', 'Amitié'),
      ('long_term_relationship', 'Relation sérieuse'),
      ('short_term_relationship', 'Relation courte'),
      ('casual_dating', 'Rencontres occasionnelles'),
      ('networking', 'Réseautage'),
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
      ('all', 'Tout le monde'),
      ('male', 'Hommes'),
      ('female', 'Femmes'),
      ('non_binary', 'Non-binaire'),
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

  void _applyFilters() {
    final filters = SearchPreferences(
      ageRange: AgeRange(
        min: _ageRange.start.round(),
        max: _ageRange.end.round(),
      ),
      maxDistanceKm: _maxDistance.round(),
      relationshipType: _relationshipType,
      gendersSought: _genders,
    );

    context.read<DiscoveryBloc>().add(UpdateFilters(filters: filters));
    context.pop();
  }
}