cmake_minimum_required(VERSION 3.0.2)

project(kvs_webrtc_stream)

set(CMAKE_CXX_STANDARD 11)

option(BUILD_SAMPLE "Build available samples" OFF)
option(BUILD_STATIC_LIBS "Build static libraries" ON)

find_package(PkgConfig REQUIRED)
pkg_check_modules(GSTLIBS REQUIRED
  gstreamer-1.0
  glib-2.0
  gstreamer-app-1.0
  gobject-2.0
)

include(FetchContent)
FetchContent_Declare(
  webrtc
  GIT_REPOSITORY https://github.com/awslabs/amazon-kinesis-video-streams-webrtc-sdk-c
  GIT_TAG        v1.7.3
  GIT_SHALLOW   TRUE
)

FetchContent_GetProperties(webrtc)
if(NOT webrtc_POPULATED)
  FetchContent_Populate(webrtc)
  add_subdirectory(${webrtc_SOURCE_DIR} ${webrtc_BINARY_DIR} EXCLUDE_FROM_ALL)
endif()

include_directories(include)
include_directories(${webrtc_SOURCE_DIR}/src/include)
include_directories(${webrtc_SOURCE_DIR}/open-source/include)
include_directories(${GSTLIBS_INCLUDE_DIRS})

link_directories(${webrtc_SOURCE_DIR}/open-source/lib)
link_directories(${GSTLIBS_LIBRARY_DIRS})

add_executable(
  iot_stream
  src/main.c
  src/Common.c
)
target_link_libraries(
  iot_stream
  kvsWebrtcClient
  kvsWebrtcSignalingClient
  ${GSTLIBS_LIBRARIES}
  kvsCommonLws
  kvspicUtils
  websockets
)
