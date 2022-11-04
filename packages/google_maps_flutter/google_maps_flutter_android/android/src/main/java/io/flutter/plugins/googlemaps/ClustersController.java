// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.googlemaps;

import android.content.Context;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
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

class ClustersController implements GoogleMap.OnCameraIdleListener {
  private static final String TAG = "ClustersController";
  private final Context context;
  private final HashMap<String, ClusterManager> clusterIdToManager;
  private final HashMap<String, WeakReference<MarkerController>> clusterIdToController;
  private final MethodChannel methodChannel;
  private MarkerManager markerManager;
  private GoogleMap googleMap;
  private ClusterListener clusterListener;

  ClustersController(MethodChannel methodChannel, Context context) {
    this.clusterIdToManager = new HashMap<>();
    this.clusterIdToController = new HashMap<>();
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
    for (Map.Entry<String, ClusterManager> entry : clusterIdToManager.entrySet()) {
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

  void addClusters(List<Object> clustersToAdd) {
    if (clustersToAdd != null) {
      for (Object clusterToAdd : clustersToAdd) {
        addCluster(clusterToAdd);
      }
    }
  }

  void addCluster(Object cluster) {
    String clusterId = getClusterId(cluster);
    Log.e(TAG, "Adding cluster 1 - clusterId:" + clusterId);
    if (clusterId == null) {
      throw new IllegalArgumentException("clusterId was null");
    }
    ClusterManager clusterManager = new ClusterManager<MarkerBuilder>(context, googleMap, markerManager);
    ClusterRenderer clusterRenderer = new ClusterRenderer(context, googleMap, clusterManager, clusterId, this);
    clusterManager.setRenderer(clusterRenderer);
    initListenersForClusterManager(clusterManager, clusterListener);
    clusterIdToManager.put(clusterId, clusterManager);
  }

  public void removeClusters(List<Object> clusterIdsToRemove) {
    if (clusterIdsToRemove == null) {
      return;
    }
    for (Object rawClusterId : clusterIdsToRemove) {
      if (rawClusterId == null) {
        continue;
      }
      String clusterId = (String) rawClusterId;
      removeCluster(clusterId);
    }
  }

  private void removeCluster(Object clusterId) {
    final ClusterManager clusterManager = clusterIdToManager.remove(clusterId);
    if (clusterManager == null) {
      return;
    }
    initListenersForClusterManager(clusterManager, null);
    clusterManager.clearItems();
  }

  public void changeClusters(List<Object> clustersToChange) {
    if (clustersToChange != null) {
      for (Object clusterToChange : clustersToChange) {
        changeCluster(clusterToChange);
      }
    }
  }

  private void changeCluster(Object clusterToChange) {
  }

  public void addItem(MarkerBuilder item) {
    ClusterManager clusterManager = clusterIdToManager.get(item.clusterId());
    Log.e(TAG, "addItem: Found cluster manager:" + clusterManager.toString());
    if (clusterManager != null) {
      clusterManager.addItem(item);
      clusterManager.cluster();
    }
  }

  public void removeItem(MarkerBuilder item) {
    ClusterManager clusterManager = clusterIdToManager.get(item.clusterId());
    Log.e(TAG, "removeItem: Found cluster manager:" + clusterManager.toString());
    if (clusterManager != null) {
      clusterManager.removeItem(item);
      clusterManager.cluster();
    }
  }

  void onMarker(MarkerBuilder item, Marker marker) {
    if (clusterListener != null) {
      clusterListener.onClusterMarker(item, marker);
    }
  }

  @SuppressWarnings("unchecked")
  private static String getClusterId(Object cluster) {
    Map<String, Object> clusterMap = (Map<String, Object>) cluster;
    return (String) clusterMap.get("clusterId");
  }

  @Override
  public void onCameraIdle() {
    Log.e(TAG, "Camera idle");
    for (Map.Entry<String, ClusterManager> entry : clusterIdToManager.entrySet()) {
      Log.e(TAG, "Inform idle for " + entry.getKey());
      entry.getValue().onCameraIdle();
    }
  }

  private class ClusterRenderer extends DefaultClusterRenderer<MarkerBuilder> {
    private final ClustersController clustersController;
    private final String clusterId;

    public ClusterRenderer(
        Context context,
        GoogleMap map,
        ClusterManager<MarkerBuilder> clusterManager,
        String clusterId,
        ClustersController clustersController) {
      super(context, map, clusterManager);
      this.clustersController = clustersController;
      this.clusterId = clusterId;
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
      clustersController.onMarker(item, marker);
    }

    @Override
    protected void onClusterItemRendered(@NonNull MarkerBuilder item, @NonNull Marker marker) {
      Log.e(TAG, "onClusterItemRendered:" + item.markerId());
      super.onClusterItemRendered(item, marker);
      clustersController.onMarker(item, marker);
    }

    @Override
    protected void onBeforeClusterRendered(
        @NonNull Cluster<MarkerBuilder> cluster, @NonNull MarkerOptions markerOptions) {
      Log.e(TAG, "onBeforeClusterRendered:" + cluster.toString());
      super.onBeforeClusterRendered(cluster, markerOptions);
      // clustersController.initClusterMarkerOptions(clusterId, markerOptions);
    }

    @Override
    protected void onClusterUpdated(@NonNull Cluster<MarkerBuilder> cluster, @NonNull Marker marker) {
      Log.e(TAG, "onClusterUpdated:" + cluster.toString());
      super.onClusterUpdated(cluster, marker);
      // clustersController.onCluster(clusterId, item, marker);
    }

    @Override
    protected void onClusterRendered(@NonNull Cluster<MarkerBuilder> cluster, @NonNull Marker marker) {
      Log.e(TAG, "onClusterRendered:" + cluster.toString());
      super.onClusterUpdated(cluster, marker);
      // clustersController.onCluster(clusterId, item, marker);
    }
  }

  public interface OnClusterMarker<T extends ClusterItem> {
    void onClusterMarker(MarkerBuilder markerBuilder, Marker marker);
  }
}
