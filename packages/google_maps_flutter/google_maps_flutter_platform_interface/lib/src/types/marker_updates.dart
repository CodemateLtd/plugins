// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'types.dart';

/// [Marker] update events to be applied to the [GoogleMap].
///
/// Used in [GoogleMapController] when the map is updated.
// (Do not re-export)
class MarkerUpdates extends MapsObjectUpdates<Marker> {
  /// Computes [MarkerUpdates] given previous and current [Marker]s.
  MarkerUpdates.from(Set<Marker> previous, Set<Marker> current)
      : super.from(<Marker>{}, <Marker>{}, objectName: 'marker') {
    final Set<ClusterManagerId?> clusterManagerIds = <ClusterManagerId?>{
      ...previous.map<ClusterManagerId?>((Marker m) => m.clusterManagerId),
      ...current.map<ClusterManagerId?>((Marker m) => m.clusterManagerId)
    }.toSet();

    for (final ClusterManagerId? clusterManagerId in clusterManagerIds) {
      final MapsObjectUpdates<Marker> clusterManagerUpdates =
          MapsObjectUpdates<Marker>.from(
              previous
                  .where((Marker m) => m.clusterManagerId == clusterManagerId)
                  .toSet(),
              current
                  .where((Marker m) => m.clusterManagerId == clusterManagerId)
                  .toSet(),
              objectName: 'marker');
      objectsToAdd.addAll(clusterManagerUpdates.objectsToAdd);
      objectIdsToRemove.addAll(clusterManagerUpdates.objectIdsToRemove);
      objectsToChange.addAll(clusterManagerUpdates.objectsToChange);
    }
  }

  /// Set of Markers to be added in this update.
  Set<Marker> get markersToAdd => objectsToAdd;

  /// Set of MarkerIds to be removed in this update.
  Set<MarkerId> get markerIdsToRemove => objectIdsToRemove.cast<MarkerId>();

  /// Set of Markers to be changed in this update.
  Set<Marker> get markersToChange => objectsToChange;
}
