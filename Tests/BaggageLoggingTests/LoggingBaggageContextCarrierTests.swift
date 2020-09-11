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
import BaggageLogging
import Logging
import XCTest

final class LoggingBaggageContextCarrierTests: XCTestCase {
    func test_ContextWithLogger_dumpBaggage() throws {
        let baggage = BaggageContext.background
        let logger = Logger(label: "TheLogger")

        var context: LoggingBaggageContextCarrier = ExampleFrameworkContext(context: baggage, logger: logger)
        context.testID = 42

        func frameworkFunctionDumpsBaggage(param: String, context: LoggingBaggageContextCarrier) -> String {
            var s = ""
            context.baggage.forEach { key, item in
                s += "\(key.name): \(item)\n"
            }
            return s
        }

        let result = frameworkFunctionDumpsBaggage(param: "x", context: context)
        XCTAssertEqual(
            result,
            """
            TestIDKey: 42

            """
        )
    }

    func test_ContextWithLogger_log_withBaggage() throws {
        let baggage = BaggageContext.background
        let logging = TestLogging()
        let logger = Logger(label: "TheLogger", factory: { label in logging.make(label: label) })

        var context: LoggingBaggageContextCarrier = ExampleFrameworkContext(context: baggage, logger: logger)

        context.secondTestID = "value"
        context.testID = 42
        context.logger.info("Hello")

        context.testID = nil
        context.logger.warning("World")

        logging.history.assertExist(level: .info, message: "Hello", metadata: [
            "TestIDKey": .stringConvertible(42),
            "secondIDExplicitlyNamed": "value",
        ])
        logging.history.assertExist(level: .warning, message: "World", metadata: [
            "secondIDExplicitlyNamed": "value",
        ])
    }

    func test_ContextWithLogger_log_prefersBaggageContextOverExistingLoggerMetadata() {
        let baggage = BaggageContext.background
        let logging = TestLogging()
        var logger = Logger(label: "TheLogger", factory: { label in logging.make(label: label) })
        logger[metadataKey: "secondIDExplicitlyNamed"] = "set on logger"

        var context: LoggingBaggageContextCarrier = ExampleFrameworkContext(context: baggage, logger: logger)

        context.secondTestID = "set on baggage"

        context.logger.info("Hello")

        logging.history.assertExist(level: .info, message: "Hello", metadata: [
            "secondIDExplicitlyNamed": "set on baggage",
        ])
    }
}

struct ExampleFrameworkContext: LoggingBaggageContextCarrier {
    var baggage: BaggageContext

    private var _logger: Logger
    var logger: Logger {
        return self._logger.with(context: self.baggage)
    }

    init(context baggage: BaggageContext, logger: Logger) {
        self.baggage = baggage
        self._logger = logger
    }
}

struct CoolFrameworkContext: LoggingBaggageContextCarrier {
    private var _logger: Logger = Logger(label: "some frameworks logger")
    var logger: Logger {
        return self._logger.with(context: self.baggage)
    }

    var baggage: BaggageContext = .background

    // framework context defines other values as well
    let frameworkField: String = ""

    // including the popular eventLoop
    let eventLoop: FakeEventLoop
}

struct FakeEventLoop {}

private extension BaggageContextProtocol {
    var testID: Int? {
        get {
            return self[TestIDKey.self]
        }
        set {
            self[TestIDKey.self] = newValue
        }
    }

    var secondTestID: String? {
        get {
            return self[SecondTestIDKey.self]
        }
        set {
            self[SecondTestIDKey.self] = newValue
        }
    }
}

private enum TestIDKey: BaggageContextKey {
    typealias Value = Int
}

private enum SecondTestIDKey: BaggageContextKey {
    typealias Value = String

    static let name: String? = "secondIDExplicitlyNamed"
}
