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
#import <GoogleMaps/GoogleMaps.h>
#import "GoogleMapController.h"

NS_ASSUME_NONNULL_BEGIN

// Defines marker cluster controllable by Flutter.
@interface FLTGoogleMapMarkerClusterController : NSObject
- (instancetype)initMarkerClusterWithMarkers:(NSArray *)markers
                                  identifier:(NSString *)identifier
                                     mapView:(GMSMapView *)mapView
                               methodChannel:(FlutterMethodChannel *)methodChannel
                                   registrar:(NSObject<FlutterPluginRegistrar> *)registrar;
@end

@interface FLTMarkerClustersController : NSObject
- (instancetype)initWithMethodChannel:(FlutterMethodChannel *)methodChannel
                              mapView:(GMSMapView *)mapView
                            registrar:(NSObject<FlutterPluginRegistrar> *)registrar;
- (void)addMarkerClusters:(NSArray *)markerClusterManagersToAdd;
@end

NS_ASSUME_NONNULL_END
