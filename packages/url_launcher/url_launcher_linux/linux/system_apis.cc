#include "include/url_launcher_linux/system_apis.h"

#include <gio/gio.h>
#include <glib-object.h>
#include <gtk/gtk.h>

G_DEFINE_TYPE(FlUrlLauncherSystemApis, fl_url_launcher_system_apis,
              G_TYPE_OBJECT)

static void fl_url_launcher_system_apis_class_init(
    FlUrlLauncherSystemApisClass *klass) {}
static void fl_url_launcher_system_apis_init(FlUrlLauncherSystemApis *self) {
  self->get_app_info_for_scheme = g_app_info_get_default_for_uri_scheme;
  self->launch_uri = g_app_info_launch_default_for_uri;
}
