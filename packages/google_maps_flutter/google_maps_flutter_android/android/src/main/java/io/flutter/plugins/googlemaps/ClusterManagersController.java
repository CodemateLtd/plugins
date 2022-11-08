// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.googlemaps;

import android.content.Context;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import android.graphics.Color;
import com.google.android.gms.maps.GoogleMap;
import com.google.android.gms.maps.model.Marker;
import com.google.android.gms.maps.model.MarkerOptions;
import com.google.maps.android.clustering.Cluster;
import com.google.maps.android.clustering.ClusterItem;
import com.google.maps.android.clustering.ClusterManager;
import com.google.maps.android.clustering.view.DefaultClusterRenderer;
import com.google.maps.android.collections.MarkerManager;

import io.flutter.Log;
import io.flutter.plugin.common.MethodChannel;
import java.lang.ref.WeakReference;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

class ClusterManagersController implements GoogleMap.OnCameraIdleListener {
  private static final String TAG = "ClusterManagersController";
  private final Context context;
  private final HashMap<String, ClusterManager> clusterManagerIdToManager;
  private final HashMap<String, WeakReference<MarkerController>> clusterManagerIdToController;
  private final MethodChannel methodChannel;
  private MarkerManager markerManager;
  private GoogleMap googleMap;
  private ClusterListener clusterListener;

  ClusterManagersController(MethodChannel methodChannel, Context context) {
    this.clusterManagerIdToManager = new HashMap<>();
    this.clusterManagerIdToController = new HashMap<>();
    this.markerManager = markerManager;
    this.context = context;
    this.methodChannel = methodChannel;
  }

  void init(GoogleMap googleMap, MarkerManager markerManager) {
    this.markerManager = markerManager;
    this.googleMap = googleMap;
  }

  void setListener(@Nullable ClusterListener listener) {
    clusterListener = listener;
    initListenersForClusterManagers(listener);
  }

  private void initListenersForClusterManagers(@Nullable ClusterListener listener) {
    for (Map.Entry<String, ClusterManager> entry : clusterManagerIdToManager.entrySet()) {
      initListenersForClusterManager(entry.getValue(), listener);
    }
  }

  private void initListenersForClusterManager(
      ClusterManager clusterManager, @Nullable ClusterListener listener) {
    clusterManager.setOnClusterInfoWindowClickListener(listener);
    clusterManager.setOnClusterClickListener(listener);
    clusterManager.setOnClusterItemClickListener(listener);
    clusterManager.setOnClusterItemInfoWindowClickListener(listener);
  }

  void addClusterManagers(List<Object> clusterManagersToAdd) {
    if (clusterManagersToAdd != null) {
      for (Object clusterToAdd : clusterManagersToAdd) {
        addClusterManager(clusterToAdd);
      }
    }
  }

  void addClusterManager(Object clusterManagerData) {
    String clusterManagerId = getClusterManagerId(clusterManagerData);
    if (clusterManagerId == null) {
      throw new IllegalArgumentException("clusterManagerId was null");
    }
    ClusterManager clusterManager = new ClusterManager<MarkerBuilder>(context, googleMap, markerManager);
    ClusterRenderer clusterRenderer = new ClusterRenderer(context, googleMap, clusterManager, clusterManagerId, this);
    clusterManager.setRenderer(clusterRenderer);
    initListenersForClusterManager(clusterManager, clusterListener);
    clusterManagerIdToManager.put(clusterManagerId, clusterManager);
  }

  public void removeClusterManagers(List<Object> clusterManagerIdsToRemove) {
    if (clusterManagerIdsToRemove == null) {
      return;
    }
    for (Object rawClusterManagerId : clusterManagerIdsToRemove) {
      if (rawClusterManagerId == null) {
        continue;
      }
      String clusterManagerId = (String) rawClusterManagerId;
      removeClusterManager(clusterManagerId);
    }
  }

  private void removeClusterManager(Object clusterManagerId) {
    final ClusterManager clusterManager = clusterManagerIdToManager.remove(clusterManagerId);
    if (clusterManager == null) {
      return;
    }
    initListenersForClusterManager(clusterManager, null);
    clusterManager.clearItems();
    clusterManager.cluster();
  }

  public void changeClusters(List<Object> clusterManagersToChange) {
    if (clusterManagersToChange != null) {
      for (Object clusterToChange : clusterManagersToChange) {
        changeCluster(clusterToChange);
      }
    }
  }

  private void changeCluster(Object clusterToChange) {
  }

  public void addItem(MarkerBuilder item) {
    Log.e(TAG, "addItem 1:" + item.clusterManagerId());
    ClusterManager clusterManager = clusterManagerIdToManager.get(item.clusterManagerId());
    if (clusterManager != null) {
      Log.e(TAG, "addItem 2:" + item.clusterManagerId());
      clusterManager.addItem(item);
      clusterManager.cluster();
    }
  }

  public void removeItem(MarkerBuilder item) {
    ClusterManager clusterManager = clusterManagerIdToManager.get(item.clusterManagerId());
    if (clusterManager != null) {
      clusterManager.removeItem(item);
      clusterManager.cluster();
    }
  }

  void onClusterMarker(MarkerBuilder item, Marker marker) {
    if (clusterListener != null) {
      Log.e(TAG, "onClusterMarker: " + item.markerId());
      clusterListener.onClusterMarker(item, marker);
    }
  }

  @SuppressWarnings("unchecked")
  private static String getClusterManagerId(Object clusterManagerData) {
    Map<String, Object> clusterMap = (Map<String, Object>) clusterManagerData;
    return (String) clusterMap.get("clusterManagerId");
  }

  @Override
  public void onCameraIdle() {
    Log.e(TAG, "Camera idle");
    for (Map.Entry<String, ClusterManager> entry : clusterManagerIdToManager.entrySet()) {
      Log.e(TAG, "Inform idle for " + entry.getKey());
      entry.getValue().onCameraIdle();
    }
  }

  private class ClusterRenderer extends DefaultClusterRenderer<MarkerBuilder> {
    private final ClusterManagersController clusterManagersController;
    private final String clusterManagerId;

    public ClusterRenderer(
        Context context,
        GoogleMap map,
        ClusterManager<MarkerBuilder> clusterManager,
        String clusterManagerId,
        ClusterManagersController clusterManagersController) {
      super(context, map, clusterManager);
      this.clusterManagersController = clusterManagersController;
      this.clusterManagerId = clusterManagerId;
    }

    @Override
    protected void onBeforeClusterItemRendered(@NonNull MarkerBuilder item, @NonNull MarkerOptions markerOptions) {
      Log.e(TAG, "onBeforeClusterItemRendered:" + item.markerId());
      item.build(markerOptions);
    }

    @Override
    protected void onClusterItemUpdated(@NonNull MarkerBuilder item, @NonNull Marker marker) {
      Log.e(TAG, "onClusterItemUpdated:" + item.markerId());
      super.onClusterItemUpdated(item, marker);
      clusterManagersController.onClusterMarker(item, marker);
    }

    @Override
    protected void onClusterItemRendered(@NonNull MarkerBuilder item, @NonNull Marker marker) {
      Log.e(TAG, "onClusterItemRendered:" + item.markerId());
      super.onClusterItemRendered(item, marker);
      clusterManagersController.onClusterMarker(item, marker);
    }

    @Override
    protected void onBeforeClusterRendered(
        @NonNull Cluster<MarkerBuilder> cluster, @NonNull MarkerOptions markerOptions) {
      Log.e(TAG, "onBeforeClusterRendered:" + cluster.toString());
      super.onBeforeClusterRendered(cluster, markerOptions);
      // clusterManagersController.initClusterMarkerOptions(clusterManagerId,
      // markerOptions);
    }

    @Override
    protected void onClusterUpdated(@NonNull Cluster<MarkerBuilder> cluster, @NonNull Marker marker) {
      Log.e(TAG, "onClusterUpdated:" + cluster.toString());
      super.onClusterUpdated(cluster, marker);
      // clusterManagersController.onCluster(clusterManagerId, item, marker);
    }

    @Override
    protected void onClusterRendered(@NonNull Cluster<MarkerBuilder> cluster, @NonNull Marker marker) {
      Log.e(TAG, "onClusterRendered:" + cluster.toString());
      super.onClusterUpdated(cluster, marker);
      // clusterManagersController.onCluster(clusterManagerId, item, marker);
    }

    @Override
    protected int getColor(int clusterSize) {
      return Color.argb(255, 50, 128, 128);
    }
  }

  public interface OnClusterMarker<T extends ClusterItem> {
    void onClusterMarker(MarkerBuilder markerBuilder, Marker marker);
  }
}
