// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FLTClusterManagersController.h"
#import "FLTGoogleMapJSONConversions.h"

@interface FLTClusterManagersController ()

@property(strong, nonatomic) NSMutableDictionary *clusterManagerIdToManager;
@property(strong, nonatomic) GMSMapView *mapView;

@end

@implementation FLTClusterManagersController

- (instancetype)initWithMapView:(GMSMapView *)mapView {
  self = [super init];
  if (self) {
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
  if (clusterManager != (id)[NSNull null]) {
    [clusterManager addItem:marker];
    [clusterManager cluster];
  } else {
    NSLog(@"MISSING ClusterManager");
  }
}

- (void)changeItem:(NSDictionary *)marker {
}

- (void)removeItemById:(NSString *)markerIdentifier {
}
@end
