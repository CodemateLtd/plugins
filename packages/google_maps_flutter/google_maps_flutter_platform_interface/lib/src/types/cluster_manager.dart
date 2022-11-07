// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart' show immutable, VoidCallback;
import 'types.dart';

/// Uniquely identifies a [ClusterManager] among [GoogleMap] clusters.
///
/// This does not have to be globally unique, only unique among the list.
@immutable
class ClusterManagerId extends MapsObjectId<ClusterManager> {
  /// Creates an immutable identifier for a [ClusterManager].
  const ClusterManagerId(String value) : super(value);
}

/// TBD
@immutable
class ClusterManager implements MapsObject<ClusterManager> {
  /// Creates a set of cluster configuration options.
  ///
  /// Default cluster options.
  ///
  /// Specifies a cluster that
  /// * TBD
  /// * reports [onTap] events
  const ClusterManager({
    required this.clusterManagerId,
    this.consumeTapEvents = false,
    this.infoWindow = InfoWindow.noText,
    this.icon = BitmapDescriptor.defaultMarker,
    this.onTap,
  });

  /// Uniquely identifies a [ClusterManager].
  final ClusterManagerId clusterManagerId;

  @override
  ClusterManagerId get mapsId => clusterManagerId;

  /// True if the cluster icon consumes tap events. If not, the map will perform
  /// default tap handling by centering the map on the cluster and displaying its
  /// info window.
  final bool consumeTapEvents;

  /// A description of the bitmap used to draw the marker icon.
  final BitmapDescriptor icon;

  /// A Google Maps InfoWindow.
  ///
  /// The window is displayed when the cluster is tapped.
  final InfoWindow infoWindow;

  /// Callbacks to receive tap events for cluster icons placed on this map.
  final VoidCallback? onTap;

  /// Creates a new [ClusterManager] object whose values are the same as this instance,
  /// unless overwritten by the specified parameters.
  ClusterManager copyWith({
    bool? consumeTapEventsParam,
    InfoWindow? infoWindowParam,
    BitmapDescriptor? iconParam,
    VoidCallback? onTapParam,
  }) {
    return ClusterManager(
      clusterManagerId: clusterManagerId,
      consumeTapEvents: consumeTapEventsParam ?? consumeTapEvents,
      icon: iconParam ?? icon,
      infoWindow: infoWindowParam ?? infoWindow,
      onTap: onTapParam ?? onTap,
    );
  }

  /// Creates a new [ClusterManager] object whose values are the same as this instance.
  @override
  ClusterManager clone() => copyWith();

  /// Converts this object to something serializable in JSON.
  @override
  Object toJson() {
    final Map<String, Object> json = <String, Object>{};

    void addIfPresent(String fieldName, Object? value) {
      if (value != null) {
        json[fieldName] = value;
      }
    }

    addIfPresent('clusterManagerId', clusterManagerId.value);
    addIfPresent('consumeTapEvents', consumeTapEvents);
    addIfPresent('icon', icon.toJson());
    addIfPresent('infoWindow', infoWindow.toJson());
    return json;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is ClusterManager &&
        clusterManagerId == other.clusterManagerId &&
        consumeTapEvents == other.consumeTapEvents &&
        icon == other.icon &&
        infoWindow == other.infoWindow;
  }

  @override
  int get hashCode => clusterManagerId.hashCode;

  @override
  String toString() {
    return 'Cluster{clusterManagerId: $clusterManagerId, consumeTapEvents: $consumeTapEvents, '
        'icon: $icon, infoWindow: $infoWindow, onTap: $onTap}';
  }
}
