//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Service Context open source project
//
// Copyright (c) 2020-2026 Apple Inc. and the Swift Service Context project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Service Context project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Testing

import ServiceContextModule

// `ServiceContext`'s full behavior test suite now lives with its implementation in
// swift-distributed-tracing's `ServiceContextCoreTests`. These tests only confirm the
// backward-compatibility re-export shim still exposes a working, usable API.
@Suite("ServiceContextModule compatibility shim")
struct CompatibilityShimTests {
    private enum TestKey: ServiceContextKey {
        typealias Value = String
    }

    @Test("ServiceContext is usable through the ServiceContextModule import")
    func serviceContextUsableThroughShim() {
        var context = ServiceContext.topLevel
        #expect(context.isEmpty)

        context[TestKey.self] = "hello"
        #expect(context[TestKey.self] == "hello")
        #expect(context.count == 1)
    }

    @Test("ServiceContext propagates through task-local current")
    func taskLocalPropagation() {
        var context = ServiceContext.topLevel
        context[TestKey.self] = "propagated"

        ServiceContext.withValue(context) {
            #expect(ServiceContext.current?[TestKey.self] == "propagated")
        }
    }
}
