//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Distributed Tracing Baggage
// open source project
//
// Copyright (c) 2020-2021 Apple Inc. and the Swift Distributed Tracing Baggage
// project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import InstrumentationBaggage
import XCTest

final class BaggageTests: XCTestCase {
    func test_topLevelBaggageIsEmpty() {
        let baggage = Baggage.topLevel

        XCTAssertTrue(baggage.isEmpty)
        XCTAssertEqual(baggage.count, 0)
    }

    func test_readAndWriteThroughSubscript() throws {
        var baggage = Baggage.topLevel
        XCTAssertNil(baggage[FirstTestKey.self])
        XCTAssertNil(baggage[SecondTestKey.self])

        baggage[FirstTestKey.self] = 42
        baggage[SecondTestKey.self] = 42.0

        XCTAssertFalse(baggage.isEmpty)
        XCTAssertEqual(baggage.count, 2)
        XCTAssertEqual(baggage[FirstTestKey.self], 42)
        XCTAssertEqual(baggage[SecondTestKey.self], 42.0)
    }

    func test_forEachIteratesOverAllBaggageItems() {
        var baggage = Baggage.topLevel

        baggage[FirstTestKey.self] = 42
        baggage[SecondTestKey.self] = 42.0
        baggage[ThirdTestKey.self] = "test"

        var baggageItems = [AnyBaggageKey: Any]()
        baggage.forEach { key, value in
            baggageItems[key] = value
        }
        XCTAssertEqual(baggageItems.count, 3)
        XCTAssertTrue(baggageItems.contains(where: { $0.key.name == "FirstTestKey" }))
        XCTAssertTrue(baggageItems.contains(where: { $0.value as? Int == 42 }))
        XCTAssertTrue(baggageItems.contains(where: { $0.key.name == "SecondTestKey" }))
        XCTAssertTrue(baggageItems.contains(where: { $0.value as? Double == 42.0 }))
        XCTAssertTrue(baggageItems.contains(where: { $0.key.name == "explicit" }))
        XCTAssertTrue(baggageItems.contains(where: { $0.value as? String == "test" }))
    }

    func test_TODO_doesNotCrashWithoutExplicitCompilerFlag() {
        _ = Baggage.TODO(#function)
    }

    func test_automaticPropagationThroughTaskLocal() throws {
        #if compiler(>=5.5)
        guard #available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *) else {
            throw XCTSkip("Task locals are not supported on this platform.")
        }

        XCTAssertNil(Baggage.current)

        var baggage = Baggage.topLevel
        baggage[FirstTestKey.self] = 42

        var propagatedBaggage: Baggage?
        func exampleFunction() {
            propagatedBaggage = Baggage.current
        }

        let c = Baggage.$current
        c.withValue(baggage, operation: exampleFunction)

        XCTAssertEqual(propagatedBaggage?.count, 1)
        XCTAssertEqual(propagatedBaggage?[FirstTestKey.self], 42)
        #endif
    }

    #if swift(>=5.7)
    actor SomeActor {
        var value: Int = 0

        func test() async {
            Baggage.$current.withValue(.topLevel) {
                value = 12 // should produce no warnings
            }
            Baggage.withValue(.topLevel) {
                value = 12 // should produce no warnings
            }
        }
    }
    #endif

    private enum FirstTestKey: BaggageKey {
        typealias Value = Int
    }

    private enum SecondTestKey: BaggageKey {
        typealias Value = Double
    }

    private enum ThirdTestKey: BaggageKey {
        typealias Value = String

        static let nameOverride: String? = "explicit"
    }
}
