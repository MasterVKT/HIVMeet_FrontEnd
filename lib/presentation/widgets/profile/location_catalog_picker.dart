import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/domain/entities/location_catalog.dart';
import 'package:hivmeet/domain/repositories/profile_repository.dart';

/// A manual location picker backed exclusively by the versioned GeoNames API.
///
/// It never turns free text into a location.  A country must first be selected
/// from the server catalogue, then a city from that country's result set.
class LocationCatalogPicker extends StatefulWidget {
  const LocationCatalogPicker({
    super.key,
    required this.repository,
    required this.onCityChanged,
    this.initialCountryCode,
    this.initialCountryLabel,
    this.initialCity,
  });

  final ProfileRepository repository;
  final ValueChanged<LocationCity?> onCityChanged;
  final String? initialCountryCode;
  final String? initialCountryLabel;
  final LocationCity? initialCity;

  @override
  State<LocationCatalogPicker> createState() => _LocationCatalogPickerState();
}

class _LocationCatalogPickerState extends State<LocationCatalogPicker> {
  static const _debounceDelay = Duration(milliseconds: 300);

  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  Timer? _countryDebounce;
  Timer? _cityDebounce;
  int _countryRequest = 0;
  int _cityRequest = 0;

  List<LocationCountry> _countries = const <LocationCountry>[];
  List<LocationCity> _cities = const <LocationCity>[];
  String? _countryCode;
  LocationCity? _city;
  bool _loadingCountries = false;
  bool _loadingCities = false;
  bool _countriesFailed = false;
  bool _citiesFailed = false;

  @override
  void initState() {
    super.initState();
    _countryCode = widget.initialCountryCode;
    _city = widget.initialCity;
    _countryController.text = widget.initialCountryLabel ?? '';
    _cityController.text = widget.initialCity?.name ?? '';
    if (_countryCode != null) {
      _searchCities(immediate: true);
    }
  }

  @override
  void dispose() {
    _countryDebounce?.cancel();
    _cityDebounce?.cancel();
    _countryController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _onCountryQueryChanged(String _) {
    // Invalidate an in-flight response immediately, before the debounce ends.
    _countryRequest++;
    _countryCode = null;
    _city = null;
    _cities = const <LocationCity>[];
    _cityController.clear();
    widget.onCityChanged(null);
    _countryDebounce?.cancel();
    _countryDebounce = Timer(_debounceDelay, _searchCountries);
    setState(() {});
  }

  void _onCityQueryChanged(String _) {
    // Invalidate an in-flight response immediately, before the debounce ends.
    _cityRequest++;
    _city = null;
    widget.onCityChanged(null);
    _cityDebounce?.cancel();
    _cityDebounce = Timer(_debounceDelay, _searchCities);
    setState(() {});
  }

  Future<void> _searchCountries({bool immediate = false}) async {
    if (!immediate && _countryController.text.trim().isEmpty) {
      if (mounted) setState(() => _countries = const <LocationCountry>[]);
      return;
    }
    final request = ++_countryRequest;
    setState(() {
      _loadingCountries = true;
      _countriesFailed = false;
    });
    final result = await widget.repository.getLocationCountries(
      query: _countryController.text.trim(),
    );
    if (!mounted || request != _countryRequest) return;
    result.fold(
      (_) => setState(() {
        _loadingCountries = false;
        _countriesFailed = true;
      }),
      (countries) => setState(() {
        _loadingCountries = false;
        _countries = countries;
      }),
    );
  }

  Future<void> _searchCities({bool immediate = false}) async {
    final countryCode = _countryCode;
    if (countryCode == null) return;
    final request = ++_cityRequest;
    setState(() {
      _loadingCities = true;
      _citiesFailed = false;
    });
    final result = await widget.repository.getLocationCities(
      countryCode: countryCode,
      query: _cityController.text.trim(),
    );
    if (!mounted || request != _cityRequest || countryCode != _countryCode) {
      return;
    }
    result.fold(
      (_) => setState(() {
        _loadingCities = false;
        _citiesFailed = true;
      }),
      (cities) => setState(() {
        _loadingCities = false;
        _cities = cities;
      }),
    );
  }

  void _selectCountry(LocationCountry country) {
    _countryDebounce?.cancel();
    setState(() {
      _countryCode = country.code;
      _countryController.text = country.label;
      _countries = const <LocationCountry>[];
      _city = null;
      _cityController.clear();
      _cities = const <LocationCity>[];
    });
    widget.onCityChanged(null);
    _searchCities(immediate: true);
  }

  void _selectCity(LocationCity city) {
    _cityDebounce?.cancel();
    setState(() {
      _city = city;
      _cityController.text = city.name;
      _cities = const <LocationCity>[];
    });
    widget.onCityChanged(city);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextFormField(
          controller: _countryController,
          textInputAction: TextInputAction.next,
          onTap: () {
            if (_countries.isEmpty && !_loadingCountries) {
              _searchCountries(immediate: true);
            }
          },
          onChanged: _onCountryQueryChanged,
          decoration: InputDecoration(
            labelText: _tr('profile.country'),
            hintText: _tr('profile.location_search_country'),
            suffixIcon: _loadingCountries
                ? const _InlineProgress()
                : _countryController.text.isNotEmpty
                    ? IconButton(
                        tooltip: _tr('common.clear'),
                        onPressed: () => _onCountryQueryChanged(
                          _countryController.text = '',
                        ),
                        icon: const Icon(Icons.clear),
                      )
                    : null,
          ),
        ),
        _countryResults(),
        const SizedBox(height: 12),
        TextFormField(
          controller: _cityController,
          enabled: _countryCode != null,
          textInputAction: TextInputAction.done,
          onTap: () {
            if (_countryCode != null && _cities.isEmpty && !_loadingCities) {
              _searchCities(immediate: true);
            }
          },
          onChanged: _onCityQueryChanged,
          decoration: InputDecoration(
            labelText: _tr('profile.city'),
            hintText: _tr('profile.location_search_city'),
            suffixIcon: _loadingCities ? const _InlineProgress() : null,
          ),
        ),
        _cityResults(),
        if (_city != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('${_city!.name}, ${_city!.countryName}'),
          ),
      ],
    );
  }

  Widget _countryResults() {
    if (_countriesFailed) {
      return _RetryRow(onRetry: _searchCountries);
    }
    if (!_loadingCountries &&
        _countryCode == null &&
        _countryController.text.trim().isNotEmpty &&
        _countries.isEmpty) {
      return _EmptyResult(text: _tr('profile.location_no_country_results'));
    }
    return _ResultList<LocationCountry>(
      items: _countries,
      label: (country) => country.label,
      onSelected: _selectCountry,
    );
  }

  Widget _cityResults() {
    if (_citiesFailed) {
      return _RetryRow(onRetry: _searchCities);
    }
    if (_countryCode != null &&
        _city == null &&
        !_loadingCities &&
        _cityController.text.trim().isNotEmpty &&
        _cities.isEmpty) {
      return _EmptyResult(text: _tr('profile.location_no_city_results'));
    }
    return _ResultList<LocationCity>(
      items: _cities,
      label: (city) => city.name,
      onSelected: _selectCity,
    );
  }
}

class _ResultList<T> extends StatelessWidget {
  const _ResultList({
    required this.items,
    required this.label,
    required this.onSelected,
  });

  final List<T> items;
  final String Function(T item) label;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 192),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: items.length,
          itemBuilder: (context, index) => ListTile(
            dense: true,
            title: Text(label(items[index]),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () => onSelected(items[index]),
          ),
        ),
      ),
    );
  }
}

class _InlineProgress extends StatelessWidget {
  const _InlineProgress();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
}

class _RetryRow extends StatelessWidget {
  const _RetryRow({required this.onRetry});

  final Future<void> Function({bool immediate}) onRetry;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => onRetry(immediate: true),
          icon: const Icon(Icons.refresh),
          label: Text(_tr('common.retry')),
        ),
      );
}

class _EmptyResult extends StatelessWidget {
  const _EmptyResult({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(text, style: Theme.of(context).textTheme.bodySmall),
      );
}

String _tr(String key) => LocalizationService.translate(key);
