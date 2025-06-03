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

import ServiceContextModule
import XCTest

final class ServiceContextTests: XCTestCase {
    func test_topLevelServiceContextIsEmpty() {
        let context = ServiceContext.topLevel

        XCTAssertTrue(context.isEmpty)
        XCTAssertEqual(context.count, 0)
    }

    func test_readAndWriteThroughSubscript() throws {
        var context = ServiceContext.topLevel
        XCTAssertNil(context[FirstTestKey.self])
        XCTAssertNil(context[SecondTestKey.self])

        context[FirstTestKey.self] = 42
        context[SecondTestKey.self] = 42.0

        XCTAssertFalse(context.isEmpty)
        XCTAssertEqual(context.count, 2)
        XCTAssertEqual(context[FirstTestKey.self], 42)
        XCTAssertEqual(context[SecondTestKey.self], 42.0)
    }

    func test_forEachIteratesOverAllServiceContextItems() {
        var context = ServiceContext.topLevel

        context[FirstTestKey.self] = 42
        context[SecondTestKey.self] = 42.0
        context[ThirdTestKey.self] = "test"

        var contextItems = [AnyServiceContextKey: Any]()
        // swift-format-ignore: ReplaceForEachWithForLoop
        context.forEach { key, value in
            contextItems[key] = value
        }
        XCTAssertEqual(contextItems.count, 3)
        XCTAssertTrue(contextItems.contains(where: { $0.key.name == "FirstTestKey" }))
        XCTAssertTrue(contextItems.contains(where: { $0.value as? Int == 42 }))
        XCTAssertTrue(contextItems.contains(where: { $0.key.name == "SecondTestKey" }))
        XCTAssertTrue(contextItems.contains(where: { $0.value as? Double == 42.0 }))
        XCTAssertTrue(contextItems.contains(where: { $0.key.name == "explicit" }))
        XCTAssertTrue(contextItems.contains(where: { $0.value as? String == "test" }))
    }

    func test_TODO_doesNotCrashWithoutExplicitCompilerFlag() {
        _ = ServiceContext.TODO(#function)
    }

    func test_automaticPropagationThroughTaskLocal() throws {
        guard #available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *) else {
            throw XCTSkip("Task locals are not supported on this platform.")
        }

        XCTAssertNil(ServiceContext.current)

        var context = ServiceContext.topLevel
        context[FirstTestKey.self] = 42

        var propagatedServiceContext: ServiceContext?
        func exampleFunction() {
            propagatedServiceContext = ServiceContext.current
        }

        let c = ServiceContext.$current
        c.withValue(context, operation: exampleFunction)

        XCTAssertEqual(propagatedServiceContext?.count, 1)
        XCTAssertEqual(propagatedServiceContext?[FirstTestKey.self], 42)
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
