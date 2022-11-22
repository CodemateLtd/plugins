// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';

import 'package:flutter/material.dart';
import 'package:google_maps_places_platform_interface/google_maps_places_platform_interface.dart';

/// Title
const title = 'Flutter Google Places iOS SDK Example';

void main() {
  runApp(MyApp());
}

/// Main app
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: ThemeData(
        primaryColor: Colors.blueAccent,
      ),
      home: MyHomePage(),
    );
  }
}

/// Main home page
class MyHomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _places = GoogleMapsPlacesPlatform.instance;

  //
  String? _predictLastText;
  List<String> _countries = ['fi'];
  TypeFilter _placeTypeFilter = TypeFilter.address;

  final LatLngBounds _locationBias = LatLngBounds(
    southwest: const LatLng(60.4518, 22.2666),
    northeast: const LatLng(70.0821, 27.8718),
  );

  bool _predicting = false;
  dynamic _predictErr;

  List<AutocompletePrediction?>? _predictions;

  final TextEditingController _fetchPlaceIdController = TextEditingController();

  bool _fetching = false;
  dynamic _fetchingErr;

  late Future<void> _loading;

  @override
  void initState() {
    super.initState();
    _loading = init();
  }

  Future<bool> init() => Future.delayed(
        const Duration(seconds: 1),
        () => true,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text(title)),
        body: FutureBuilder(
          future: _loading,
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasError) {
                return Center(child: Text(snapshot.error?.toString() ?? "N/A"));
              }

              return _buildBody();
            }

            return Center(child: CircularProgressIndicator());
          },
        ));
  }

  Widget _buildBody() {
    final predictionsWidgets = _buildPredictionWidgets();

    return Padding(
      padding: EdgeInsets.all(30),
      child: ListView(children: predictionsWidgets),
    );
  }

  void _onPlaceTypeFilterChanged(TypeFilter? value) {
    if (value != null) {
      setState(() {
        _placeTypeFilter = value;
      });
    }
  }

  String? _countriesValidator(String? input) {
    if (input == null || input.length == 0) {
      return null; // valid
    }

    return input
        .split(",")
        .map((part) => part.trim())
        .map((part) {
          if (part.length != 2) {
            return "Country part '${part}' must be 2 characters";
          }
          return null;
        })
        .where((item) => item != null)
        .firstOrNull;
  }

  void _onCountriesTextChanged(String countries) {
    _countries = (countries == "")
        ? []
        : countries
            .split(",")
            .map((item) => item.trim())
            .toList(growable: false);
  }

  void _onPredictTextChanged(String value) {
    _predictLastText = value;
  }

  void _predict() async {
    if (_predicting) {
      return;
    }

    final hasContent = _predictLastText?.isNotEmpty ?? false;

    setState(() {
      _predicting = hasContent;
      _predictErr = null;
    });

    if (!hasContent) {
      return;
    }
    try {
      final List<AutocompletePrediction> result =
          await _places.findAutocompletePredictions(
              query: _predictLastText!,
              countries: _countries,
              origin: const LatLng(65.0121, 25.4651),
              locationBias: _locationBias);

      setState(() {
        _predictions = result;
        _predicting = false;
      });
    } catch (err) {
      setState(() {
        _predictErr = err;
        _predicting = false;
      });
    }
  }

  void _onItemClicked(AutocompletePrediction? item) {
    if (item != null) {
      _fetchPlaceIdController.text = item.placeId;
    }
  }

  Widget _buildPredictionItem(AutocompletePrediction? item) {
    if (item == null) {
      return Container();
    }
    return InkWell(
      onTap: () => _onItemClicked(item),
      child: Column(children: [
        Text(item.fullText),
        Text(item.primaryText + ' - ' + item.secondaryText),
        const Divider(thickness: 2),
      ]),
    );
  }

  Widget _buildErrorWidget(dynamic err) {
    final theme = Theme.of(context);
    final errorText = err == null ? '' : err.toString();
    return Text(errorText,
        style: theme.textTheme.caption?.copyWith(color: theme.errorColor));
  }

  List<Widget> _buildPredictionWidgets() {
    return [
      // --
      TextFormField(
        onChanged: _onPredictTextChanged,
        decoration: InputDecoration(label: Text("Query")),
      ),
      // _countries
      TextFormField(
        onChanged: _onCountriesTextChanged,
        decoration: InputDecoration(label: Text("Countries")),
        validator: _countriesValidator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        initialValue: _countries.join(","),
      ),
      DropdownButton<TypeFilter>(
        items: TypeFilter.values
            .map((item) => DropdownMenuItem<TypeFilter>(
                child: Text(item.name), value: item))
            .toList(growable: false),
        value: _placeTypeFilter,
        onChanged: _onPlaceTypeFilterChanged,
      ),
      ElevatedButton(
        onPressed: _predicting == true ? null : _predict,
        child: const Text('Predict'),
      ),

      // -- Error widget + Result
      _buildErrorWidget(_predictErr),
      Column(
        mainAxisSize: MainAxisSize.min,
        children: (_predictions ?? [])
            .map(_buildPredictionItem)
            .toList(growable: false),
      ),
      /*Image(
        image: GoogleMapsPlacesPlatform.ASSET_POWERED_BY_GOOGLE_ON_WHITE,
      ),*/
    ];
  }
}
