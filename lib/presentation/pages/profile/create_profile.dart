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
import 'package:hivmeet/presentation/widgets/common/app_button.dart';
import 'package:hivmeet/presentation/widgets/common/app_text_field.dart';
import 'package:hivmeet/presentation/widgets/dialogs/hiv_dialogs.dart';
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
      
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _currentPosition = position;
          _cityController.text = place.locality ?? '';
          _countryController.text = place.country ?? '';
        });
      }
    } catch (e) {
      HIVToast.showError(
        context: context,
        message: 'Impossible de récupérer votre localisation',
      );
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
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
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir de la galerie'),
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
              toolbarTitle: 'Recadrer la photo',
              toolbarColor: AppColors.primaryPurple,
              toolbarWidgetColor: Colors.white,
              activeControlsWidgetColor: AppColors.primaryPurple,
            ),
            IOSUiSettings(
              title: 'Recadrer la photo',
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
            message: 'Veuillez ajouter une photo',
          );
          return false;
        }
        return true;
      case 1:
        if (_bioController.text.isEmpty) {
          HIVToast.showError(
            context: context,
            message: 'Veuillez écrire une bio',
          );
          return false;
        }
        if (_selectedInterests.isEmpty) {
          HIVToast.showError(
            context: context,
            message: 'Veuillez sélectionner au moins un centre d\'intérêt',
          );
          return false;
        }
        return true;
      case 2:
        if (_cityController.text.isEmpty || _countryController.text.isEmpty) {
          HIVToast.showError(
            context: context,
            message: 'Veuillez indiquer votre localisation',
          );
          return false;
        }
        return true;
      case 3:
        if (_selectedGenders.isEmpty) {
          HIVToast.showError(
            context: context,
            message: 'Veuillez sélectionner au moins un genre',
          );
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _createProfile() {
    // TODO: Implémenter la création du profil avec les données collectées
    HIVToast.showSuccess(
      context: context,
      message: 'Profil créé avec succès !',
    );
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ProfileBloc>(),
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
                            onPressed: _previousStep,
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
                      'Étape ${_currentStep + 1} sur 4',
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
                  onPressed: _nextStep,
                  text: _currentStep < 3 ? 'Suivant' : 'Créer mon profil',
                  type: ButtonType.primary,
                ),
              ),
            ],
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
            'Ajoutez votre photo',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Choisissez une photo qui vous représente bien',
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
                            'Ajouter une photo',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
            'Parlez-nous de vous',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Qu\'est-ce qui vous rend unique ?',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.slate,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          
          // Bio
          AppTextField(
            controller: _bioController,
            label: 'Bio',
            hintText: 'Écrivez quelque chose sur vous...',
            maxLines: 5,
            maxLength: 500,
          ),
          const SizedBox(height: AppSpacing.xl),
          
          // Interests
          Text(
            'Centres d\'intérêt',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Sélectionnez jusqu\'à 3 centres d\'intérêt',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.slate,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          
          _buildInterestsGrid(),
          const SizedBox(height: AppSpacing.xl),
          
          // Relationship type
          Text(
            'Que recherchez-vous ?',
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
            'Où êtes-vous ?',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Votre localisation aide à trouver des personnes près de vous',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.slate,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          
          // Location button
          if (_currentPosition == null && !_isLoadingLocation)
            AppButton(
              onPressed: _getCurrentLocation,
              text: 'Utiliser ma localisation actuelle',
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
            label: 'Ville',
            hintText: 'Ex: Paris',
            prefixIcon: Icons.location_city,
          ),
          const SizedBox(height: AppSpacing.lg),
          
          AppTextField(
            controller: _countryController,
            label: 'Pays',
            hintText: 'Ex: France',
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
            'Vos préférences',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Qui souhaitez-vous rencontrer ?',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.slate,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          
          // Gender preferences
          Text(
            'Je recherche',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          
          _buildGenderSelector(),
          const SizedBox(height: AppSpacing.xl),
          
          // Age range
          Text(
            'Tranche d\'âge',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${_ageRange.start.round()} - ${_ageRange.end.round()} ans',
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
            'Distance maximale',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${_maxDistance.round()} km',
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
      'Sport', 'Musique', 'Cinéma', 'Voyage', 'Cuisine',
      'Art', 'Nature', 'Technologie', 'Lecture', 'Photographie',
      'Yoga', 'Méditation', 'Danse', 'Gaming', 'Mode',
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
      (RelationshipType.friendship, 'Amitié'),
      (RelationshipType.longTerm, 'Relation sérieuse'),
      (RelationshipType.shortTerm, 'Relation courte'),
      (RelationshipType.casualDating, 'Rencontres casual'),
      (RelationshipType.networking, 'Networking'),
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
    final genders = [
      (Gender.male, 'Homme'),
      (Gender.female, 'Femme'),
      (Gender.nonBinary, 'Non-binaire'),
      (Gender.transMale, 'Homme trans'),
      (Gender.transFemale, 'Femme trans'),
      (Gender.other, 'Autre'),
    ];
    
    return Column(
      children: genders.map((gender) {
        final isSelected = _selectedGenders.contains(gender.$1);
        return CheckboxListTile(
          title: Text(gender.$2),
          value: isSelected,
          onChanged: (value) {
            setState(() {
              if (value == true) {
                _selectedGenders.add(gender.$1);
              } else {
                _selectedGenders.remove(gender.$1);
              }
            });
          },
          activeColor: AppColors.primaryPurple,
        );
      }).toList(),
    );
  }
}