// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'types.dart';

/// [Cluster] update events to be applied to the [GoogleMap].
///
/// Used in [GoogleMapController] when the map is updated.
// (Do not re-export)
class ClusterUpdates extends MapsObjectUpdates<Cluster> {
  /// Computes [ClusterUpdates] given previous and current [Cluster]s.
  ClusterUpdates.from(Set<Cluster> previous, Set<Cluster> current)
      : super.from(previous, current, objectName: 'cluster');

  /// Set of Clusters to be added in this update.
  Set<Cluster> get clustersToAdd => objectsToAdd;

  /// Set of ClusterIds to be removed in this update.
  Set<ClusterId> get clusterIdsToRemove => objectIdsToRemove.cast<ClusterId>();

  /// Set of Clusters to be changed in this update.
  Set<Cluster> get clustersToChange => objectsToChange;
}
