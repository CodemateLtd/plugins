cmake_minimum_required(VERSION 3.15)
set(PROJECT_NAME "camera_windows")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must
# not be changed
set(PLUGIN_NAME "${PROJECT_NAME}_plugin")

list(APPEND PLUGIN_SOURCES
  "camera_plugin.cpp"
  "camera_plugin.h"
  "capture_controller.cpp"
  "capture_controller.h"
  "string_utils.cpp"
  "string_utils.h"
  "device_info.cpp"
  "device_info.h"
)

add_library(${PLUGIN_NAME} SHARED
  "camera_windows.cpp"
  "include/camera_windows/camera_windows.h"
  ${PLUGIN_SOURCES}
)

apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE 
  mf mfplat mfreadwrite mfuuid d3d11 flutter flutter_wrapper_plugin)

# List of absolute paths to libraries that should be bundled with the plugin
set(camera_windows_bundled_libraries
  ""
  PARENT_SCOPE
)
