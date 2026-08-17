// lib/presentation/pages/profile/create_profile_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:hivmeet/domain/entities/profile.dart';
import 'package:hivmeet/injection.dart';
import 'package:hivmeet/presentation/blocs/profile/profile_bloc.dart';
import 'package:hivmeet/presentation/blocs/profile/profile_state.dart';
import 'package:hivmeet/presentation/blocs/profile/profile_event.dart';
import 'package:hivmeet/presentation/widgets/common/app_button.dart';
import 'package:hivmeet/presentation/widgets/common/app_text_field.dart';
import 'package:hivmeet/presentation/widgets/dialogs/hiv_dialogs.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:permission_handler/permission_handler.dart';

class CreateProfilePage extends StatefulWidget {
  const CreateProfilePage({super.key});

  @override
  State<CreateProfilePage> createState() => _CreateProfilePageState();
}

class _CreateProfilePageState extends State<CreateProfilePage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Controllers
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();

  // State
  File? _mainPhoto;
  final List<String> _selectedInterests = [];
  String _selectedRelationshipType = RelationshipType.friendship;
  final List<String> _selectedGenders = [];
  RangeValues _ageRange = const RangeValues(18, 50);
  double _maxDistance = 50;

  // Location
  Position? _currentPosition;
  bool _isLoadingLocation = false;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  @override
  void dispose() {
    _bioController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      await _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _currentPosition = position;
          _cityController.text = place.locality ?? '';
          _countryController.text = place.country ?? '';
        });
      }
    } catch (e) {
      if (!mounted) return;
      HIVToast.showError(
        context: context,
        message: _tr('create_profile.location_error'),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(_tr('create_profile.take_photo')),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(_tr('create_profile.choose_gallery')),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final XFile? image = await picker.pickImage(source: source);
      if (image != null) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: _tr('create_profile.crop_photo'),
              toolbarColor: AppColors.primaryPurple,
              toolbarWidgetColor: Colors.white,
              activeControlsWidgetColor: AppColors.primaryPurple,
            ),
            IOSUiSettings(
              title: _tr('create_profile.crop_photo'),
            ),
          ],
        );

        if (croppedFile != null) {
          setState(() {
            _mainPhoto = File(croppedFile.path);
          });
        }
      }
    }
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      if (_currentStep < 3) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _createProfile();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_mainPhoto == null) {
          HIVToast.showError(
            context: context,
            message: _tr('create_profile.error_photo_required'),
          );
          return false;
        }
        return true;
      case 1:
        if (_bioController.text.isEmpty) {
          HIVToast.showError(
            context: context,
            message: _tr('create_profile.error_bio_required'),
          );
          return false;
        }
        if (_selectedInterests.isEmpty) {
          HIVToast.showError(
            context: context,
            message: _tr('create_profile.error_interests_required'),
          );
          return false;
        }
        return true;
      case 2:
        if (_cityController.text.isEmpty || _countryController.text.isEmpty) {
          HIVToast.showError(
            context: context,
            message: _tr('create_profile.error_location_required'),
          );
          return false;
        }
        return true;
      case 3:
        if (_selectedGenders.isEmpty) {
          HIVToast.showError(
            context: context,
            message: _tr('create_profile.error_gender_required'),
          );
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _createProfile() {
    if (_mainPhoto == null || _currentPosition == null) {
      HIVToast.showError(
        context: context,
        message: _tr('create_profile.error_photo_location_required'),
      );
      return;
    }

    final bloc = context.read<ProfileBloc>();
    bloc.add(CreateProfile(
      mainPhoto: _mainPhoto!,
      bio: _bioController.text,
      interests: List<String>.from(_selectedInterests),
      relationshipType: _selectedRelationshipType,
      relationshipTypesSought: [_selectedRelationshipType],
      city: _cityController.text,
      country: _countryController.text,
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
      minAge: _ageRange.start.round(),
      maxAge: _ageRange.end.round(),
      maxDistance: _maxDistance,
      interestedIn: List<String>.from(_selectedGenders),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ProfileBloc>(),
      child: BlocListener<ProfileBloc, ProfileState>(
        listenWhen: (previous, current) {
          // Éviter les écoutes multiples sur le même état final
          if (previous == current) return false;
          return current is ProfileActionSuccess ||
              current is ProfileError ||
              current is ProfileLoading ||
              current is PhotoUploading ||
              current is ProfileUpdating;
        },
        listener: (context, state) {
          if (state is ProfileActionSuccess) {
            HIVToast.showSuccess(
              context: context,
              message: _tr('create_profile.success_created'),
            );
            context.go('/discovery');
            return;
          }

          if (state is ProfileError) {
            HIVToast.showError(
              context: context,
              message: state.message,
            );
            setState(() {
              _isSubmitting = false;
            });
            return;
          }

          setState(() {
            _isSubmitting = state is ProfileLoading ||
                state is PhotoUploading ||
                state is ProfileUpdating;
          });
        },
        child: Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // Progress indicator
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          if (_currentStep > 0)
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: _isSubmitting ? null : _previousStep,
                            )
                          else
                            const SizedBox(width: 48),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: (_currentStep + 1) / 4,
                              backgroundColor: AppColors.platinum,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primaryPurple,
                              ),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _tr(
                          'create_profile.step_counter',
                          params: {
                            'current': '${_currentStep + 1}',
                            'total': '4',
                          },
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.slate,
                            ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() {
                        _currentStep = index;
                      });
                    },
                    children: [
                      _buildPhotoStep(),
                      _buildBioStep(),
                      _buildLocationStep(),
                      _buildPreferencesStep(),
                    ],
                  ),
                ),

                // Next button
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: AppButton(
                    onPressed: _isSubmitting ? null : _nextStep,
                    text: _currentStep < 3
                        ? _tr('create_profile.next')
                        : (_isSubmitting
                            ? _tr('create_profile.creating')
                            : _tr('create_profile.create')),
                    type: ButtonType.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoStep() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _tr('create_profile.photo_title'),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _tr('create_profile.photo_subtitle'),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.slate,
                ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Photo picker
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.platinum,
                  borderRadius: BorderRadius.circular(24),
                  image: _mainPhoto != null
                      ? DecorationImage(
                          image: FileImage(_mainPhoto!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _mainPhoto == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo,
                            size: 48,
                            color: AppColors.slate,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            _tr('create_profile.add_photo'),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.slate,
                                ),
                          ),
                        ],
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _tr('create_profile.bio_title'),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _tr('create_profile.bio_subtitle'),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.slate,
                ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Bio
          AppTextField(
            controller: _bioController,
            label: _tr('profile.bio'),
            hintText: _tr('create_profile.bio_hint'),
            maxLines: 5,
            maxLength: 500,
          ),
          const SizedBox(height: AppSpacing.xl),

          // Interests
          Text(
            _tr('create_profile.interests_title'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _tr('create_profile.interests_subtitle'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.slate,
                ),
          ),
          const SizedBox(height: AppSpacing.md),

          _buildInterestsGrid(),
          const SizedBox(height: AppSpacing.xl),

          // Relationship type
          Text(
            _tr('create_profile.relationship_title'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.md),

          _buildRelationshipTypeSelector(),
        ],
      ),
    );
  }

  Widget _buildLocationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _tr('create_profile.location_title'),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _tr('create_profile.location_subtitle'),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.slate,
                ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Location button
          if (_currentPosition == null && !_isLoadingLocation)
            AppButton(
              onPressed: _getCurrentLocation,
              text: _tr('create_profile.use_current_location'),
              icon: Icons.location_on,
              type: ButtonType.secondary,
            ),

          if (_isLoadingLocation)
            const Center(
              child: CircularProgressIndicator(),
            ),

          const SizedBox(height: AppSpacing.lg),

          // Manual input
          AppTextField(
            controller: _cityController,
            label: _tr('profile.city'),
            hintText: _tr('create_profile.city_hint'),
            prefixIcon: Icons.location_city,
          ),
          const SizedBox(height: AppSpacing.lg),

          AppTextField(
            controller: _countryController,
            label: _tr('profile.country'),
            hintText: _tr('create_profile.country_hint'),
            prefixIcon: Icons.flag,
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _tr('create_profile.preferences_title'),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _tr('create_profile.preferences_subtitle'),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.slate,
                ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Gender preferences
          Text(
            _tr('create_profile.gender_title'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.md),

          _buildGenderSelector(),
          const SizedBox(height: AppSpacing.xl),

          // Age range
          Text(
            _tr('create_profile.age_range_title'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _tr(
              'create_profile.age_range_value',
              params: {
                'min': '${_ageRange.start.round()}',
                'max': '${_ageRange.end.round()}',
              },
            ),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
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
          const SizedBox(height: AppSpacing.xl),

          // Distance
          Text(
            _tr('create_profile.distance_title'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _tr(
              'create_profile.distance_value',
              params: {'distance': '${_maxDistance.round()}'},
            ),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Slider(
            value: _maxDistance,
            min: 5,
            max: 100,
            divisions: 19,
            activeColor: AppColors.primaryPurple,
            inactiveColor: AppColors.platinum,
            onChanged: (value) {
              setState(() {
                _maxDistance = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsGrid() {
    final interests = [
      _tr('interest.sport'),
      _tr('interest.music'),
      _tr('interest.cinema'),
      _tr('interest.travel'),
      _tr('interest.cooking'),
      _tr('interest.art'),
      _tr('interest.nature'),
      _tr('interest.technology'),
      _tr('interest.reading'),
      _tr('interest.photography'),
      _tr('interest.yoga'),
      _tr('interest.meditation'),
      _tr('interest.dance'),
      _tr('interest.gaming'),
      _tr('interest.fashion'),
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: interests.map((interest) {
        final isSelected = _selectedInterests.contains(interest);
        return ChoiceChip(
          label: Text(interest),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected && _selectedInterests.length < 3) {
                _selectedInterests.add(interest);
              } else if (!selected) {
                _selectedInterests.remove(interest);
              }
            });
          },
          selectedColor: AppColors.primaryPurple,
          backgroundColor: AppColors.platinum,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.charcoal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRelationshipTypeSelector() {
    final types = [
      (RelationshipType.friendship, _tr('profile.relationship_friendship')),
      (RelationshipType.longTerm, _tr('profile.relationship_long_term')),
      (RelationshipType.shortTerm, _tr('profile.relationship_short_term')),
      (RelationshipType.casualDating, _tr('profile.relationship_casual')),
    ];

    return Column(
      children: types.map((type) {
        return RadioListTile<String>(
          title: Text(type.$2),
          value: type.$1,
          groupValue: _selectedRelationshipType,
          onChanged: (value) {
            setState(() {
              _selectedRelationshipType = value!;
            });
          },
          activeColor: AppColors.primaryPurple,
        );
      }).toList(),
    );
  }

  Widget _buildGenderSelector() {
    // 3 options simplifiées : Tout le monde, Hommes, Femmes
    final genders = [
      ('all', _tr('gender.all'), Icons.people),
      (Gender.male, Gender.getLabel(Gender.male), Icons.male),
      (Gender.female, Gender.getLabel(Gender.female), Icons.female),
    ];

    return Column(
      children: genders.map((gender) {
        final isSelected = _selectedGenders.contains(gender.$1);
        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: ListTile(
            leading: Icon(
              gender.$3,
              color: isSelected ? AppColors.primaryPurple : AppColors.slate,
            ),
            title: Text(
              gender.$2,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primaryPurple : null,
              ),
            ),
            trailing: isSelected
                ? const Icon(Icons.check_circle, color: AppColors.primaryPurple)
                : const Icon(Icons.circle_outlined, color: AppColors.slate),
            onTap: () {
              setState(() {
                _selectedGenders.clear();
                _selectedGenders.add(gender.$1);
              });
            },
          ),
        );
      }).toList(),
    );
  }

  String _tr(String key, {Map<String, dynamic>? params}) =>
      LocalizationService.translate(key, params: params);
}
