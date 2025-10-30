//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Service Context open source project
//
// Copyright (c) 2020-2021 Apple Inc. and the Swift Service Context project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Service Context project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Testing

@testable import ServiceContextModule

@Suite("ServiceContext Tests")
struct ServiceContextTests {
    @Test("Top-level ServiceContext is empty")
    func topLevelServiceContextIsEmpty() {
        let context = ServiceContext.topLevel

        #expect(context.isEmpty)
        #expect(context.count == 0)
    }

    @Test("Read and write values through subscript")
    func readAndWriteThroughSubscript() throws {
        var context = ServiceContext.topLevel
        #expect(context[FirstTestKey.self] == nil)
        #expect(context[SecondTestKey.self] == nil)

        context[FirstTestKey.self] = 42
        context[SecondTestKey.self] = 42.0

        #expect(!context.isEmpty)
        #expect(context.count == 2)
        #expect(context[FirstTestKey.self] == 42)
        #expect(context[SecondTestKey.self] == 42.0)
    }

    @Test("Context forEach iterates over all context items")
    func forEachIteratesOverAllServiceContextItems() {
        var context = ServiceContext.topLevel

        context[FirstTestKey.self] = 42
        context[SecondTestKey.self] = 42.0
        context[ThirdTestKey.self] = "test"

        var contextItems = [AnyServiceContextKey: Any]()
        // swift-format-ignore: ReplaceForEachWithForLoop
        context.forEach { key, value in
            contextItems[key] = value
        }
        #expect(contextItems.count == 3)
        #expect(contextItems.contains(where: { $0.key.name == "FirstTestKey" }))
        #expect(contextItems.contains(where: { $0.value as? Int == 42 }))
        #expect(contextItems.contains(where: { $0.key.name == "SecondTestKey" }))
        #expect(contextItems.contains(where: { $0.value as? Double == 42.0 }))
        #expect(contextItems.contains(where: { $0.key.name == "explicit" }))
        #expect(contextItems.contains(where: { $0.value as? String == "test" }))
    }

    @Test("TODO Context does not crash without explicit compiler flag")
    func TODO_doesNotCrashWithoutExplicitCompilerFlag() {
        _ = ServiceContext.TODO(#function)
    }

    @Test("ServiceContextKey name defaults to type name without override")
    func serviceContextKeyName_withoutOverride() {
        let name = FirstTestKey.name
        #expect(name == "FirstTestKey")
    }

    @Test("ServiceContextKey name uses explicit override when provided")
    func serviceContextKeyName_withOverride() {
        let name = ThirdTestKey.name
        #expect(name == "explicit")
    }

    @Test("AnyServiceContextKey name defaults to type name without override")
    func anyServiceContextKeyName_withoutOverride() {
        let anyKey = AnyServiceContextKey(FirstTestKey.self)
        #expect(anyKey.name == "FirstTestKey")
    }

    @Test("AnyServiceContextKey name uses explicit override when provided")
    func anyServiceContextKeyName_withOverride() {
        let anyKey = AnyServiceContextKey(ThirdTestKey.self)
        #expect(anyKey.name == "explicit")
    }

    @Test("ServiceContextKey name matches AnyServiceContextKey name")
    func serviceContextKeyName_matchesAnyServiceContextKeyName() {
        #expect(FirstTestKey.name == AnyServiceContextKey(FirstTestKey.self).name)
        #expect(SecondTestKey.name == AnyServiceContextKey(SecondTestKey.self).name)
        #expect(ThirdTestKey.name == AnyServiceContextKey(ThirdTestKey.self).name)
    }

    @Test("Automatic propagation through task-local storage")
    func automaticPropagationThroughTaskLocal() throws {
        guard #available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *) else {
            #expect(Bool(true), "Task locals are not supported on this platform.")
            return
        }

        #expect(ServiceContext.current == nil)

        var context = ServiceContext.topLevel
        context[FirstTestKey.self] = 42

        var propagatedServiceContext: ServiceContext?
        func exampleFunction() {
            propagatedServiceContext = ServiceContext.current
        }

        let c = ServiceContext.$current
        c.withValue(context, operation: exampleFunction)

        #expect(propagatedServiceContext?.count == 1)
        #expect(propagatedServiceContext?[FirstTestKey.self] == 42)
    }

    actor SomeActor {
        var value: Int = 0

        func check() async {
            ServiceContext.$current.withValue(.topLevel) {
                value = 12  // should produce no warnings
            }
            ServiceContext.withValue(.topLevel) {
                value = 12  // should produce no warnings
            }
            await ServiceContext.withValue(.topLevel) { () async in
                value = 12  // should produce no warnings
            }
        }
    }

    private enum FirstTestKey: ServiceContextKey {
        typealias Value = Int
    }

    private enum SecondTestKey: ServiceContextKey {
        typealias Value = Double
    }

    private enum ThirdTestKey: ServiceContextKey {
        typealias Value = String

        static let nameOverride: String? = "explicit"
    }
}
