// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_places_platform_interface/google_maps_places_platform_interface.dart';

import 'page.dart';

class AutoCompletePage extends PlacesExampleAppPage {
  const AutoCompletePage({Key? key})
      : super(const Icon(Icons.search), 'Places Autocomplete', key: key);

  @override
  Widget build(BuildContext context) {
    return const AutoCompleteBody();
  }
}

class AutoCompleteBody extends StatefulWidget {
  const AutoCompleteBody({super.key});

  @override
  State<StatefulWidget> createState() => _MyAutoCompleteBodyState();
}

class _MyAutoCompleteBodyState extends State<AutoCompleteBody> {
  final GoogleMapsPlacesPlatform _places = GoogleMapsPlacesPlatform.instance;

  String _query = '';
  List<String> _countries = <String>['fi'];
  TypeFilter _typeFilter = TypeFilter.address;

  final LatLng _origin = const LatLng(65.0121, 25.4651);

  final LatLngBounds _locationBias = LatLngBounds(
    southwest: const LatLng(60.4518, 22.2666),
    northeast: const LatLng(70.0821, 27.8718),
  );

  bool _findingPlaces = false;
  dynamic _error;

  List<AutocompletePrediction> _results = <AutocompletePrediction>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildBody());
  }

  Widget _buildBody() {
    final List<Widget> widgets = _buildQueryWidgets() + _buildResultWidgets();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(children: widgets),
    );
  }

  void _onPlaceTypeFilterChanged(TypeFilter? value) {
    if (value != null) {
      setState(() {
        _typeFilter = value;
      });
    }
  }

  String? _countriesValidator(String? input) {
    if (input == null || input.isEmpty) {
      return null;
    }

    return input
        .split(',')
        .map((String countryPart) => countryPart.trim())
        .map((String countryPart) {
          if (countryPart.length != 2) {
            return "Use two-letter country codes splitted by ','";
          }
          return null;
        })
        .where((String? item) => item != null)
        .firstOrNull;
  }

  void _onCountriesTextChanged(String countries) {
    _countries = (countries == '')
        ? <String>[]
        : countries
            .split(',')
            .map((String item) => item.trim())
            .toList(growable: false);
  }

  void _findAction() {
    if (_findingPlaces || _query.isEmpty) {
      return;
    }
    setState(() {
      _findingPlaces = true;
      _results = <AutocompletePrediction>[];
      _error = null;
    });
    _findPlacesAutoComplete();
  }

  Future<void> _findPlacesAutoComplete() async {
    try {
      final List<AutocompletePrediction> result =
          await _places.findAutocompletePredictions(
              query: _query,
              countries: _countries,
              typeFilter: <TypeFilter>[_typeFilter],
              origin: _origin,
              locationBias: _locationBias);

      setState(() {
        _results = result;
        _findingPlaces = false;
      });
    } catch (error) {
      setState(() {
        _error = error;
        _findingPlaces = false;
      });
    }
  }

  Widget _buildPredictionRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Container(
            padding: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
            child: Text(title)),
        Flexible(child: Text(value, textAlign: TextAlign.end))
      ],
    );
  }

  Widget _buildAutoPredictionItem(AutocompletePrediction? item) {
    if (item == null) {
      return Container();
    }
    return Column(children: <Widget>[
      _buildPredictionRow('FullText:', item.fullText),
      _buildPredictionRow('PrimaryText:', item.primaryText),
      _buildPredictionRow('SecondaryText:', item.secondaryText),
      _buildPredictionRow(
          'Distance:', '${(item.distanceMeters ?? 0) / 1000} km'),
      _buildPredictionRow('PlaceId:', item.placeId),
      _buildPredictionRow(
          'PlaceTypes:',
          item.placeTypes
              .map((PlaceType placeType) => placeType.name)
              .join(', ')),
      const Divider(thickness: 2),
    ]);
  }

  Widget _buildErrorWidget() {
    final ThemeData theme = Theme.of(context);
    final String errorText = _error == null ? '' : _error.toString();
    return Text(errorText,
        style: theme.textTheme.caption?.copyWith(color: theme.errorColor));
  }

  List<Widget> _buildQueryWidgets() {
    return <Widget>[
      TextFormField(
        onChanged: (String text) {
          _query = text;
        },
        decoration: const InputDecoration(label: Text('Query')),
      ),
      TextFormField(
        onChanged: _onCountriesTextChanged,
        decoration: const InputDecoration(label: Text('Countries')),
        validator: _countriesValidator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        initialValue: _countries.join(','),
      ),
      DropdownButton<TypeFilter>(
        items: TypeFilter.values
            .map((TypeFilter item) => DropdownMenuItem<TypeFilter>(
                value: item, child: Text(item.name)))
            .toList(growable: false),
        value: _typeFilter,
        onChanged: _onPlaceTypeFilterChanged,
      ),
      ElevatedButton(
        onPressed: _findAction,
        child: const Text('Find'),
      ),
      Container(padding: const EdgeInsets.only(top: 20))
    ];
  }

  List<Widget> _buildResultWidgets() {
    return <Widget>[
      if (_error != null)
        _buildErrorWidget()
      else if (!_findingPlaces)
        Column(
          children:
              _results.map(_buildAutoPredictionItem).toList(growable: false),
        )
      else
        const Center(child: CircularProgressIndicator()),
      const Image(
        image: AssetImage('assets/google_on_white.png'),
      ),
    ];
  }
}
