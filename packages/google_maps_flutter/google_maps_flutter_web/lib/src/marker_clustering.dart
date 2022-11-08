// ignore_for_file: public_member_api_docs, non_constant_identifier_names
part of google_maps_flutter_web;

typedef ClusterClickHandler = void Function(
    gmaps.MapMouseEvent, Cluster, gmaps.GMap);

class ClusterManagersController extends GeometryController {
  ClusterManagersController()
      : _clusterManagerIdToMarkerClusterer =
            <ClusterManagerId, MarkerClusterer>{};

  // A cache of [MarkerClusterer]s indexed by their [ClusterManagerId].
  final Map<ClusterManagerId, MarkerClusterer>
      _clusterManagerIdToMarkerClusterer;

  /// Adds a set of [ClusterManager] objects to the cache.
  void addClusterManagers(Set<ClusterManager> clusterManagersToAdd) {
    clusterManagersToAdd.forEach(_addClusterManager);
  }

  void _addClusterManager(ClusterManager clusterManager) {
    if (clusterManager == null) {
      return;
    }
    final MarkerClustererOptions markerClustererOptions =
        createClusterOptions(googleMap, markers: <gmaps.Marker>[]);
    final MarkerClusterer markerClusterer =
        MarkerClusterer(markerClustererOptions);
    _clusterManagerIdToMarkerClusterer[clusterManager.clusterManagerId] =
        markerClusterer;
    markerClusterer.onAdd();
  }

  /// Removes a set of [ClusterManagerId]s from the cache.
  void removeClusterManagers(Set<ClusterManagerId> clusterManagerIdsToRemove) {
    clusterManagerIdsToRemove.forEach(_removeClusterManager);
  }

  void _removeClusterManager(ClusterManagerId clusterManagerId) {
    final MarkerClusterer? markerClusterer =
        _clusterManagerIdToMarkerClusterer[clusterManagerId];
    if (markerClusterer != null) {
      markerClusterer.onRemove();
      markerClusterer.clearMarkers(true);
    }
    _clusterManagerIdToMarkerClusterer.remove(clusterManagerId);
  }

  /// Updates a set of [ClusterManager] objects with new options.
  void changeClusterManagers(Set<ClusterManager> clusterManagersToChange) {
    clusterManagersToChange.forEach(_changeClusterManager);
  }

  void _changeClusterManager(ClusterManager clusterManager) {}

  void addItem(ClusterManagerId clusterManagerId, gmaps.Marker marker) {
    final MarkerClusterer? markerClusterer =
        _clusterManagerIdToMarkerClusterer[clusterManagerId];
    if (markerClusterer != null) {
      markerClusterer.addMarker(marker, false);
    }
  }

  void removeItem(ClusterManagerId clusterManagerId, gmaps.Marker? marker) {
    if (marker != null) {
      final MarkerClusterer? markerClusterer =
          _clusterManagerIdToMarkerClusterer[clusterManagerId];
      if (markerClusterer != null) {
        markerClusterer.removeMarker(marker, false);
      }
    }
  }
}

@JS()
external ClusterClickHandler defaultOnClusterClickHandler;

@JS()
@anonymous
class MarkerClustererOptions {
  external factory MarkerClustererOptions();

  external gmaps.GMap? get map;

  external set map(gmaps.GMap? map);

  external List<gmaps.Marker>? get markers;

  external set markers(List<gmaps.Marker>? markers);

  external ClusterClickHandler? get onClusterClick;

  external set onClusterClick(ClusterClickHandler? handler);
}

@JS('markerClusterer.Cluster')
class Cluster {
  external gmaps.Marker get marker;
  external List<gmaps.Marker>? markers;

  external gmaps.LatLngBounds? get bounds;
  external gmaps.LatLng get position;

  /// Get the count of **visible** markers.
  external int get count;

  external void delete();
  external void push(gmaps.Marker marker);
}

@JS('markerClusterer.MarkerClusterer')
class MarkerClusterer {
  external MarkerClusterer(MarkerClustererOptions options);

  external void addMarker(gmaps.Marker marker, bool? noDraw);
  external void addMarkers(List<gmaps.Marker>? markers, bool? noDraw);
  external bool removeMarker(gmaps.Marker marker, bool? noDraw);
  external bool removeMarkers(List<gmaps.Marker>? markers, bool? noDraw);
  external void clearMarkers(bool? noDraw);
  external void onAdd();
  external void onRemove();

  /// Recalculates and draws all the marker clusters.
  external void render();
}

MarkerClusterer createMarkerClusterer(gmaps.GMap map,
    {List<gmaps.Marker>? markers, ClusterClickHandler? onClusterClickHandler}) {
  return MarkerClusterer(createClusterOptions(map,
      markers: markers, onClusterClickHandler: onClusterClickHandler));
}

MarkerClustererOptions createClusterOptions(gmaps.GMap map,
    {List<gmaps.Marker>? markers, ClusterClickHandler? onClusterClickHandler}) {
  final MarkerClustererOptions options = MarkerClustererOptions()
    ..map = map
    ..markers = markers;

  if (onClusterClickHandler != null) {
    options.onClusterClick = allowInterop(onClusterClickHandler);
  }

  return options;
}
