# SPDX-License-Identifier: Apache-2.0

cmake_minimum_required(VERSION 3.29)
project(SwiftServiceContext LANGUAGES C Swift)

if(CMAKE_Swift_COMPILER_VERSION VERSION_LESS 6.2)
  message(FATAL_ERROR "Swift 6.2 or newer is required")
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
swift_library(ServiceContextModule)

add_library(InstrumentationBaggage
  Sources/InstrumentationBaggage/CompatibilityShims.swift
)
add_library(SwiftServiceContext::InstrumentationBaggage ALIAS InstrumentationBaggage)
swift_library(InstrumentationBaggage)
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
