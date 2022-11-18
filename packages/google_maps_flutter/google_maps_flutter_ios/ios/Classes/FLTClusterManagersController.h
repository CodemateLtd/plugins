// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Flutter/Flutter.h>
#import <Google-Maps-iOS-Utils/GMUClusterAlgorithm.h>
#import <Google-Maps-iOS-Utils/GMUClusterIconGenerator.h>
#import <Google-Maps-iOS-Utils/GMUClusterManager.h>
#import <Google-Maps-iOS-Utils/GMUClusterRenderer.h>
#import <Google-Maps-iOS-Utils/GMUDefaultClusterIconGenerator.h>
#import <Google-Maps-iOS-Utils/GMUDefaultClusterRenderer.h>
#import <Google-Maps-iOS-Utils/GMUGridBasedClusterAlgorithm.h>
#import <Google-Maps-iOS-Utils/GMUNonHierarchicalDistanceBasedAlgorithm.h>
#import <Google-Maps-iOS-Utils/GMUSimpleClusterAlgorithm.h>
#import <Google-Maps-iOS-Utils/GMUStaticCluster.h>
#import <GoogleMaps/GoogleMaps.h>

NS_ASSUME_NONNULL_BEGIN

@interface FLTClusterManagersController : NSObject
- (instancetype)init:(FlutterMethodChannel *)methodChannel mapView:(GMSMapView *)mapView;
- (void)addClusterManagers:(NSArray *)clusterManagersToAdd;
- (void)removeClusterManagers:(NSArray *)identifiers;
- (void)addItem:(GMSMarker *)marker clusterManagerId:(NSString *)clusterManagerId;
- (void)removeItem:(GMSMarker *)marker clusterManagerId:(NSString *)clusterManagerId;
- (void)getClustersWithIdentifier:(NSString *)identifier result:(FlutterResult)result;
- (bool)didTapCluster:(GMUStaticCluster *)cluster;
- (void)clusterAll;
@end

NS_ASSUME_NONNULL_END
