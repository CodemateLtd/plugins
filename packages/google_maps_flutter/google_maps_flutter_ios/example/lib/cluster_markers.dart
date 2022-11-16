// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs
// ignore_for_file: unawaited_futures

import 'package:flutter/material.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

import 'example_google_map.dart';
import 'page.dart';

class ClusterMarkersPage extends GoogleMapExampleAppPage {
  const ClusterMarkersPage({Key? key})
      : super(const Icon(Icons.hive), 'Cluster markers', key: key);

  @override
  Widget build(BuildContext context) {
    return const ClusterMarkersBody();
  }
}

class ClusterMarkersBody extends StatefulWidget {
  const ClusterMarkersBody({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => ClusterMarkersBodyState();
}

const LatLng _kMapCenter = LatLng(52.4278, -3.5202);

Set<Marker> markers = {
  const Marker(
    clusterManagerId: ClusterManagerId('cluster1'),
    markerId: MarkerId('marker1'),
    position: LatLng(52.0078, -3.5802),
  ),
  const Marker(
    clusterManagerId: ClusterManagerId('cluster1'),
    markerId: MarkerId('marker2'),
    position: LatLng(52.8478, -3.0002),
  ),
  const Marker(
    clusterManagerId: ClusterManagerId('cluster1'),
    markerId: MarkerId('marker3'),
    position: LatLng(52.0078, -3.0002),
  ),
  const Marker(
    clusterManagerId: ClusterManagerId('cluster1'),
    markerId: MarkerId('marker4'),
    position: LatLng(52.8478, -3.5802),
  ),
  const Marker(
    markerId: MarkerId('marker5'),
    position: LatLng(52.9478, -3.6802),
  ),
};

const clusterIcon = Icon(Icons.adjust);
Set<ClusterManager> clusterManagers = {
  const ClusterManager(
    clusterManagerId: ClusterManagerId('cluster1'),
  ),
};

class ClusterMarkersBodyState extends State<ClusterMarkersBody> {
  ExampleGoogleMapController? controller;
  BitmapDescriptor? _markerIcon;

  @override
  Widget build(BuildContext context) {
    _createMarkerImageFromAsset(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Center(
          child: SizedBox(
            width: 350.0,
            height: 300.0,
            child: ExampleGoogleMap(
              initialCameraPosition: const CameraPosition(
                target: _kMapCenter,
                zoom: 7.0,
              ),
              markers: markers,
              clusterManagers: clusterManagers,
              onMapCreated: _onMapCreated,
            ),
          ),
        )
      ],
    );
  }

  Future<void> _createMarkerImageFromAsset(BuildContext context) async {
    if (_markerIcon == null) {
      final ImageConfiguration imageConfiguration =
          createLocalImageConfiguration(context, size: const Size.square(48));
      BitmapDescriptor.fromAssetImage(
              imageConfiguration, 'assets/red_square.png')
          .then(_updateBitmap);
    }
  }

  void _updateBitmap(BitmapDescriptor bitmap) {
    setState(() {
      _markerIcon = bitmap;
    });
  }

  void _onMapCreated(ExampleGoogleMapController controllerParam) {
    setState(() {
      controller = controllerParam;
    });
  }
}
