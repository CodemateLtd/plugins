// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;
import 'dart:typed_data';

// Fake interface for the logic that this package needs from (web-only) dart:ui.
// This is conditionally exported so the analyzer sees these methods as available.

// ignore_for_file: avoid_classes_with_only_static_members
// ignore_for_file: camel_case_types

/// Shim for web_ui engine.PlatformViewRegistry
/// https://github.com/flutter/engine/blob/main/lib/web_ui/lib/ui.dart#L62
class platformViewRegistry {
  /// Shim for registerViewFactory
  /// https://github.com/flutter/engine/blob/main/lib/web_ui/lib/ui.dart#L72
  static bool registerViewFactory(
      String viewTypeId, html.Element Function(int viewId) viewFactory) {
    return false;
  }
}

/// Shim for web_ui engine.AssetManager.
/// https://github.com/flutter/engine/blob/main/lib/web_ui/lib/src/engine/assets.dart#L12
class webOnlyAssetManager {
  /// Shim for getAssetUrl.
  /// https://github.com/flutter/engine/blob/main/lib/web_ui/lib/src/engine/assets.dart#L45
  static String getAssetUrl(String asset) => '';
}

/// Signature of callbacks that have no arguments and return no data.
typedef VoidCallback = void Function();

/// Shim for web_ui engine.Image.
/// https://github.com/flutter/engine/blob/main/lib/web_ui/lib/painting.dart#L342
class Image {
  /// Shim for width.
  int get width => 0;

  /// Shim for height.
  int get height => 0;
}

/// Shim for web_ui engine.FrameInfo.
/// https://github.com/flutter/engine/blob/main/lib/web_ui/lib/painting.dart#L453
class FrameInfo {
  /// Shim for image.
  Image get image => Image();
}

/// Shim for web_ui engine.Codec.
/// https://github.com/flutter/engine/blob/main/lib/web_ui/lib/painting.dart#L460
class Codec {
  /// Shim for getNextFrame.
  Future<FrameInfo> getNextFrame() async {
    return FrameInfo();
  }
}

/// Shim for web_ui engine.WebOnlyImageCodecChunkCallback.
/// https://github.com/flutter/engine/blob/main/lib/web_ui/lib/painting.dart#L495
class WebOnlyImageCodecChunkCallback {}

/// Shim for web_ui engine.instantiateImageCodec.
/// https://github.com/flutter/engine/blob/main/lib/web_ui/lib/painting.dart#L472
Future<Codec> instantiateImageCodec(
  Uint8List list, {
  int? targetWidth,
  int? targetHeight,
  bool allowUpscaling = true,
}) async =>
    Codec();

/// Shim for web_ui engine.webOnlyInstantiateImageCodecFromUrl.
/// https://github.com/flutter/engine/blob/main/lib/web_ui/lib/painting.dart#L494
Future<Codec> webOnlyInstantiateImageCodecFromUrl(Uri uri,
        {WebOnlyImageCodecChunkCallback? chunkCallback}) async =>
    Codec();
