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
import io.flutter.plugin.common.MethodChannel;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

class ClusterManagersController implements GoogleMap.OnCameraIdleListener, ClusterListener {
  private final Context context;
  private final HashMap<String, ClusterManager<MarkerBuilder>> clusterManagerIdToManager;
  private final MethodChannel methodChannel;
  private MarkerManager markerManager;
  private GoogleMap googleMap;
  private ClusterMarkerListener clusterMarkerListener;

  ClusterManagersController(MethodChannel methodChannel, Context context) {
    this.clusterManagerIdToManager = new HashMap<>();
    this.context = context;
    this.methodChannel = methodChannel;
  }

  void init(GoogleMap googleMap, MarkerManager markerManager) {
    this.markerManager = markerManager;
    this.googleMap = googleMap;
  }

  void setClusterMarkerListener(@Nullable ClusterMarkerListener listener) {
    clusterMarkerListener = listener;
    initListenersForClusterManagers(this, listener);
  }

  private void initListenersForClusterManagers(
      @Nullable ClusterListener clusterListener,
      @Nullable ClusterMarkerListener clusterMarkerListener) {
    for (Map.Entry<String, ClusterManager<MarkerBuilder>> entry :
        clusterManagerIdToManager.entrySet()) {
      initListenersForClusterManager(entry.getValue(), clusterListener, clusterMarkerListener);
    }
  }

  private void initListenersForClusterManager(
      ClusterManager<MarkerBuilder> clusterManager,
      @Nullable ClusterListener clusterListener,
      @Nullable ClusterMarkerListener clusterMarkerListener) {
    clusterManager.setOnClusterInfoWindowClickListener(clusterListener);
    clusterManager.setOnClusterClickListener(clusterListener);
    clusterManager.setOnClusterItemClickListener(clusterMarkerListener);
    clusterManager.setOnClusterItemInfoWindowClickListener(clusterMarkerListener);
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
    ClusterManager<MarkerBuilder> clusterManager =
        new ClusterManager<>(context, googleMap, markerManager);
    ClusterRenderer clusterRenderer = new ClusterRenderer(context, googleMap, clusterManager, this);
    clusterManager.setRenderer(clusterRenderer);
    initListenersForClusterManager(clusterManager, this, clusterMarkerListener);
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
    final ClusterManager<MarkerBuilder> clusterManager =
        clusterManagerIdToManager.remove(clusterManagerId);
    if (clusterManager == null) {
      return;
    }
    initListenersForClusterManager(clusterManager, null, null);
    clusterManager.clearItems();
    clusterManager.cluster();
  }

  public void addItem(MarkerBuilder item) {
    ClusterManager<MarkerBuilder> clusterManager =
        clusterManagerIdToManager.get(item.clusterManagerId());
    if (clusterManager != null) {
      clusterManager.addItem(item);
      clusterManager.cluster();
    }
  }

  public void removeItem(MarkerBuilder item) {
    ClusterManager<MarkerBuilder> clusterManager =
        clusterManagerIdToManager.get(item.clusterManagerId());
    if (clusterManager != null) {
      clusterManager.removeItem(item);
      clusterManager.cluster();
    }
  }

  void onClusterMarker(MarkerBuilder item, Marker marker) {
    if (clusterMarkerListener != null) {
      clusterMarkerListener.onClusterMarker(item, marker);
    }
  }

  @SuppressWarnings("unchecked")
  private static String getClusterManagerId(Object clusterManagerData) {
    Map<String, Object> clusterMap = (Map<String, Object>) clusterManagerData;
    return (String) clusterMap.get("clusterManagerId");
  }

  public void getClustersWithClusterManagerId(
      String clusterManagerId, MethodChannel.Result result) {
    ClusterManager<MarkerBuilder> clusterManager = clusterManagerIdToManager.get(clusterManagerId);
    if (clusterManager == null) {
      result.error(
          "Invalid clusterManagerId", "getClusters called with invalid clusterManagerId", null);
      return;
    }

    final Set<? extends Cluster<MarkerBuilder>> clusters =
        clusterManager.getAlgorithm().getClusters(googleMap.getCameraPosition().zoom);
    result.success(Convert.clustersToJson(clusterManagerId, clusters));
  }

  @Override
  public void onCameraIdle() {
    for (Map.Entry<String, ClusterManager<MarkerBuilder>> entry :
        clusterManagerIdToManager.entrySet()) {
      entry.getValue().onCameraIdle();
    }
  }

  @Override
  public boolean onClusterClick(Cluster<MarkerBuilder> cluster) {
    if (cluster.getSize() > 0) {
      MarkerBuilder[] builders = cluster.getItems().toArray(new MarkerBuilder[0]);
      String clusterManagerId = getClusterManagerIdFromMarkerBuilder(builders[0]);
      methodChannel.invokeMethod("cluster#onTap", Convert.clusterToJson(clusterManagerId, cluster));
    }
    return false;
  }

  @Override
  public void onClusterInfoWindowClick(Cluster<MarkerBuilder> cluster) {}

  @Override
  public void onClusterInfoWindowLongClick(Cluster<MarkerBuilder> cluster) {}

  private String getClusterManagerIdFromMarkerBuilder(MarkerBuilder item) {
    return item.clusterManagerId();
  }

  private static class ClusterRenderer extends DefaultClusterRenderer<MarkerBuilder> {
    private final ClusterManagersController clusterManagersController;

    public ClusterRenderer(
        Context context,
        GoogleMap map,
        ClusterManager<MarkerBuilder> clusterManager,
        ClusterManagersController clusterManagersController) {
      super(context, map, clusterManager);
      this.clusterManagersController = clusterManagersController;
    }

    @Override
    protected void onBeforeClusterItemRendered(
        @NonNull MarkerBuilder item, @NonNull MarkerOptions markerOptions) {
      // Builds new markerOptions for new marker created by the ClusterRenderer under
      // ClusterManager.
      item.build(markerOptions);
    }

    @Override
    protected void onClusterItemRendered(@NonNull MarkerBuilder item, @NonNull Marker marker) {
      super.onClusterItemRendered(item, marker);
      clusterManagersController.onClusterMarker(item, marker);
    }
  }

  public interface OnClusterMarker<T extends ClusterItem> {
    void onClusterMarker(T item, Marker marker);
  }
}
