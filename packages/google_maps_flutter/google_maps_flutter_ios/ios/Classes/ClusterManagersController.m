// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ClusterManagersController.h"
#import "FLTGoogleMapJSONConversions.h"

@interface FLTClusterManagersController ()

@property(strong, nonatomic) NSMutableDictionary *clusterManagerIdToManagers;
@property(strong, nonatomic) FlutterMethodChannel *methodChannel;
@property(weak, nonatomic) GMSMapView *mapView;

@end

@implementation FLTClusterManagersController
- (instancetype)initWithMethodChannel:(FlutterMethodChannel *)methodChannel mapView:(GMSMapView *)mapView {
  self = [super init];
  if (self) {
    _methodChannel = methodChannel;
    _mapView = mapView;
    _clusterManagerIdToManagers = [[NSMutableDictionary alloc] init];
  }
  return self;
}

- (void)addClusterManagers:(NSArray *)clusterManagersToAdd {
  for (NSDictionary *clusterDict in clusterManagersToAdd) {
    NSString *identifier = clusterDict[@"clusterManagerId"];
    id<GMUClusterAlgorithm> algorithm = [[GMUNonHierarchicalDistanceBasedAlgorithm alloc] init];
    id<GMUClusterIconGenerator> iconGenerator = [[GMUDefaultClusterIconGenerator alloc] init];
    id<GMUClusterRenderer> renderer =
        [[GMUDefaultClusterRenderer alloc] initWithMapView:_mapView
                                      clusterIconGenerator:iconGenerator];
    GMUClusterManager *clusterManager = [[GMUClusterManager alloc] initWithMap:_mapView
                                                                     algorithm:algorithm
                                                                      renderer:renderer];
    self.clusterManagerIdToManagers[identifier] = clusterManager;
  }
}

- (void)removeClusterManagers:(NSArray *)identifiers {
  for (NSString *identifier in identifiers) {
    GMUClusterManager *clusterManager = [self.clusterManagerIdToManagers objectForKey:identifier];
    if (!clusterManager) {
      continue;
    }
    [clusterManager clearItems];
    [self.clusterManagerIdToManagers removeObjectForKey:identifier];
  }
}

- (void)addItem:(GMSMarker *)marker clusterManagerId:(NSString *)clusterManagerId {
  GMUClusterManager *clusterManager =
      [self.clusterManagerIdToManagers objectForKey:clusterManagerId];
  if (marker && clusterManager != (id)[NSNull null]) {
    [clusterManager addItem:(id<GMUClusterItem>)marker];
  }
}

- (void)removeItem:(GMSMarker *)marker clusterManagerId:(NSArray *)clusterManagerId {
  GMUClusterManager *clusterManager =
      [self.clusterManagerIdToManagers objectForKey:clusterManagerId];
  if (marker && clusterManager != (id)[NSNull null]) {
    [clusterManager removeItem:(id<GMUClusterItem>)marker];
  }
}

- (void)clusterAll {
  for (GMUClusterManager *clusterManager in [self.clusterManagerIdToManagers allValues]) {
    [clusterManager cluster];
  }
}

- (void)getClustersWithIdentifier:(NSString *)identifier result:(FlutterResult)result {
  GMUClusterManager *clusterManager = [self.clusterManagerIdToManagers objectForKey:identifier];
    
    if (!clusterManager) {
        result([FlutterError errorWithCode:@"Invalid clusterManagerId"
                                   message:@"getClusters called with invalid clusterManagerId"
                                   details:nil]);
        return;
    }
    
    NSMutableArray *response = [[NSMutableArray alloc] init];

    NSUInteger integralZoom = (NSUInteger)floorf(_mapView.camera.zoom + 0.5f);
    NSArray<id<GMUCluster>> *clusters = [clusterManager.algorithm clustersAtZoom:integralZoom];
    for (id<GMUCluster> cluster in clusters) {

      NSDictionary *clusterDict = [self getClusterDict:cluster];
      if (clusterDict == nil) {
            continue;
      }
      [response addObject:clusterDict];
    }
    result(response);
}

- (BOOL)didTapCluster:(GMUStaticCluster *)cluster {
  NSDictionary *clusterDict = [self getClusterDict:cluster];
  if (clusterDict == nil) {
    return NO;
  }

  [self.methodChannel
      invokeMethod:@"cluster#onTap"
         arguments:clusterDict];
  return NO;
}

- (NSString *)getClusterManagerIdFrom:(GMUStaticCluster *)cluster {
    if ([cluster.items count] == 0) {
      return nil;
    }

    GMSMarker *firstMarker = (GMSMarker *)cluster.items[0];
    NSArray *firstMarkerUserData = firstMarker.userData;
    if ([firstMarkerUserData count] != 2) {
      return nil;
    }

    NSString *clusterManagerId = firstMarker.userData[1];
    if (clusterManagerId == (id)[NSNull null]) {
      return nil;
    }
    return clusterManagerId;
}

- (NSDictionary *)getClusterDict:(GMUStaticCluster *)cluster {
    NSString *clusterManagerId = [self getClusterManagerIdFrom:cluster];
    if (clusterManagerId == nil) {
      return nil;
    }

    NSMutableArray *markerIds = [[NSMutableArray alloc] init];
    GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] init];

    for (GMSMarker *marker in cluster.items) {
      NSString *markerId = marker.userData[0];
      [markerIds addObject:markerId];
      bounds = [bounds includingCoordinate:marker.position];
    }
    
    return @{
        @"clusterManagerId" : clusterManagerId,
        @"position" : [FLTGoogleMapJSONConversions arrayFromLocation:cluster.position],
        @"bounds" : [FLTGoogleMapJSONConversions dictionaryFromCoordinateBounds:bounds],
        @"markerIds" : markerIds
      };
}

@end
