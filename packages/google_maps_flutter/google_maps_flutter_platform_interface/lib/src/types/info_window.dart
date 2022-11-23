// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Offset;
import 'package:flutter/foundation.dart' show immutable, VoidCallback;

import 'types.dart';

/// Text labels for a [Marker] info window.
@immutable
class InfoWindow {
  /// Creates an immutable representation of a label on for [Marker].
  const InfoWindow({
    this.title,
    this.snippet,
    this.anchor = const Offset(0.5, 0.0),
    this.onTap,
  });

  /// Text labels specifying that no text is to be displayed.
  static const InfoWindow noText = InfoWindow();

  /// Text displayed in an info window when the user taps the marker.
  ///
  /// A null value means no title.
  final String? title;

  /// Additional text displayed below the [title].
  ///
  /// A null value means no additional text.
  final String? snippet;

  /// The icon image point that will be the anchor of the info window when
  /// displayed.
  ///
  /// The image point is specified in normalized coordinates: An anchor of
  /// (0.0, 0.0) means the top left corner of the image. An anchor
  /// of (1.0, 1.0) means the bottom right corner of the image.
  final Offset anchor;

  /// onTap callback for this [InfoWindow].
  final VoidCallback? onTap;

  /// Creates a new [InfoWindow] object whose values are the same as this instance,
  /// unless overwritten by the specified parameters.
  InfoWindow copyWith({
    String? titleParam,
    String? snippetParam,
    Offset? anchorParam,
    VoidCallback? onTapParam,
  }) {
    return InfoWindow(
      title: titleParam ?? title,
      snippet: snippetParam ?? snippet,
      anchor: anchorParam ?? anchor,
      onTap: onTapParam ?? onTap,
    );
  }

  /// Converts this object to something serializable in JSON.
  Object toJson() {
    final Map<String, Object> json = <String, Object>{};

    void addIfPresent(String fieldName, Object? value) {
      if (value != null) {
        json[fieldName] = value;
      }
    }

    addIfPresent('title', title);
    addIfPresent('snippet', snippet);
    addIfPresent('anchor', <Object>[anchor.dx, anchor.dy]);

    return json;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is InfoWindow &&
        title == other.title &&
        snippet == other.snippet &&
        anchor == other.anchor;
  }

  @override
  int get hashCode => Object.hash(title.hashCode, snippet, anchor);

  @override
  String toString() {
    return 'InfoWindow{title: $title, snippet: $snippet, anchor: $anchor}';
  }
}
