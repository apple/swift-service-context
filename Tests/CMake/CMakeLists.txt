# SPDX-License-Identifier: Apache-2.0

cmake_minimum_required(VERSION 3.29)
project(CMakeConsumer LANGUAGES Swift)
find_package(SwiftServiceContext CONFIG REQUIRED)
add_executable(CMakeConsumer main.swift)
target_link_libraries(CMakeConsumer PRIVATE SwiftServiceContext::ServiceContextModule SwiftServiceContext::InstrumentationBaggage)
enable_testing()
add_test(NAME CMakeConsumer COMMAND CMakeConsumer)
if(WIN32)
  set_tests_properties(CMakeConsumer PROPERTIES ENVIRONMENT_MODIFICATION
    "PATH=path_list_prepend:$<TARGET_FILE_DIR:SwiftServiceContext::InstrumentationBaggage>;PATH=path_list_prepend:$<TARGET_FILE_DIR:SwiftServiceContext::ServiceContextModule>")
endif()
