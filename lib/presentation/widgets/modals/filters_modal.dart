// lib/presentation/widgets/modals/filters_modal.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/domain/entities/profile.dart';

class FiltersModal extends StatefulWidget {
  const FiltersModal({super.key});

  @override
  State<FiltersModal> createState() => _FiltersModalState();
}

class _FiltersModalState extends State<FiltersModal> {
  late RangeValues _ageRange;
  late double _distance;
  late List<String> _selectedInterests;
  late bool _verifiedOnly;
  late String _relationshipType;

  @override
  void initState() {
    super.initState();
    _initializeFilters();
  }

  void _initializeFilters() {
    _ageRange = RangeValues(18, 99);
    _distance = 50.0;
    _selectedInterests = [];
    _verifiedOnly = false;
    _relationshipType = 'any';
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
                  _buildRelationshipTypeFilter(),
                  const SizedBox(height: 24),
                  _buildInterestsFilter(),
                  const SizedBox(height: 24),
                  _buildVerifiedFilter(),
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
          min: 1,
          max: 100,
          divisions: 99,
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
              '1 km',
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
          children: [
            _buildRelationshipChip('any', 'discovery.any'),
            _buildRelationshipChip('friendship', 'discovery.friendship'),
            _buildRelationshipChip('relationship', 'discovery.relationship'),
            _buildRelationshipChip('casual', 'discovery.casual'),
          ],
        ),
      ],
    );
  }

  Widget _buildRelationshipChip(String value, String labelKey) {
    final isSelected = _relationshipType == value;
    return FilterChip(
      label: Text(LocalizationService.translate(labelKey)),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _relationshipType = value;
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

  Widget _buildInterestsFilter() {
    final availableInterests = [
      'Musique',
      'Sport',
      'Voyage',
      'Cinéma',
      'Lecture',
      'Cuisine',
      'Art',
      'Nature',
      'Technologie',
      'Mode',
      'Photographie',
      'Danse',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocalizationService.translate('discovery.interests'),
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
          children: availableInterests.map((interest) {
            final isSelected = _selectedInterests.contains(interest);
            return FilterChip(
              label: Text(interest),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    if (_selectedInterests.length < 5) {
                      _selectedInterests.add(interest);
                    }
                  } else {
                    _selectedInterests.remove(interest);
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
          }).toList(),
        ),
        if (_selectedInterests.length >= 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              LocalizationService.translate('discovery.max_interests_selected'),
              style: GoogleFonts.openSans(
                fontSize: 12,
                color: AppColors.warning,
              ),
            ),
          ),
      ],
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
    final newFilters = SearchPreferences(
      minAge: _ageRange.start.round(),
      maxAge: _ageRange.end.round(),
      maxDistance: _distance,
      interestedIn: [], // TODO: Implémenter la sélection de genres
      relationshipTypes: _relationshipType == 'any' ? [] : [_relationshipType],
      showVerifiedOnly: _verifiedOnly,
    );

    // TODO: Appliquer les filtres via le BLoC
    Navigator.of(context).pop(newFilters);
  }
}
