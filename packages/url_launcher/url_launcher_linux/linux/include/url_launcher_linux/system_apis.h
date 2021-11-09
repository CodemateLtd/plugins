// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef PACKAGES_URL_LAUNCHER_URL_LAUNCHER_LINUX_LINUX_INCLUDE_URL_LAUNCHER_SYSTEM_APIS_H_
#define PACKAGES_URL_LAUNCHER_URL_LAUNCHER_LINUX_LINUX_INCLUDE_URL_LAUNCHER_SYSTEM_APIS_H_

// A mockable system call struct.

#include <glib-object.h>
#include <gtk/gtk.h>

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlUrlLauncherSystemApis, fl_url_launcher_system_apis, FL,
                     URL_LAUNCHER_SYSTEM_APIS, GObject)

struct _FlUrlLauncherSystemApis {
  GObject parent_instance;

  GAppInfo *(*get_app_info_for_scheme)(const char *uri_scheme);
  gboolean (*launch_uri)(const char *uri, GAppLaunchContext *context,
                         GError **error);
};

G_END_DECLS

#endif  // PACKAGES_URL_LAUNCHER_URL_LAUNCHER_LINUX_LINUX_INCLUDE_URL_LAUNCHER_SYSTEM_APIS_H_
