// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart' show immutable, VoidCallback;
import 'types.dart';

/// Uniquely identifies a [Cluster] among [GoogleMap] clusters.
///
/// This does not have to be globally unique, only unique among the list.
@immutable
class ClusterId extends MapsObjectId<Cluster> {
  /// Creates an immutable identifier for a [Cluster].
  const ClusterId(String value) : super(value);
}

/// TBD
@immutable
class Cluster implements MapsObject<Cluster> {
  /// Creates a set of cluster configuration options.
  ///
  /// Default cluster options.
  ///
  /// Specifies a cluster that
  /// * TBD
  /// * reports [onTap] events
  const Cluster({
    required this.clusterId,
    this.consumeTapEvents = false,
    this.infoWindow = InfoWindow.noText,
    this.visible = true,
    this.onTap,
  });

  /// Uniquely identifies a [Cluster].
  final ClusterId clusterId;

  @override
  ClusterId get mapsId => clusterId;

  /// True if the cluster icon consumes tap events. If not, the map will perform
  /// default tap handling by centering the map on the cluster and displaying its
  /// info window.
  final bool consumeTapEvents;

  /// A Google Maps InfoWindow.
  ///
  /// The window is displayed when the cluster is tapped.
  final InfoWindow infoWindow;

  /// True if the cluster icon is visible.
  final bool visible;

  /// Callbacks to receive tap events for cluster icons placed on this map.
  final VoidCallback? onTap;

  /// Creates a new [Cluster] object whose values are the same as this instance,
  /// unless overwritten by the specified parameters.
  Cluster copyWith({
    bool? consumeTapEventsParam,
    InfoWindow? infoWindowParam,
    bool? visibleParam,
    VoidCallback? onTapParam,
  }) {
    return Cluster(
      clusterId: clusterId,
      consumeTapEvents: consumeTapEventsParam ?? consumeTapEvents,
      infoWindow: infoWindowParam ?? infoWindow,
      visible: visibleParam ?? visible,
      onTap: onTapParam ?? onTap,
    );
  }

  /// Creates a new [Cluster] object whose values are the same as this instance.
  @override
  Cluster clone() => copyWith();

  /// Converts this object to something serializable in JSON.
  @override
  Object toJson() {
    final Map<String, Object> json = <String, Object>{};

    void addIfPresent(String fieldName, Object? value) {
      if (value != null) {
        json[fieldName] = value;
      }
    }

    addIfPresent('clusterId', clusterId.value);
    addIfPresent('consumeTapEvents', consumeTapEvents);
    addIfPresent('infoWindow', infoWindow.toJson());
    addIfPresent('visible', visible);
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
    return other is Cluster &&
        clusterId == other.clusterId &&
        consumeTapEvents == other.consumeTapEvents &&
        infoWindow == other.infoWindow &&
        visible == other.visible;
  }

  @override
  int get hashCode => clusterId.hashCode;

  @override
  String toString() {
    return 'Cluster{clusterId: $clusterId, consumeTapEvents: $consumeTapEvents, '
        'infoWindow: $infoWindow, visible: $visible, onTap: $onTap}';
  }
}
