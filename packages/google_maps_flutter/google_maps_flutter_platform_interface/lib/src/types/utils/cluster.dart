// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../types.dart';
import 'maps_object.dart';

/// Converts an [Iterable] of Clusters in a Map of ClusterId -> Cluster.
Map<ClusterId, Cluster> keyByClusterId(Iterable<Cluster> clusters) {
  return keyByMapsObjectId<Cluster>(clusters).cast<ClusterId, Cluster>();
}

/// Converts a Set of Clusters into something serializable in JSON.
Object serializeClusterSet(Set<Cluster> clusters) {
  return serializeMapsObjectSet(clusters);
}
