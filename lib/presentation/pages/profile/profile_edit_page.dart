import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/domain/entities/profile.dart';
import 'package:hivmeet/injection.dart';
import 'package:hivmeet/presentation/blocs/profile/profile_bloc.dart';
import 'package:hivmeet/presentation/blocs/profile/profile_event.dart';
import 'package:hivmeet/presentation/blocs/profile/profile_state.dart';
import 'package:hivmeet/presentation/widgets/common/hiv_toast.dart';
import 'package:hivmeet/presentation/widgets/loaders/hiv_loader.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _interestsController = TextEditingController();
  int _minAge = 18;
  int _maxAge = 50;
  int _distance = 50;
  List<String> _gendersSought = const [];
  List<String> _relationships = const [RelationshipType.friendship];
  bool _initialized = false;

  @override
  void dispose() {
    _bioController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _interestsController.dispose();
    super.dispose();
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
            context.go('/profile');
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
                  _field(
                    controller: _cityController,
                    label: _tr('profile.city'),
                    maxLength: 100,
                  ),
                  _field(
                    controller: _countryController,
                    label: _tr('profile.country'),
                    maxLength: 100,
                  ),
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
                    values: Gender.allOptions,
                    selected: _gendersSought,
                    labelFor: (value) => Gender.getLabel(value),
                    onChanged: (values) =>
                        setState(() => _gendersSought = values),
                  ),
                  _chips(
                    label: _tr('profile.relationships'),
                    values: RelationshipType.all,
                    selected: _relationships,
                    labelFor: _relationshipLabel,
                    onChanged: (values) =>
                        setState(() => _relationships = values),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _initFromProfile(Profile profile) {
    if (_initialized) return;
    _bioController.text = profile.bio;
    _cityController.text = profile.city;
    _countryController.text = profile.country;
    _interestsController.text = profile.interests.join(', ');
    _minAge = profile.searchPreferences.minAge;
    _maxAge = profile.searchPreferences.maxAge;
    _distance = profile.searchPreferences.maxDistance.round();
    _gendersSought = profile.searchPreferences.interestedIn;
    _relationships = profile.relationshipTypesSought.isNotEmpty
        ? profile.relationshipTypesSought
        : profile.searchPreferences.relationshipTypes;
    _initialized = true;
  }

  void _save(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    if (_minAge > _maxAge) {
      HIVToast.showError(context: context, message: _tr('profile.error_age'));
      return;
    }
    final interests = _parseInterests();
    context.read<ProfileBloc>().add(UpdateProfileEvent(
          bio: _bioController.text.trim(),
          city: _cityController.text.trim(),
          country: _countryController.text.trim(),
          interests: interests,
          relationshipTypesSought: _relationships,
          searchPreferences: SearchPreferences(
            minAge: _minAge,
            maxAge: _maxAge,
            maxDistance: _distance.toDouble(),
            interestedIn: _gendersSought,
            relationshipTypes: _relationships,
          ),
        ));
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

  List<String> _parseInterests() {
    return _interestsController.text
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }
}

Widget _field({
  required TextEditingController controller,
  required String label,
  String? helper,
  int? maxLength,
  int maxLines = 1,
  TextInputType keyboardType = TextInputType.text,
  String? Function(String?)? validator,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(labelText: label, helperText: helper),
    ),
  );
}

Widget _numberRow({
  required String label,
  required int min,
  required int max,
  required int first,
  required int second,
  required ValueChanged<int> onFirst,
  required ValueChanged<int> onSecond,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: first.toDouble(),
                min: min.toDouble(),
                max: max.toDouble(),
                divisions: max - min,
                label: '$first',
                onChanged: (value) => onFirst(value.round()),
              ),
            ),
            Text('$first - $second'),
            Expanded(
              child: Slider(
                value: second.toDouble(),
                min: min.toDouble(),
                max: max.toDouble(),
                divisions: max - min,
                label: '$second',
                onChanged: (value) => onSecond(value.round()),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _slider({
  required String label,
  required int value,
  required int min,
  required int max,
  required ValueChanged<int> onChanged,
}) {
  final unit = _tr('profile.distance_unit');
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: $value $unit'),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          label: '$value $unit',
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    ),
  );
}

Widget _chips({
  required String label,
  required List<String> values,
  required List<String> selected,
  required String Function(String) labelFor,
  required ValueChanged<List<String>> onChanged,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: values.map((value) {
            final active = selected.contains(value);
            return FilterChip(
              label: Text(labelFor(value)),
              selected: active,
              onSelected: (isSelected) {
                final next = [...selected];
                isSelected ? next.add(value) : next.remove(value);
                onChanged(next);
              },
            );
          }).toList(),
        ),
      ],
    ),
  );
}

String _relationshipLabel(String value) {
  switch (value) {
    case RelationshipType.longTerm:
      return _tr('profile.relationship_long_term');
    case RelationshipType.shortTerm:
      return _tr('profile.relationship_short_term');
    case RelationshipType.casualDating:
      return _tr('profile.relationship_casual');
    default:
      return _tr('profile.relationship_friendship');
  }
}

ProfileLoaded? _loadedFrom(ProfileState state) {
  if (state is ProfileLoaded) return state;
  if (state is ProfileActionSuccess) return state.loadedState;
  if (state is ProfileError) return state.loadedState;
  if (state is ProfileSectionLoading) return state.previousState;
  return null;
}

String _tr(String key) => LocalizationService.translate(key);
