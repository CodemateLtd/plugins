// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "GoogleMapMarkerClusterController.h"
#import "FLTGoogleMapJSONConversions.h"

@interface FLTGoogleMapMarkerClusterController ()

@property(strong, nonatomic) FlutterMethodChannel *methodChannel;
@property(weak, nonatomic) NSObject<FlutterPluginRegistrar> *registrar;
@property(weak, nonatomic) GMSMapView *mapView;
@property(strong, nonatomic) GMUClusterManager *clusterManager;
@property(nonatomic, strong) FLTMarkersController *markersController;

@end

@implementation FLTGoogleMapMarkerClusterController

- (instancetype)initMarkerClusterWithMarkers:(NSArray *)markers
                            identifier:(NSString *)identifier
                            mapView:(GMSMapView *)mapView
                            methodChannel:(FlutterMethodChannel *)methodChannel
                            registrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  self = [super init];
  if (self) {
    _methodChannel = methodChannel;
    _mapView = mapView;
    _registrar = registrar;
    id<GMUClusterAlgorithm> algorithm =
        [[GMUNonHierarchicalDistanceBasedAlgorithm alloc] init];
    id<GMUClusterIconGenerator> iconGenerator =
        [[GMUDefaultClusterIconGenerator alloc] init];
    id<GMUClusterRenderer> renderer =
        [[GMUDefaultClusterRenderer alloc] initWithMapView:_mapView
                                      clusterIconGenerator:iconGenerator];
    _clusterManager =
      [[GMUClusterManager alloc] initWithMap:_mapView
                                   algorithm:algorithm
                                    renderer:renderer];
    _markersController = [[FLTMarkersController alloc] initWithMethodChannel:_methodChannel
                                  mapView:_mapView
                                registrar:registrar];
    [_markersController setClusterManager:_clusterManager];
    [_markersController addMarkers:markers];
  }
  return self;
}

@end

@interface FLTMarkerClustersController ()

@property(strong, nonatomic) NSMutableDictionary *clusterIdentifierToController;
@property(strong, nonatomic) FlutterMethodChannel *methodChannel;
@property(weak, nonatomic) NSObject<FlutterPluginRegistrar> *registrar;
@property(weak, nonatomic) GMSMapView *mapView;

@end

@implementation FLTMarkerClustersController

- (instancetype)initWithMethodChannel:(FlutterMethodChannel *)methodChannel
                              mapView:(GMSMapView *)mapView
                            registrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  self = [super init];
  if (self) {
    _methodChannel = methodChannel;
    _mapView = mapView;
    _clusterIdentifierToController = [[NSMutableDictionary alloc] init];
    _registrar = registrar;
  }
  return self;
}

- (void)addMarkerClusters:(NSArray *)markerClustersToAdd {
  for (NSDictionary *cluster in markerClustersToAdd) {
    NSString *identifier = cluster[@"clusterId"];
    FLTGoogleMapMarkerClusterController *controller =
        [[FLTGoogleMapMarkerClusterController alloc] initMarkerClusterWithMarkers:cluster[@"markers"]
                                                          identifier:identifier
                                                          mapView:self.mapView
                                                          methodChannel: self.methodChannel
                                                          registrar: self.registrar];
    self.clusterIdentifierToController[identifier] = controller;
  }
}

@end
