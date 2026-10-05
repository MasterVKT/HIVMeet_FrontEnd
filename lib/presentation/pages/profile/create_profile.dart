// lib/presentation/pages/profile/create_profile_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:hivmeet/injection.dart';
import 'package:hivmeet/presentation/blocs/profile/profile_bloc.dart';
import 'package:hivmeet/presentation/blocs/profile/profile_state.dart';
import 'package:hivmeet/presentation/blocs/profile/profile_event.dart';
import 'package:hivmeet/presentation/widgets/common/app_button.dart';
import 'package:hivmeet/presentation/widgets/common/app_text_field.dart';
import 'package:hivmeet/presentation/widgets/dialogs/hiv_dialogs.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/core/services/foreground_location_service.dart';
import 'package:hivmeet/domain/entities/location_catalog.dart';
import 'package:hivmeet/domain/entities/discovery_preference_catalog.dart';
import 'package:hivmeet/domain/repositories/profile_repository.dart';
import 'package:hivmeet/presentation/widgets/profile/location_catalog_picker.dart';

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

  // State
  File? _mainPhoto;
  final List<String> _selectedInterests = [];
  String _selectedRelationship = DiscoveryPreferenceCatalog.everyone;
  String _selectedGender = DiscoveryPreferenceCatalog.everyone;
  RangeValues _ageRange = const RangeValues(18, 50);
  double _maxDistance = 50;

  // Location
  double? _automaticLatitude;
  double? _automaticLongitude;
  bool _isLoadingLocation = false;
  final ProfileRepository _profileRepository = getIt<ProfileRepository>();
  final ForegroundLocationService _locationService =
      const ForegroundLocationService();
  String? _countryCode;
  LocationCity? _city;
  ProfileLocationUpdate? _locationUpdate;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _bioController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final result = await _locationService.requestCurrentPosition();
      if (!mounted) return;
      if (result case ForegroundLocationReady()) {
        setState(() {
          _automaticLatitude = result.latitude;
          _automaticLongitude = result.longitude;
          _locationUpdate = ProfileLocationUpdate.automatic(
            latitude: result.latitude,
            longitude: result.longitude,
            accuracyMeters: result.accuracyMeters,
          );
        });
      } else {
        HIVToast.showWarning(
          context: context,
          message: _tr('profile.location_permission_denied'),
        );
      }
    } catch (_) {
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
        if (_locationUpdate == null) {
          HIVToast.showError(
            context: context,
            message: _tr('create_profile.error_location_required'),
          );
          return false;
        }
        return true;
      case 3:
        // An empty sought-gender list is the shared contract for “all”.
        return true;
      default:
        return true;
    }
  }

  void _createProfile() {
    if (_mainPhoto == null || _locationUpdate == null) {
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
      relationshipType: _selectedRelationship,
      relationshipTypesSought:
          DiscoveryPreferenceCatalog.relationshipPayload(_selectedRelationship),
      city: _city?.name ?? '',
      country: _city?.countryName ?? '',
      latitude: _automaticLatitude ?? 0,
      longitude: _automaticLongitude ?? 0,
      minAge: _ageRange.start.round(),
      maxAge: _ageRange.end.round(),
      maxDistance: _maxDistance,
      interestedIn: DiscoveryPreferenceCatalog.genderPayload(_selectedGender),
      locationUpdate: _locationUpdate,
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
          if (_locationUpdate == null && !_isLoadingLocation)
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

          Text(_tr('profile.manual_location')),
          const SizedBox(height: AppSpacing.sm),
          LocationCatalogPicker(
            repository: _profileRepository,
            initialCountryCode: _countryCode,
            initialCity: _city,
            onCityChanged: (city) => setState(() {
              _city = city;
              _countryCode = city?.countryCode;
              _locationUpdate = city == null
                  ? null
                  : ProfileLocationUpdate.manual(cityId: city.id);
            }),
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
    const types = <String>[
      DiscoveryPreferenceCatalog.everyone,
      ...DiscoveryPreferenceCatalog.relationshipValues,
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: types.map((type) {
        final isSelected = _selectedRelationship == type;
        return ChoiceChip(
          label: Text(_tr(
            DiscoveryPreferenceCatalog.relationshipLabelKey(type),
          )),
          selected: isSelected,
          selectedColor: AppColors.primaryPurple,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.charcoal,
          ),
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedRelationship = type;
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildGenderSelector() {
    const genders = <String>[
      DiscoveryPreferenceCatalog.everyone,
      ...DiscoveryPreferenceCatalog.genderValues,
    ];

    return Column(
      children: genders.map((gender) {
        final isSelected = _selectedGender == gender;
        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: ListTile(
            leading: Icon(
              gender == DiscoveryPreferenceCatalog.everyone
                  ? Icons.people
                  : Icons.person,
              color: isSelected ? AppColors.primaryPurple : AppColors.slate,
            ),
            title: Text(
              _tr(DiscoveryPreferenceCatalog.genderLabelKey(gender)),
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
                _selectedGender = gender;
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
