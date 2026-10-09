##===----------------------------------------------------------------------===##
##
## This source file is part of the Swift Service Context open source project
##
## Copyright (c) 2026 Apple Inc. and the Swift Service Context project authors
## Licensed under Apache License v2.0
##
## See LICENSE.txt for license information
## See CONTRIBUTORS.txt for the list of Swift Service Context project authors
##
## SPDX-License-Identifier: Apache-2.0
##
##===----------------------------------------------------------------------===##

cmake_minimum_required(VERSION 3.29)
project(SwiftServiceContext LANGUAGES C Swift)

# Match the DLL runtime used by the Windows Swift SDK, including Debug builds.
if(WIN32 AND NOT DEFINED CMAKE_MSVC_RUNTIME_LIBRARY)
  set(CMAKE_MSVC_RUNTIME_LIBRARY MultiThreadedDLL)
endif()

if(CMAKE_Swift_COMPILER_VERSION VERSION_LESS 6.2)
  message(FATAL_ERROR "Swift 6.2 or newer is required")
endif()
if(WIN32 AND BUILD_SHARED_LIBS AND CMAKE_C_COMPILER_FRONTEND_VARIANT STREQUAL "MSVC")
  message(FATAL_ERROR
    "Swift shared-library builds require Clang's GNU-style driver on Windows. Configure with -DCMAKE_C_COMPILER=clang.")
endif()
set(CMAKE_Swift_LANGUAGE_VERSION 6)
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)
include(cmake/SwiftLibrary.cmake)

add_library(ServiceContextModule
  Sources/ServiceContextModule/ServiceContext.swift
  Sources/ServiceContextModule/ServiceContextKey.swift
)
add_library(SwiftServiceContext::ServiceContextModule ALIAS ServiceContextModule)
_swift_service_context_library(ServiceContextModule)

# This compatibility module has no runtime symbols, so Windows cannot create
# a DLL import library for it. Preserve the module in a static archive instead.
set(compatibility_library_type)
if(WIN32)
  set(compatibility_library_type STATIC)
endif()
add_library(InstrumentationBaggage ${compatibility_library_type}
  Sources/InstrumentationBaggage/CompatibilityShims.swift
)
add_library(SwiftServiceContext::InstrumentationBaggage ALIAS InstrumentationBaggage)
_swift_service_context_library(InstrumentationBaggage)
target_link_libraries(InstrumentationBaggage PUBLIC ServiceContextModule)

set(package_directory "${CMAKE_INSTALL_LIBDIR}/cmake/SwiftServiceContext")
configure_package_config_file(cmake/SwiftServiceContextConfig.cmake.in
  "${CMAKE_CURRENT_BINARY_DIR}/SwiftServiceContextConfig.cmake"
  INSTALL_DESTINATION "${package_directory}")
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/SwiftServiceContextConfig.cmake"
  DESTINATION "${package_directory}")
install(EXPORT SwiftServiceContextTargets NAMESPACE SwiftServiceContext::
  DESTINATION "${package_directory}")
export(EXPORT SwiftServiceContextTargets NAMESPACE SwiftServiceContext::
  FILE "${CMAKE_CURRENT_BINARY_DIR}/SwiftServiceContextTargets.cmake")
