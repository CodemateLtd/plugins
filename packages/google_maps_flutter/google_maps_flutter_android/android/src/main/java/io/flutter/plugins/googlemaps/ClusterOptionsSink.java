// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.googlemaps;

/** Receiver of Marker configuration options. */
interface ClusterOptionsSink {
  void setVisible(boolean visible);

  void setConsumeTapEvents(boolean consumeTapEvents);
}
