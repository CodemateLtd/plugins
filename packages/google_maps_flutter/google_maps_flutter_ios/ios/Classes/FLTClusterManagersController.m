// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FLTClusterManagersController.h"
#import "FLTGoogleMapJSONConversions.h"

@interface FLTClusterManagersController ()

@property(strong, nonatomic) NSMutableDictionary *clusterManagerIdToManager;
@property(strong, nonatomic) FlutterMethodChannel *methodChannel;
@property(weak, nonatomic) GMSMapView *mapView;

@end

@implementation FLTClusterManagersController

- (instancetype)init:(FlutterMethodChannel *)methodChannel
             mapView:(GMSMapView *)mapView {
  self = [super init];
  if (self) {
    _methodChannel = methodChannel;
    _mapView = mapView;
    _clusterManagerIdToManager = [[NSMutableDictionary alloc] init];
  }
  return self;
}

- (void)addClusterManagers:(NSArray *)clusterManagersToAdd {
  for (NSDictionary *clusterManager in clusterManagersToAdd) {
    NSString *identifier = clusterManager[@"clusterManagerId"];
    NSLog(@"FLTClusterManagersController addClusterManagers clusterManagerId = %@", identifier);
    id<GMUClusterAlgorithm> algorithm = [[GMUNonHierarchicalDistanceBasedAlgorithm alloc] init];
    id<GMUClusterIconGenerator> iconGenerator = [[GMUDefaultClusterIconGenerator alloc] init];
    id<GMUClusterRenderer> renderer =
        [[GMUDefaultClusterRenderer alloc] initWithMapView:_mapView
                                      clusterIconGenerator:iconGenerator];
    GMUClusterManager *clusterManager = [[GMUClusterManager alloc] initWithMap:_mapView
                                                                     algorithm:algorithm
                                                                      renderer:renderer];
    self.clusterManagerIdToManager[identifier] = clusterManager;
  }
}

- (void)changeClusterManagers:(NSArray *)clusterManagersToChange {
  for (NSDictionary *clusterManager in clusterManagersToChange) {
    NSLog(@"FLTClusterManagersController changeClusterManagers clusterManagerId = %@",
          clusterManager);
    NSString *identifier = clusterManager[@"clusterManagerId"];
    GMUClusterManager *clusterManager = self.clusterManagerIdToManager[identifier];
    if (!clusterManager) {
      continue;
    }
    // TODO: change the cluster
  }
}

- (void)removeClusterManagers:(NSArray *)identifiers {
  for (NSString *identifier in identifiers) {
    NSLog(@"FLTClusterManagersController removeClusterManagers clusterManagerId = %@", identifier);
    GMUClusterManager *clusterManager = self.clusterManagerIdToManager[identifier];
    if (!clusterManager) {
      continue;
    }
    [clusterManager clearItems];
    [self.clusterManagerIdToManager removeObjectForKey:identifier];
  }
}

- (void)addItem:(GMSMarker *)marker clusterManagerId:(NSString *)clusterManagerId {
  NSLog(@"FLTClusterManagersController addItemWithPosition clusterManagerId = %@",
        clusterManagerId);
  GMUClusterManager *clusterManager = self.clusterManagerIdToManager[clusterManagerId];
  if (marker && clusterManager != (id)[NSNull null]) {
    NSLog(@"addItem to ClusterManager");
    [clusterManager addItem:marker];
    [clusterManager cluster];
  } else {
    NSLog(@"MISSING ClusterManager");
  }
}

- (void)removeItem:(GMSMarker *)marker clusterManagerId:(NSArray *)clusterManagerId {
  GMUClusterManager *clusterManager = self.clusterManagerIdToManager[clusterManagerId];
  if (marker && clusterManager != (id)[NSNull null]) {
    NSLog(@"remove marker ClusterManager");
    [clusterManager removeItem:marker];
    [clusterManager cluster];
  } else {
    NSLog(@"MISSING ClusterManager");
  }
}

- (bool)didTapCluster:(GMUStaticCluster *)cluster {
  if ([cluster.items count] == 0){
    return NO;
  }

  GMSMarker *firstMarker = cluster.items[0];
  NSArray *firstMarkerUserData = firstMarker.userData;
  if ([firstMarkerUserData count] != 2){
    return NO;
  }

  NSString *clusterManagerId = firstMarker.userData[1];
  if (clusterManagerId == [NSNull null]){
    return NO;
  }
    
  NSMutableArray *markerIds = [[NSMutableArray alloc] init];
  GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] init];

  for (GMSMarker *marker in cluster.items) {
      NSString *markerId = marker.userData[0];
      [markerIds addObject:markerId];
      bounds = [bounds includingCoordinate:marker.position];
  }

  [self.methodChannel invokeMethod:@"cluster#onTap"
                      arguments:@{
                        @"clusterManagerId": clusterManagerId,
                        @"position" : [FLTGoogleMapJSONConversions arrayFromLocation:cluster.position],
                        @"bounds" :  [FLTGoogleMapJSONConversions dictionaryFromCoordinateBounds:bounds],
                        @"markerIds" : markerIds
                      }];
  return NO;
}
@end
