// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of google_maps_flutter_web;

/// An Android of implementation of [GoogleMapsInspectorPlatform].
@visibleForTesting
class GoogleMapsInspectorWeb extends GoogleMapsInspectorPlatform {
  /// Creates a method-channel-based inspector instance that gets the channel
  /// for a given map ID from [channelProvider].
  GoogleMapsInspectorWeb(GoogleMapController? Function(int mapId) mapProvider)
      : _mapProvider = mapProvider;

  final GoogleMapController? Function(int mapId) _mapProvider;

  @override
  Future<bool> areBuildingsEnabled({required int mapId}) async {
    return false;
  }

  @override
  Future<bool> areRotateGesturesEnabled({required int mapId}) async {
    return false;
  }

  @override
  Future<bool> areScrollGesturesEnabled({required int mapId}) async =>
     _mapProvider(mapId)!.gestureHandlingEnabled();
  
  @override
  Future<bool> areTiltGesturesEnabled({required int mapId}) async => false;

  @override
  Future<bool> areZoomControlsEnabled({required int mapId}) async => 
     _mapProvider(mapId)!.zoomEnabled();

  @override
  Future<bool> areZoomGesturesEnabled({required int mapId}) async  => 
     _mapProvider(mapId)!.gestureHandlingEnabled();

  @override
  Future<MinMaxZoomPreference> getMinMaxZoomLevels({required int mapId}) async =>
     _mapProvider(mapId)!.getMinMaxZoomLevels();
  
  @override
  Future<TileOverlay?> getTileOverlayInfo(TileOverlayId tileOverlayId,
      {required int mapId}) async => null;

  @override
  Future<bool> isCompassEnabled({required int mapId}) async => false;

  @override
  Future<bool> isLiteModeEnabled({required int mapId}) async => false;

  @override
  Future<bool> isMapToolbarEnabled({required int mapId}) async => false;

  @override
  Future<bool> isMyLocationButtonEnabled({required int mapId}) async => false;

  @override
  Future<bool> isTrafficEnabled({required int mapId}) async  => false;
}
