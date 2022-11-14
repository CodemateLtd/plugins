// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
// TODO(a14n): remove this import once Flutter 3.1 or later reaches stable (including flutter/flutter#104231)
// ignore: unnecessary_import
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:stream_transform/stream_transform.dart';

import 'google_map_inspector_ios.dart';

// TODO(stuartmorgan): Remove the dependency on platform interface toJson
// methods. Channel serialization details should all be package-internal.

/// Error thrown when an unknown map ID is provided to a method channel API.
class UnknownMapIDError extends Error {
  /// Creates an assertion error with the provided [mapId] and optional
  /// [message].
  UnknownMapIDError(this.mapId, [this.message]);

  /// The unknown ID.
  final int mapId;

  /// Message describing the assertion error.
  final Object? message;

  @override
  String toString() {
    if (message != null) {
      return 'Unknown map ID $mapId: ${Error.safeToString(message)}';
    }
    return 'Unknown map ID $mapId';
  }
}

/// An implementation of [GoogleMapsFlutterPlatform] for iOS.
class GoogleMapsFlutterIOS extends GoogleMapsFlutterPlatform {
  /// Registers the iOS implementation of GoogleMapsFlutterPlatform.
  static void registerWith() {
    GoogleMapsFlutterPlatform.instance = GoogleMapsFlutterIOS();
  }

  // Keep a collection of id -> channel
  // Every method call passes the int mapId
  final Map<int, MethodChannel> _channels = <int, MethodChannel>{};

  /// Accesses the MethodChannel associated to the passed mapId.
  MethodChannel _channel(int mapId) {
    final MethodChannel? channel = _channels[mapId];
    if (channel == null) {
      throw UnknownMapIDError(mapId);
    }
    return channel;
  }

  // Keep a collection of mapId to a map of TileOverlays.
  final Map<int, Map<TileOverlayId, TileOverlay>> _tileOverlays =
      <int, Map<TileOverlayId, TileOverlay>>{};

  /// Returns the channel for [mapId], creating it if it doesn't already exist.
  @visibleForTesting
  MethodChannel ensureChannelInitialized(int mapId) {
    MethodChannel? channel = _channels[mapId];
    if (channel == null) {
      channel = MethodChannel('plugins.flutter.dev/google_maps_ios_$mapId');
      channel.setMethodCallHandler(
          (MethodCall call) => _handleMethodCall(call, mapId));
      _channels[mapId] = channel;
    }
    return channel;
  }

  @override
  Future<void> init(int mapId) {
    final MethodChannel channel = ensureChannelInitialized(mapId);
    return channel.invokeMethod<void>('map#waitForMap');
  }

  @override
  void dispose({required int mapId}) {
    // Noop!
  }

  // The controller we need to broadcast the different events coming
  // from handleMethodCall.
  //
  // It is a `broadcast` because multiple controllers will connect to
  // different stream views of this Controller.
  final StreamController<MapEvent<Object?>> _mapEventStreamController =
      StreamController<MapEvent<Object?>>.broadcast();

  // Returns a filtered view of the events in the _controller, by mapId.
  Stream<MapEvent<Object?>> _events(int mapId) =>
      _mapEventStreamController.stream
          .where((MapEvent<Object?> event) => event.mapId == mapId);

  @override
  Stream<CameraMoveStartedEvent> onCameraMoveStarted({required int mapId}) {
    return _events(mapId).whereType<CameraMoveStartedEvent>();
  }

  @override
  Stream<CameraMoveEvent> onCameraMove({required int mapId}) {
    return _events(mapId).whereType<CameraMoveEvent>();
  }

  @override
  Stream<CameraIdleEvent> onCameraIdle({required int mapId}) {
    return _events(mapId).whereType<CameraIdleEvent>();
  }

  @override
  Stream<MarkerTapEvent> onMarkerTap({required int mapId}) {
    return _events(mapId).whereType<MarkerTapEvent>();
  }

  @override
  Stream<InfoWindowTapEvent> onInfoWindowTap({required int mapId}) {
    return _events(mapId).whereType<InfoWindowTapEvent>();
  }

  @override
  Stream<MarkerDragStartEvent> onMarkerDragStart({required int mapId}) {
    return _events(mapId).whereType<MarkerDragStartEvent>();
  }

  @override
  Stream<MarkerDragEvent> onMarkerDrag({required int mapId}) {
    return _events(mapId).whereType<MarkerDragEvent>();
  }

  @override
  Stream<MarkerDragEndEvent> onMarkerDragEnd({required int mapId}) {
    return _events(mapId).whereType<MarkerDragEndEvent>();
  }

  @override
  Stream<PolylineTapEvent> onPolylineTap({required int mapId}) {
    return _events(mapId).whereType<PolylineTapEvent>();
  }

  @override
  Stream<PolygonTapEvent> onPolygonTap({required int mapId}) {
    return _events(mapId).whereType<PolygonTapEvent>();
  }

  @override
  Stream<CircleTapEvent> onCircleTap({required int mapId}) {
    return _events(mapId).whereType<CircleTapEvent>();
  }

  @override
  Stream<MapTapEvent> onTap({required int mapId}) {
    return _events(mapId).whereType<MapTapEvent>();
  }

  @override
  Stream<MapLongPressEvent> onLongPress({required int mapId}) {
    return _events(mapId).whereType<MapLongPressEvent>();
  }

  @override
  Stream<ClusterTapEvent> onClusterTap({required int mapId}) {
    return _events(mapId).whereType<ClusterTapEvent>();
  }

  Future<dynamic> _handleMethodCall(MethodCall call, int mapId) async {
    switch (call.method) {
      case 'camera#onMoveStarted':
        _mapEventStreamController.add(CameraMoveStartedEvent(mapId));
        break;
      case 'camera#onMove':
        _mapEventStreamController.add(CameraMoveEvent(
          mapId,
          CameraPosition.fromMap(call.arguments['position'])!,
        ));
        break;
      case 'camera#onIdle':
        _mapEventStreamController.add(CameraIdleEvent(mapId));
        break;
      case 'marker#onTap':
        _mapEventStreamController.add(MarkerTapEvent(
          mapId,
          MarkerId(call.arguments['markerId'] as String),
        ));
        break;
      case 'marker#onDragStart':
        _mapEventStreamController.add(MarkerDragStartEvent(
          mapId,
          LatLng.fromJson(call.arguments['position'])!,
          MarkerId(call.arguments['markerId'] as String),
        ));
        break;
      case 'marker#onDrag':
        _mapEventStreamController.add(MarkerDragEvent(
          mapId,
          LatLng.fromJson(call.arguments['position'])!,
          MarkerId(call.arguments['markerId'] as String),
        ));
        break;
      case 'marker#onDragEnd':
        _mapEventStreamController.add(MarkerDragEndEvent(
          mapId,
          LatLng.fromJson(call.arguments['position'])!,
          MarkerId(call.arguments['markerId'] as String),
        ));
        break;
      case 'infoWindow#onTap':
        _mapEventStreamController.add(InfoWindowTapEvent(
          mapId,
          MarkerId(call.arguments['markerId'] as String),
        ));
        break;
      case 'polyline#onTap':
        _mapEventStreamController.add(PolylineTapEvent(
          mapId,
          PolylineId(call.arguments['polylineId'] as String),
        ));
        break;
      case 'polygon#onTap':
        _mapEventStreamController.add(PolygonTapEvent(
          mapId,
          PolygonId(call.arguments['polygonId'] as String),
        ));
        break;
      case 'circle#onTap':
        _mapEventStreamController.add(CircleTapEvent(
          mapId,
          CircleId(call.arguments['circleId'] as String),
        ));
        break;
      case 'map#onTap':
        _mapEventStreamController.add(MapTapEvent(
          mapId,
          LatLng.fromJson(call.arguments['position'])!,
        ));
        break;
      case 'map#onLongPress':
        _mapEventStreamController.add(MapLongPressEvent(
          mapId,
          LatLng.fromJson(call.arguments['position'])!,
        ));
        break;
      case 'tileOverlay#getTile':
        final Map<TileOverlayId, TileOverlay>? tileOverlaysForThisMap =
            _tileOverlays[mapId];
        final String tileOverlayId = call.arguments['tileOverlayId'] as String;
        final TileOverlay? tileOverlay =
            tileOverlaysForThisMap?[TileOverlayId(tileOverlayId)];
        final TileProvider? tileProvider = tileOverlay?.tileProvider;
        if (tileProvider == null) {
          return TileProvider.noTile.toJson();
        }
        final Tile tile = await tileProvider.getTile(
          call.arguments['x'] as int,
          call.arguments['y'] as int,
          call.arguments['zoom'] as int?,
        );
        return tile.toJson();
      case 'cluster#onTap':
        final ClusterManagerId clusterManagerId =
            ClusterManagerId(call.arguments['clusterManagerId'] as String);
        final LatLng position = LatLng.fromJson(call.arguments['position'])!;

        final Map<String, List<dynamic>> latLngData =
            (call.arguments['bounds']! as Map<dynamic, dynamic>).map(
                (dynamic key, dynamic object) =>
                    MapEntry<String, List<dynamic>>(
                        key as String, object as List<dynamic>));

        final LatLngBounds bounds = LatLngBounds(
            northeast: LatLng.fromJson(latLngData['northeast'])!,
            southwest: LatLng.fromJson(latLngData['southwest'])!);

        final List<MarkerId> markerIds =
            (call.arguments['markerIds']! as List<dynamic>)
                .map((dynamic markerId) => MarkerId(markerId as String))
                .toList();

        _mapEventStreamController.add(ClusterTapEvent(
          mapId,
          Cluster(clusterManagerId, position, bounds, markerIds),
        ));
        break;
      default:
        throw MissingPluginException();
    }
  }

  @override
  Future<void> updateMapOptions(
    Map<String, dynamic> optionsUpdate, {
    required int mapId,
  }) {
    assert(optionsUpdate != null);
    return _channel(mapId).invokeMethod<void>(
      'map#update',
      <String, dynamic>{
        'options': optionsUpdate,
      },
    );
  }

  @override
  Future<void> updateMarkers(
    MarkerUpdates markerUpdates, {
    required int mapId,
  }) {
    assert(markerUpdates != null);
    return _channel(mapId).invokeMethod<void>(
      'markers#update',
      markerUpdates.toJson(),
    );
  }

  @override
  Future<void> updateClusterManagers(
    ClusterManagerUpdates clusterManagerUpdates, {
    required int mapId,
  }) {
    assert(clusterManagerUpdates != null);
    return _channel(mapId).invokeMethod<void>(
      'clusterManagers#update',
      clusterManagerUpdates.toJson(),
    );
  }

  @override
  Future<void> updatePolygons(
    PolygonUpdates polygonUpdates, {
    required int mapId,
  }) {
    assert(polygonUpdates != null);
    return _channel(mapId).invokeMethod<void>(
      'polygons#update',
      polygonUpdates.toJson(),
    );
  }

  @override
  Future<void> updatePolylines(
    PolylineUpdates polylineUpdates, {
    required int mapId,
  }) {
    assert(polylineUpdates != null);
    return _channel(mapId).invokeMethod<void>(
      'polylines#update',
      polylineUpdates.toJson(),
    );
  }

  @override
  Future<void> updateCircles(
    CircleUpdates circleUpdates, {
    required int mapId,
  }) {
    assert(circleUpdates != null);
    return _channel(mapId).invokeMethod<void>(
      'circles#update',
      circleUpdates.toJson(),
    );
  }

  @override
  Future<void> updateTileOverlays({
    required Set<TileOverlay> newTileOverlays,
    required int mapId,
  }) {
    final Map<TileOverlayId, TileOverlay>? currentTileOverlays =
        _tileOverlays[mapId];
    final Set<TileOverlay> previousSet = currentTileOverlays != null
        ? currentTileOverlays.values.toSet()
        : <TileOverlay>{};
    final _TileOverlayUpdates updates =
        _TileOverlayUpdates.from(previousSet, newTileOverlays);
    _tileOverlays[mapId] = keyTileOverlayId(newTileOverlays);
    return _channel(mapId).invokeMethod<void>(
      'tileOverlays#update',
      updates.toJson(),
    );
  }

  @override
  Future<void> clearTileCache(
    TileOverlayId tileOverlayId, {
    required int mapId,
  }) {
    return _channel(mapId)
        .invokeMethod<void>('tileOverlays#clearTileCache', <String, Object>{
      'tileOverlayId': tileOverlayId.value,
    });
  }

  @override
  Future<void> animateCamera(
    CameraUpdate cameraUpdate, {
    required int mapId,
  }) {
    return _channel(mapId)
        .invokeMethod<void>('camera#animate', <String, Object>{
      'cameraUpdate': cameraUpdate.toJson(),
    });
  }

  @override
  Future<void> moveCamera(
    CameraUpdate cameraUpdate, {
    required int mapId,
  }) {
    return _channel(mapId).invokeMethod<void>('camera#move', <String, dynamic>{
      'cameraUpdate': cameraUpdate.toJson(),
    });
  }

  @override
  Future<void> setMapStyle(
    String? mapStyle, {
    required int mapId,
  }) async {
    final List<dynamic> successAndError = (await _channel(mapId)
        .invokeMethod<List<dynamic>>('map#setStyle', mapStyle))!;
    final bool success = successAndError[0] as bool;
    if (!success) {
      throw MapStyleException(successAndError[1] as String);
    }
  }

  @override
  Future<LatLngBounds> getVisibleRegion({
    required int mapId,
  }) async {
    final Map<String, dynamic> latLngBounds = (await _channel(mapId)
        .invokeMapMethod<String, dynamic>('map#getVisibleRegion'))!;
    final LatLng southwest = LatLng.fromJson(latLngBounds['southwest'])!;
    final LatLng northeast = LatLng.fromJson(latLngBounds['northeast'])!;

    return LatLngBounds(northeast: northeast, southwest: southwest);
  }

  @override
  Future<ScreenCoordinate> getScreenCoordinate(
    LatLng latLng, {
    required int mapId,
  }) async {
    final Map<String, int> point = (await _channel(mapId)
        .invokeMapMethod<String, int>(
            'map#getScreenCoordinate', latLng.toJson()))!;

    return ScreenCoordinate(x: point['x']!, y: point['y']!);
  }

  @override
  Future<LatLng> getLatLng(
    ScreenCoordinate screenCoordinate, {
    required int mapId,
  }) async {
    final List<dynamic> latLng = (await _channel(mapId)
        .invokeMethod<List<dynamic>>(
            'map#getLatLng', screenCoordinate.toJson()))!;
    return LatLng(latLng[0] as double, latLng[1] as double);
  }

  @override
  Future<void> showMarkerInfoWindow(
    MarkerId markerId, {
    required int mapId,
  }) {
    assert(markerId != null);
    return _channel(mapId).invokeMethod<void>(
        'markers#showInfoWindow', <String, String>{'markerId': markerId.value});
  }

  @override
  Future<void> hideMarkerInfoWindow(
    MarkerId markerId, {
    required int mapId,
  }) {
    assert(markerId != null);
    return _channel(mapId).invokeMethod<void>(
        'markers#hideInfoWindow', <String, String>{'markerId': markerId.value});
  }

  @override
  Future<bool> isMarkerInfoWindowShown(
    MarkerId markerId, {
    required int mapId,
  }) async {
    assert(markerId != null);
    return (await _channel(mapId).invokeMethod<bool>(
        'markers#isInfoWindowShown',
        <String, String>{'markerId': markerId.value}))!;
  }

  @override
  Future<double> getZoomLevel({
    required int mapId,
  }) async {
    return (await _channel(mapId).invokeMethod<double>('map#getZoomLevel'))!;
  }

  @override
  Future<Uint8List?> takeSnapshot({
    required int mapId,
  }) {
    return _channel(mapId).invokeMethod<Uint8List>('map#takeSnapshot');
  }

  Widget _buildView(
    int creationId,
    PlatformViewCreatedCallback onPlatformViewCreated, {
    required MapWidgetConfiguration widgetConfiguration,
    MapObjects mapObjects = const MapObjects(),
    Map<String, dynamic> mapOptions = const <String, dynamic>{},
  }) {
    final Map<String, dynamic> creationParams = <String, dynamic>{
      'initialCameraPosition':
          widgetConfiguration.initialCameraPosition.toMap(),
      'options': mapOptions,
      'markersToAdd': serializeMarkerSet(mapObjects.markers),
      'clusterManagersToAdd': serializeClusterSet(mapObjects.clusterManagers),
      'polygonsToAdd': serializePolygonSet(mapObjects.polygons),
      'polylinesToAdd': serializePolylineSet(mapObjects.polylines),
      'circlesToAdd': serializeCircleSet(mapObjects.circles),
      'tileOverlaysToAdd': serializeTileOverlaySet(mapObjects.tileOverlays),
    };

    return UiKitView(
      viewType: 'plugins.flutter.dev/google_maps_ios',
      onPlatformViewCreated: onPlatformViewCreated,
      gestureRecognizers: widgetConfiguration.gestureRecognizers,
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
    );
  }

  @override
  Widget buildViewWithConfiguration(
    int creationId,
    PlatformViewCreatedCallback onPlatformViewCreated, {
    required MapWidgetConfiguration widgetConfiguration,
    MapConfiguration mapConfiguration = const MapConfiguration(),
    MapObjects mapObjects = const MapObjects(),
  }) {
    return _buildView(
      creationId,
      onPlatformViewCreated,
      widgetConfiguration: widgetConfiguration,
      mapObjects: mapObjects,
      mapOptions: _jsonForMapConfiguration(mapConfiguration),
    );
  }

  @override
  Widget buildViewWithTextDirection(
    int creationId,
    PlatformViewCreatedCallback onPlatformViewCreated, {
    required CameraPosition initialCameraPosition,
    required TextDirection textDirection,
    Set<Marker> markers = const <Marker>{},
    Set<Polygon> polygons = const <Polygon>{},
    Set<Polyline> polylines = const <Polyline>{},
    Set<Circle> circles = const <Circle>{},
    Set<TileOverlay> tileOverlays = const <TileOverlay>{},
    Set<ClusterManager> clusterManagers = const <ClusterManager>{},
    Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers,
    Map<String, dynamic> mapOptions = const <String, dynamic>{},
  }) {
    return _buildView(
      creationId,
      onPlatformViewCreated,
      widgetConfiguration: MapWidgetConfiguration(
          initialCameraPosition: initialCameraPosition,
          textDirection: textDirection),
      mapObjects: MapObjects(
          markers: markers,
          polygons: polygons,
          polylines: polylines,
          circles: circles,
          tileOverlays: tileOverlays,
          clusterManagers: clusterManagers),
      mapOptions: mapOptions,
    );
  }

  @override
  Widget buildView(
    int creationId,
    PlatformViewCreatedCallback onPlatformViewCreated, {
    required CameraPosition initialCameraPosition,
    Set<Marker> markers = const <Marker>{},
    Set<Polygon> polygons = const <Polygon>{},
    Set<Polyline> polylines = const <Polyline>{},
    Set<Circle> circles = const <Circle>{},
    Set<TileOverlay> tileOverlays = const <TileOverlay>{},
    Set<ClusterManager> clusterManagers = const <ClusterManager>{},
    Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers,
    Map<String, dynamic> mapOptions = const <String, dynamic>{},
  }) {
    return buildViewWithTextDirection(
      creationId,
      onPlatformViewCreated,
      initialCameraPosition: initialCameraPosition,
      textDirection: TextDirection.ltr,
      markers: markers,
      polygons: polygons,
      polylines: polylines,
      circles: circles,
      tileOverlays: tileOverlays,
      clusterManagers: clusterManagers,
      gestureRecognizers: gestureRecognizers,
      mapOptions: mapOptions,
    );
  }

  @override
  @visibleForTesting
  void enableDebugInspection() {
    GoogleMapsInspectorPlatform.instance =
        GoogleMapsInspectorIOS((int mapId) => _channel(mapId));
  }
}

Map<String, Object> _jsonForMapConfiguration(MapConfiguration config) {
  final EdgeInsets? padding = config.padding;
  return <String, Object>{
    if (config.compassEnabled != null) 'compassEnabled': config.compassEnabled!,
    if (config.mapToolbarEnabled != null)
      'mapToolbarEnabled': config.mapToolbarEnabled!,
    if (config.cameraTargetBounds != null)
      'cameraTargetBounds': config.cameraTargetBounds!.toJson(),
    if (config.mapType != null) 'mapType': config.mapType!.index,
    if (config.minMaxZoomPreference != null)
      'minMaxZoomPreference': config.minMaxZoomPreference!.toJson(),
    if (config.rotateGesturesEnabled != null)
      'rotateGesturesEnabled': config.rotateGesturesEnabled!,
    if (config.scrollGesturesEnabled != null)
      'scrollGesturesEnabled': config.scrollGesturesEnabled!,
    if (config.tiltGesturesEnabled != null)
      'tiltGesturesEnabled': config.tiltGesturesEnabled!,
    if (config.zoomControlsEnabled != null)
      'zoomControlsEnabled': config.zoomControlsEnabled!,
    if (config.zoomGesturesEnabled != null)
      'zoomGesturesEnabled': config.zoomGesturesEnabled!,
    if (config.liteModeEnabled != null)
      'liteModeEnabled': config.liteModeEnabled!,
    if (config.trackCameraPosition != null)
      'trackCameraPosition': config.trackCameraPosition!,
    if (config.myLocationEnabled != null)
      'myLocationEnabled': config.myLocationEnabled!,
    if (config.myLocationButtonEnabled != null)
      'myLocationButtonEnabled': config.myLocationButtonEnabled!,
    if (padding != null)
      'padding': <double>[
        padding.top,
        padding.left,
        padding.bottom,
        padding.right,
      ],
    if (config.indoorViewEnabled != null)
      'indoorEnabled': config.indoorViewEnabled!,
    if (config.trafficEnabled != null) 'trafficEnabled': config.trafficEnabled!,
    if (config.buildingsEnabled != null)
      'buildingsEnabled': config.buildingsEnabled!,
  };
}

/// Update specification for a set of [TileOverlay]s.
// TODO(stuartmorgan): Fix the missing export of this class in the platform
// interface, and remove this copy.
class _TileOverlayUpdates extends MapsObjectUpdates<TileOverlay> {
  /// Computes [TileOverlayUpdates] given previous and current [TileOverlay]s.
  _TileOverlayUpdates.from(Set<TileOverlay> previous, Set<TileOverlay> current)
      : super.from(previous, current, objectName: 'tileOverlay');

  /// Set of TileOverlays to be added in this update.
  Set<TileOverlay> get tileOverlaysToAdd => objectsToAdd;

  /// Set of TileOverlayIds to be removed in this update.
  Set<TileOverlayId> get tileOverlayIdsToRemove =>
      objectIdsToRemove.cast<TileOverlayId>();

  /// Set of TileOverlays to be changed in this update.
  Set<TileOverlay> get tileOverlaysToChange => objectsToChange;
}
