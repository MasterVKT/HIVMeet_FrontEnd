import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/services/foreground_location_service.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/domain/entities/discovery_preference_catalog.dart';
import 'package:hivmeet/domain/entities/location_catalog.dart';
import 'package:hivmeet/domain/entities/profile.dart';
import 'package:hivmeet/domain/repositories/profile_repository.dart';
import 'package:hivmeet/injection.dart';
import 'package:hivmeet/presentation/blocs/profile/profile_bloc.dart';
import 'package:hivmeet/presentation/blocs/profile/profile_event.dart';
import 'package:hivmeet/presentation/blocs/profile/profile_state.dart';
import 'package:hivmeet/presentation/widgets/common/hiv_toast.dart';
import 'package:hivmeet/presentation/widgets/loaders/hiv_loader.dart';
import 'package:hivmeet/presentation/widgets/profile/location_catalog_picker.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  final _interestsController = TextEditingController();
  final ProfileRepository _repository = getIt<ProfileRepository>();
  final ForegroundLocationService _locationService =
      const ForegroundLocationService();

  int _minAge = 18;
  int _maxAge = 50;
  int _distance = 50;
  String _genderSought = DiscoveryPreferenceCatalog.everyone;
  String _relationship = DiscoveryPreferenceCatalog.everyone;
  String _gender = '';
  bool _requiresGenderConfirmation = false;
  bool _locationEnabled = true;
  bool _initialized = false;
  String? _countryCode;
  LocationCity? _city;
  ProfileLocationUpdate? _locationUpdate;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _bioController.dispose();
    _interestsController.dispose();
    super.dispose();
  }

  Future<void> _changeLocationEnabled(bool enabled) async {
    if (!enabled) {
      setState(() {
        _locationEnabled = false;
        _locationUpdate = _city == null
            ? const ProfileLocationUpdate.disabled()
            : ProfileLocationUpdate.manual(cityId: _city!.id);
      });
      return;
    }
    final result = await _locationService.requestCurrentPosition();
    if (!mounted) return;
    switch (result) {
      case ForegroundLocationReady():
        setState(() {
          _locationEnabled = true;
          _locationUpdate = ProfileLocationUpdate.automatic(
            latitude: result.latitude,
            longitude: result.longitude,
            accuracyMeters: result.accuracyMeters,
          );
        });
      case ForegroundLocationUnavailable():
        setState(() => _locationEnabled = false);
        final key = switch (result.reason) {
          ForegroundLocationFailure.serviceDisabled =>
            'profile.location_service_disabled',
          ForegroundLocationFailure.denied =>
            'profile.location_permission_denied',
          ForegroundLocationFailure.deniedForever =>
            'profile.location_permission_denied_forever',
        };
        HIVToast.showWarning(context: context, message: _tr(key));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProfileBloc>()..add(LoadProfile()),
      child: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileError) {
            HIVToast.showError(context: context, message: _tr(state.message));
          }
          if (state is ProfileActionSuccess) {
            HIVToast.showSuccess(context: context, message: _tr(state.message));
            if (context.canPop()) {
              context.pop<Profile>(state.profile);
            } else {
              // A direct link has no profile page in the stack. Returning to
              // the route reloads the confirmed server profile as fallback.
              context.go('/profile');
            }
          }
        },
        builder: (context, state) {
          final loaded = _loadedFrom(state);
          if (state is ProfileLoading || loaded == null) {
            return const Scaffold(body: Center(child: HIVLoader()));
          }
          _initFromProfile(loaded.profile);
          return Scaffold(
            backgroundColor: AppColors.primaryWhite,
            appBar: AppBar(
              title: Text(_tr('profile.edit_profile')),
              backgroundColor: AppColors.primaryWhite,
              actions: [
                TextButton(
                  onPressed: () => _save(context),
                  child: Text(_tr('common.save')),
                ),
              ],
            ),
            body: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.all(AppSpacing.md),
                children: [
                  _field(
                    controller: _bioController,
                    label: _tr('profile.bio'),
                    maxLength: AppLimits.maxBioLength,
                    maxLines: 5,
                    validator: (value) =>
                        (value?.length ?? 0) > AppLimits.maxBioLength
                            ? _tr('profile.error_bio')
                            : null,
                  ),
                  _identityGenderControl(),
                  _locationSection(),
                  _field(
                    controller: _interestsController,
                    label: _tr('profile.interests'),
                    helper: _tr('profile.interests_helper'),
                    validator: _validateInterests,
                  ),
                  _numberRow(
                    label: _tr('profile.age_range'),
                    min: 18,
                    max: 99,
                    first: _minAge,
                    second: _maxAge,
                    onFirst: (value) => setState(() => _minAge = value),
                    onSecond: (value) => setState(() => _maxAge = value),
                  ),
                  _slider(
                    label: _tr('profile.distance'),
                    value: _distance,
                    min: AppLimits.minDistance,
                    max: AppLimits.maxDistance,
                    onChanged: (value) => setState(() => _distance = value),
                  ),
                  _chips(
                    label: _tr('profile.genders_sought'),
                    values: const <String>[
                      DiscoveryPreferenceCatalog.everyone,
                      ...DiscoveryPreferenceCatalog.genderValues,
                    ],
                    selected: <String>[_genderSought],
                    labelFor: (value) => _tr(
                      DiscoveryPreferenceCatalog.genderLabelKey(value),
                    ),
                    onChanged: (values) => setState(() {
                      _genderSought = values.isEmpty
                          ? DiscoveryPreferenceCatalog.everyone
                          : values.single;
                    }),
                    singleChoice: true,
                  ),
                  _chips(
                    label: _tr('profile.relationships'),
                    values: const <String>[
                      DiscoveryPreferenceCatalog.everyone,
                      ...DiscoveryPreferenceCatalog.relationshipValues,
                    ],
                    selected: <String>[_relationship],
                    labelFor: (value) => _tr(
                      DiscoveryPreferenceCatalog.relationshipLabelKey(value),
                    ),
                    onChanged: (values) => setState(() {
                      _relationship = values.isEmpty
                          ? DiscoveryPreferenceCatalog.everyone
                          : values.single;
                    }),
                    singleChoice: true,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _locationSection() => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_tr('profile.location'),
                style: Theme.of(context).textTheme.titleMedium),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(_tr('profile.use_device_location')),
              subtitle: Text(_tr('profile.use_device_location_subtitle')),
              value: _locationEnabled,
              onChanged: _changeLocationEnabled,
            ),
            if (!_locationEnabled) ...[
              Text(_tr('profile.manual_location')),
              const SizedBox(height: 8),
              LocationCatalogPicker(
                repository: _repository,
                initialCountryCode: _countryCode,
                initialCountryLabel: _city?.countryName,
                initialCity: _city,
                onCityChanged: (city) => setState(() {
                  _city = city;
                  _countryCode = city?.countryCode;
                  _locationUpdate = city == null
                      ? const ProfileLocationUpdate.disabled()
                      : ProfileLocationUpdate.manual(cityId: city.id);
                }),
              ),
            ],
          ],
        ),
      );

  void _initFromProfile(Profile profile) {
    if (_initialized) return;
    _bioController.text = profile.bio;
    _interestsController.text = profile.interests.join(', ');
    _minAge = profile.searchPreferences.minAge;
    _maxAge = profile.searchPreferences.maxAge;
    _distance = profile.searchPreferences.maxDistance.round();
    _genderSought = DiscoveryPreferenceCatalog.genderSelection(
      profile.searchPreferences.interestedIn,
    );
    _relationship = DiscoveryPreferenceCatalog.relationshipSelection(
      profile.relationshipTypesSought.isNotEmpty
          ? profile.relationshipTypesSought
          : profile.searchPreferences.relationshipTypes,
    );
    _gender = profile.gender;
    _requiresGenderConfirmation = profile.genderConfirmationRequired;
    _locationEnabled = profile.locationEnabled;
    _countryCode = profile.countryCode;
    if (profile.geoCityId != null) {
      _city = LocationCity(
        id: profile.geoCityId!,
        name: profile.city,
        countryCode: profile.countryCode ?? '',
        countryName: profile.country,
      );
    }
    _initialized = true;
  }

  void _save(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    if (_minAge > _maxAge) {
      HIVToast.showError(context: context, message: _tr('profile.error_age'));
      return;
    }
    if (_requiresGenderConfirmation &&
        !DiscoveryPreferenceCatalog.genderValues.contains(_gender)) {
      HIVToast.showError(
        context: context,
        message: _tr('profile.gender_confirmation_required'),
      );
      return;
    }
    if (!_locationEnabled && _city == null) {
      HIVToast.showError(
          context: context, message: _tr('profile.location_city_required'));
      return;
    }
    final locationUpdate = _locationEnabled
        ? _locationUpdate
        : ProfileLocationUpdate.manual(cityId: _city!.id);
    context.read<ProfileBloc>().add(UpdateProfileEvent(
          bio: _bioController.text.trim(),
          gender: _requiresGenderConfirmation ? _gender : null,
          interests: _parseInterests(),
          relationshipTypesSought:
              DiscoveryPreferenceCatalog.relationshipPayload(_relationship),
          locationUpdate: locationUpdate,
          searchPreferences: SearchPreferences(
            minAge: _minAge,
            maxAge: _maxAge,
            maxDistance: _distance.toDouble(),
            interestedIn:
                DiscoveryPreferenceCatalog.genderPayload(_genderSought),
            relationshipTypes:
                DiscoveryPreferenceCatalog.relationshipPayload(_relationship),
          ),
        ));
  }

  Widget _identityGenderControl() {
    if (_requiresGenderConfirmation) {
      return _chips(
        label: _tr('profile.gender_confirmation_title'),
        values: DiscoveryPreferenceCatalog.genderValues,
        selected: _gender.isEmpty ? const <String>[] : <String>[_gender],
        labelFor: (value) =>
            _tr(DiscoveryPreferenceCatalog.genderLabelKey(value)),
        onChanged: (values) => setState(
          () => _gender = values.isEmpty ? '' : values.single,
        ),
        singleChoice: true,
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.lock_outline),
        title: Text(_tr('profile.gender')),
        subtitle: Text(_tr('profile.gender_locked_subtitle')),
        trailing: Text(
          _tr(DiscoveryPreferenceCatalog.genderLabelKey(_gender)),
        ),
      ),
    );
  }

  String? _validateInterests(String? value) {
    final interests = _parseInterests();
    if (interests.length > AppLimits.maxInterests) {
      return _tr('profile.error_interests_count');
    }
    if (interests.any((item) => item.length > 50)) {
      return _tr('profile.error_interest_length');
    }
    return null;
  }

  List<String> _parseInterests() => _interestsController.text
      .split(',')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList();
}

Widget _field({
  required TextEditingController controller,
  required String label,
  String? helper,
  int? maxLength,
  int maxLines = 1,
  String? Function(String?)? validator,
}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLength: maxLength,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(labelText: label, helperText: helper),
      ),
    );

Widget _numberRow({
  required String label,
  required int min,
  required int max,
  required int first,
  required int second,
  required ValueChanged<int> onFirst,
  required ValueChanged<int> onSecond,
}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label),
        Row(children: [
          Expanded(
              child: Slider(
                  value: first.toDouble(),
                  min: min.toDouble(),
                  max: max.toDouble(),
                  divisions: max - min,
                  onChanged: (value) => onFirst(value.round()))),
          Text('$first - $second'),
          Expanded(
              child: Slider(
                  value: second.toDouble(),
                  min: min.toDouble(),
                  max: max.toDouble(),
                  divisions: max - min,
                  onChanged: (value) => onSecond(value.round()))),
        ]),
      ]),
    );

Widget _slider({
  required String label,
  required int value,
  required int min,
  required int max,
  required ValueChanged<int> onChanged,
}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$label: $value ${_tr('profile.distance_unit')}'),
        Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            onChanged: (v) => onChanged(v.round())),
      ]),
    );

Widget _chips({
  required String label,
  required List<String> values,
  required List<String> selected,
  required String Function(String) labelFor,
  required ValueChanged<List<String>> onChanged,
  bool singleChoice = false,
}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label),
        const SizedBox(height: 8),
        Wrap(
            spacing: 8,
            runSpacing: 4,
            children: values.map((value) {
              final active = selected.contains(value);
              return FilterChip(
                label: Text(labelFor(value)),
                selected: active,
                onSelected: (isSelected) {
                  final next = singleChoice ? <String>[] : [...selected];
                  if (isSelected) next.add(value);
                  onChanged(next);
                },
              );
            }).toList()),
      ]),
    );

ProfileLoaded? _loadedFrom(ProfileState state) {
  if (state is ProfileLoaded) return state;
  if (state is ProfileActionSuccess) return state.loadedState;
  if (state is ProfileError) return state.loadedState;
  if (state is ProfileSectionLoading) return state.previousState;
  return null;
}

String _tr(String key) => LocalizationService.translate(key);
