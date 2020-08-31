//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Context Propagation open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift Baggage Context project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

@testable import Baggage
import XCTest

final class BaggageContextCarrierTests: XCTestCase {
    func testBaggageContextSubscript() {
        var carrier = TestFrameworkContext()

        // mutate baggage context through carrier
        carrier[TestKey.self] = 42
        XCTAssertEqual(carrier[TestKey.self], 42)
        XCTAssertEqual(carrier.baggage[TestKey.self], 42)

        // mutate baggage context directly
        carrier.baggage[OtherKey.self] = "test"
        XCTAssertEqual(carrier.baggage[OtherKey.self], "test")
        XCTAssertEqual(carrier[OtherKey.self], "test")
    }

    func testBaggageContextForEach() {
        var contents = [AnyBaggageContextKey: Any]()
        var carrier = TestFrameworkContext()

        carrier[TestKey.self] = 42
        carrier[OtherKey.self] = "test"

        carrier.forEach { key, value in
            contents[key] = value
        }

        XCTAssertNotNil(contents[AnyBaggageContextKey(TestKey.self)])
        XCTAssertEqual(contents[AnyBaggageContextKey(TestKey.self)] as? Int, 42)
        XCTAssertNotNil(contents[AnyBaggageContextKey(OtherKey.self)])
        XCTAssertEqual(contents[AnyBaggageContextKey(OtherKey.self)] as? String, "test")
    }

    func testBaggageContextCarriesItself() {
        var context: BaggageContextCarrier = BaggageContext()

        context.baggage[TestKey.self] = 42
        XCTAssertEqual(context.baggage[TestKey.self], 42)
    }
}

private struct TestFrameworkContext: BaggageContextCarrier {
    var baggage = BaggageContext()
}

private enum TestKey: BaggageContextKey {
    typealias Value = Int
}

private enum OtherKey: BaggageContextKey {
    typealias Value = String
}
