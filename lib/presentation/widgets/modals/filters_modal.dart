// lib/presentation/widgets/modals/filters_modal.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/domain/entities/profile.dart';
import 'package:hivmeet/domain/entities/search_filters.dart';

class FiltersModal extends StatefulWidget {
  final SearchPreferences initialFilters;

  const FiltersModal({
    super.key,
    required this.initialFilters,
  });

  @override
  State<FiltersModal> createState() => _FiltersModalState();
}

class _FiltersModalState extends State<FiltersModal> {
  late RangeValues _ageRange;
  late double _distance;
  late List<String> _selectedGenders;
  late List<String> _selectedRelationshipTypes;
  late bool _verifiedOnly;
  late bool _onlineOnly;

  static const List<(String, String)> _genderOptions = [
    ('all', 'Tout le monde'),
    ('male', 'Hommes'),
    ('female', 'Femmes'),
    ('non_binary', 'Non-binaire'),
    ('trans_male', 'Hommes trans'),
    ('trans_female', 'Femmes trans'),
    ('other', 'Autre'),
    ('prefer_not_to_say', 'Préfère ne pas répondre'),
  ];

  static const List<(String, String)> _relationshipOptions = [
    ('all', 'Tout type'),
    ('friendship', 'Amitié'),
    ('long_term', 'Relation sérieuse'),
    ('short_term', 'Relation courte'),
    ('casual', 'Occasionnelle'),
  ];

  @override
  void initState() {
    super.initState();
    _initializeFilters();
  }

  void _initializeFilters() {
    _ageRange = RangeValues(
      widget.initialFilters.minAge.clamp(18, 99).toDouble(),
      widget.initialFilters.maxAge.clamp(18, 99).toDouble(),
    );
    _distance = widget.initialFilters.maxDistance.clamp(5, 100).toDouble();
    _selectedGenders = widget.initialFilters.interestedIn.isEmpty
        ? ['all']
        : List<String>.from(widget.initialFilters.interestedIn);
    _selectedRelationshipTypes = widget.initialFilters.relationshipTypes.isEmpty
        ? ['all']
        : List<String>.from(widget.initialFilters.relationshipTypes);
    _verifiedOnly = widget.initialFilters.showVerifiedOnly;
    _onlineOnly = widget.initialFilters.showOnlineOnly;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.primaryWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAgeFilter(),
                  const SizedBox(height: 24),
                  _buildDistanceFilter(),
                  const SizedBox(height: 24),
                  _buildGenderFilter(),
                  const SizedBox(height: 24),
                  _buildRelationshipTypeFilter(),
                  const SizedBox(height: 24),
                  _buildVerifiedFilter(),
                  const SizedBox(height: 12),
                  _buildOnlineOnlyFilter(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.platinum,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            LocalizationService.translate('discovery.filters'),
            style: GoogleFonts.openSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoal,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _resetFilters,
            child: Text(
              LocalizationService.translate('common.reset'),
              style: TextStyle(color: AppColors.primaryPurple),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocalizationService.translate('discovery.age_range'),
          style: GoogleFonts.openSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(height: 12),
        RangeSlider(
          values: _ageRange,
          min: 18,
          max: 99,
          divisions: 81,
          activeColor: AppColors.primaryPurple,
          inactiveColor: AppColors.platinum,
          onChanged: (values) {
            setState(() {
              _ageRange = values;
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_ageRange.start.round()} ans',
              style: GoogleFonts.openSans(
                fontSize: 14,
                color: AppColors.slate,
              ),
            ),
            Text(
              '${_ageRange.end.round()} ans',
              style: GoogleFonts.openSans(
                fontSize: 14,
                color: AppColors.slate,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDistanceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocalizationService.translate('discovery.distance'),
          style: GoogleFonts.openSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(height: 12),
        Slider(
          value: _distance,
          min: 5,
          max: 100,
          divisions: 19,
          activeColor: AppColors.primaryPurple,
          inactiveColor: AppColors.platinum,
          onChanged: (value) {
            setState(() {
              _distance = value;
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '5 km',
              style: GoogleFonts.openSans(
                fontSize: 14,
                color: AppColors.slate,
              ),
            ),
            Text(
              '${_distance.round()} km',
              style: GoogleFonts.openSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryPurple,
              ),
            ),
            Text(
              '100 km',
              style: GoogleFonts.openSans(
                fontSize: 14,
                color: AppColors.slate,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRelationshipTypeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocalizationService.translate('discovery.relationship_type'),
          style: GoogleFonts.openSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _relationshipOptions
              .map((option) => _buildMultiSelectChip(
                    list: _selectedRelationshipTypes,
                    value: option.$1,
                    label: option.$2,
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildGenderFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Genres recherchés',
          style: GoogleFonts.openSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _genderOptions
              .map((option) => _buildMultiSelectChip(
                    list: _selectedGenders,
                    value: option.$1,
                    label: option.$2,
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildMultiSelectChip({
    required List<String> list,
    required String value,
    required String label,
  }) {
    final isSelected = list.contains(value);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (value == 'all') {
            list
              ..clear()
              ..add('all');
          } else {
            list.remove('all');
            if (selected) {
              if (!list.contains(value)) {
                list.add(value);
              }
            } else {
              list.remove(value);
            }
            if (list.isEmpty) {
              list.add('all');
            }
          }
        });
      },
      selectedColor: AppColors.primaryPurple.withOpacity(0.2),
      checkmarkColor: AppColors.primaryPurple,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryPurple : AppColors.slate,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildVerifiedFilter() {
    return Row(
      children: [
        Expanded(
          child: Text(
            LocalizationService.translate('discovery.verified_only'),
            style: GoogleFonts.openSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.charcoal,
            ),
          ),
        ),
        Switch(
          value: _verifiedOnly,
          onChanged: (value) {
            setState(() {
              _verifiedOnly = value;
            });
          },
          activeColor: AppColors.primaryPurple,
        ),
      ],
    );
  }

  Widget _buildOnlineOnlyFilter() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Profils en ligne uniquement',
            style: GoogleFonts.openSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.charcoal,
            ),
          ),
        ),
        Switch(
          value: _onlineOnly,
          onChanged: (value) {
            setState(() {
              _onlineOnly = value;
            });
          },
          activeColor: AppColors.primaryPurple,
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.platinum,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.primaryPurple),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                LocalizationService.translate('common.cancel'),
                style: TextStyle(color: AppColors.primaryPurple),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                LocalizationService.translate('common.apply'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _initializeFilters();
    });
  }

  void _applyFilters() {
    final newFilters = SearchFilters(
      minAge: _ageRange.start.round(),
      maxAge: _ageRange.end.round(),
      maxDistance: _distance.round(),
      genders: _selectedGenders.contains('all') ? const [] : _selectedGenders,
      relationshipTypes: _selectedRelationshipTypes.contains('all')
          ? const []
          : _selectedRelationshipTypes,
      verifiedOnly: _verifiedOnly,
      onlineOnly: _onlineOnly,
    );

    final validationError = newFilters.validate();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    Navigator.of(context).pop(newFilters);
  }
}
