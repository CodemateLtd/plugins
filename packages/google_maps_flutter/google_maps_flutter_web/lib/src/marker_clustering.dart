// ignore_for_file: public_member_api_docs, non_constant_identifier_names
part of google_maps_flutter_web;

typedef ClusterClickHandler = void Function(
    gmaps.MapMouseEvent, Cluster, gmaps.GMap);

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
