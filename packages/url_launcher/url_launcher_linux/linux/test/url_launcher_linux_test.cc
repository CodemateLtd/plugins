// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#include <flutter_linux/flutter_linux.h>
#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include <memory>
#include <string>

#include "include/url_launcher_linux/system_apis.h"
#include "include/url_launcher_linux/url_launcher_plugin.h"
#include "url_launcher_plugin_private.h"

namespace url_launcher_plugin {
namespace test {

GAppInfo* g_app_info_get_default_for_uri_scheme_mock(const char* uri_scheme) {
  return nullptr;
}

TEST(UrlLauncherPlugin, CanLaunchSuccess) {
  g_autoptr(FlUrlLauncherPlugin) _plugin = FL_URL_LAUNCHER_PLUGIN(
      g_object_new(fl_url_launcher_plugin_get_type(), nullptr));
  g_autoptr(FlUrlLauncherSystemApis) _system_apis = FL_URL_LAUNCHER_SYSTEM_APIS(
      g_object_new(fl_url_launcher_system_apis_get_type(), nullptr));
  fl_url_launcher_plugin_set_system_apis(_plugin, _system_apis);
  g_autoptr(FlValue) args = fl_value_new_map();
  fl_value_set_string_take(args, "url",
                           fl_value_new_string("https://flutter.dev"));
  FlMethodResponse* response = can_launch(_plugin, args);
  ASSERT_NE(response, nullptr);
  ASSERT_TRUE(FL_IS_METHOD_SUCCESS_RESPONSE(response));
  g_autoptr(FlValue) expected = fl_value_new_bool(true);
  EXPECT_TRUE(fl_value_equal(fl_method_success_response_get_result(
                                 FL_METHOD_SUCCESS_RESPONSE(response)),
                             expected));
}

TEST(UrlLauncherPlugin, CanLaunchFailureUnhandled) {
  g_autoptr(FlUrlLauncherPlugin) _plugin = FL_URL_LAUNCHER_PLUGIN(
      g_object_new(fl_url_launcher_plugin_get_type(), nullptr));
  g_autoptr(FlUrlLauncherSystemApis) _system_apis = FL_URL_LAUNCHER_SYSTEM_APIS(
      g_object_new(fl_url_launcher_system_apis_get_type(), nullptr));
  fl_url_launcher_plugin_set_system_apis(_plugin, _system_apis);
  g_autoptr(FlValue) args = fl_value_new_map();
  fl_value_set_string_take(args, "url", fl_value_new_string("madeup:scheme"));
  FlMethodResponse* response = can_launch(_plugin, args);
  ASSERT_NE(response, nullptr);
  ASSERT_TRUE(FL_IS_METHOD_SUCCESS_RESPONSE(response));
  g_autoptr(FlValue) expected = fl_value_new_bool(false);
  EXPECT_TRUE(fl_value_equal(fl_method_success_response_get_result(
                                 FL_METHOD_SUCCESS_RESPONSE(response)),
                             expected));
}

TEST(UrlLauncherPlugin, CanLaunchFileSuccess) {
  g_autoptr(FlUrlLauncherPlugin) _plugin = FL_URL_LAUNCHER_PLUGIN(
      g_object_new(fl_url_launcher_plugin_get_type(), nullptr));
  g_autoptr(FlUrlLauncherSystemApis) _system_apis = FL_URL_LAUNCHER_SYSTEM_APIS(
      g_object_new(fl_url_launcher_system_apis_get_type(), nullptr));
  fl_url_launcher_plugin_set_system_apis(_plugin, _system_apis);
  g_autoptr(FlValue) args = fl_value_new_map();
  fl_value_set_string_take(args, "url", fl_value_new_string("file:/"));
  FlMethodResponse* response = can_launch(_plugin, args);
  ASSERT_NE(response, nullptr);
  ASSERT_TRUE(FL_IS_METHOD_SUCCESS_RESPONSE(response));
  g_autoptr(FlValue) expected = fl_value_new_bool(true);
  EXPECT_TRUE(fl_value_equal(fl_method_success_response_get_result(
                                 FL_METHOD_SUCCESS_RESPONSE(response)),
                             expected));
}

TEST(UrlLauncherPlugin, CanLaunchFailureInvalidFileExtension) {
  g_autoptr(FlUrlLauncherPlugin) _plugin = FL_URL_LAUNCHER_PLUGIN(
      g_object_new(fl_url_launcher_plugin_get_type(), nullptr));
  g_autoptr(FlUrlLauncherSystemApis) _system_apis = FL_URL_LAUNCHER_SYSTEM_APIS(
      g_object_new(fl_url_launcher_system_apis_get_type(), nullptr));
  fl_url_launcher_plugin_set_system_apis(_plugin, _system_apis);
  g_autoptr(FlValue) args = fl_value_new_map();
  fl_value_set_string_take(
      args, "url", fl_value_new_string("file:///madeup.madeupextension"));
  FlMethodResponse* response = can_launch(_plugin, args);
  ASSERT_NE(response, nullptr);
  ASSERT_TRUE(FL_IS_METHOD_SUCCESS_RESPONSE(response));
  g_autoptr(FlValue) expected = fl_value_new_bool(false);
  EXPECT_TRUE(fl_value_equal(fl_method_success_response_get_result(
                                 FL_METHOD_SUCCESS_RESPONSE(response)),
                             expected));
}

// For consistency with the established mobile implementations,
// an invalid URL should return false, not an error.
TEST(UrlLauncherPlugin, CanLaunchFailureInvalidUrl) {
  g_autoptr(FlValue) args = fl_value_new_map();
  fl_value_set_string_take(args, "url", fl_value_new_string(""));
  FlMethodResponse* response = can_launch(nullptr, args);
  ASSERT_NE(response, nullptr);
  ASSERT_TRUE(FL_IS_METHOD_SUCCESS_RESPONSE(response));
  g_autoptr(FlValue) expected = fl_value_new_bool(false);
  EXPECT_TRUE(fl_value_equal(fl_method_success_response_get_result(
                                 FL_METHOD_SUCCESS_RESPONSE(response)),
                             expected));
}

}  // namespace test
}  // namespace url_launcher_plugin
