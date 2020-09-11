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

import Baggage
import XCTest

final class BaggageContextTests: XCTestCase {
    func testSubscriptAccess() {
        let testID = 42

        var baggage = BaggageContext.background
        XCTAssertNil(baggage[TestIDKey.self])

        baggage[TestIDKey.self] = testID
        XCTAssertEqual(baggage[TestIDKey.self], testID)

        baggage[TestIDKey.self] = nil
        XCTAssertNil(baggage[TestIDKey.self])
    }

    func testRecommendedConvenienceExtension() {
        let testID = 42

        var baggage = BaggageContext.background
        XCTAssertNil(baggage.testID)

        baggage.testID = testID
        XCTAssertEqual(baggage.testID, testID)

        baggage[TestIDKey.self] = nil
        XCTAssertNil(baggage.testID)
    }

    func testEmptyBaggageDescription() {
        XCTAssertEqual(String(describing: BaggageContext.background), "BaggageContext(keys: [])")
    }

    func testSingleKeyBaggageDescription() {
        var baggage = BaggageContext.background
        baggage.testID = 42

        XCTAssertEqual(String(describing: baggage), #"BaggageContext(keys: ["TestIDKey"])"#)
    }

    func testMultiKeysBaggageDescription() {
        var baggage = BaggageContext.background
        baggage.testID = 42
        baggage[SecondTestIDKey.self] = "test"

        let description = String(describing: baggage)
        XCTAssert(description.starts(with: "BaggageContext(keys: ["))
        // use contains instead of `XCTAssertEqual` because the order is non-predictable (Dictionary)
        XCTAssert(description.contains("TestIDKey"))
        XCTAssert(description.contains("ExplicitKeyName"))
    }

    // ==== ------------------------------------------------------------------------------------------------------------
    // MARK: Factories

    func test_todo_context() {
        // the to-do context can be used to record intentions for why a context could not be passed through
        let context = BaggageContext.TODO("#1245 Some other library should be adjusted to pass us context")
        _ = context // avoid "not used" warning

        // TODO: Can't work with protocols; re-consider the entire carrier approach... Context being a Baggage + Logger, and a specific type.
//        func take(context: BaggageContextProtocol) {
//            _ = context // ignore
//        }
//        take(context: .TODO("pass from request instead"))
    }

    func test_todo_empty() {
        let context = BaggageContext.background
        _ = context // avoid "not used" warning

        // TODO: Can't work with protocols; re-consider the entire carrier approach... Context being a Baggage + Logger, and a specific type.
        // static member 'empty' cannot be used on protocol metatype 'BaggageContextProtocol.Protocol'
//        func take(context: BaggageContextProtocol) {
//            _ = context // ignore
//        }
//        take(context: .background)
    }
}

private enum TestIDKey: BaggageContextKey {
    typealias Value = Int
}

private extension BaggageContext {
    var testID: Int? {
        get {
            return self[TestIDKey.self]
        } set {
            self[TestIDKey.self] = newValue
        }
    }
}

private enum SecondTestIDKey: BaggageContextKey {
    typealias Value = String

    static let name: String? = "ExplicitKeyName"
}
