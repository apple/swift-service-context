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
project(CMakeConsumer LANGUAGES C Swift)

# Match the DLL runtime used by the Windows Swift SDK, including Debug builds.
if(WIN32 AND NOT DEFINED CMAKE_MSVC_RUNTIME_LIBRARY)
  set(CMAKE_MSVC_RUNTIME_LIBRARY MultiThreadedDLL)
endif()
find_package(SwiftServiceContext CONFIG REQUIRED)
add_executable(CMakeConsumer main.swift)
target_link_libraries(CMakeConsumer PRIVATE SwiftServiceContext::ServiceContextModule SwiftServiceContext::InstrumentationBaggage)
enable_testing()
add_test(NAME CMakeConsumer COMMAND CMakeConsumer)
if(WIN32)
  set_tests_properties(CMakeConsumer PROPERTIES ENVIRONMENT_MODIFICATION
    "PATH=path_list_prepend:$<TARGET_FILE_DIR:SwiftServiceContext::InstrumentationBaggage>;PATH=path_list_prepend:$<TARGET_FILE_DIR:SwiftServiceContext::ServiceContextModule>")
endif()
