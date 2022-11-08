// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.googlemaps;

import com.google.android.gms.maps.model.BitmapDescriptor;

/** Receiver of Marker configuration options. */
interface ClusterMarkerOptionsSink {
  void setIcon(BitmapDescriptor bitmapDescriptor);

  void setConsumeTapEvents(boolean consumeTapEvents);
}
