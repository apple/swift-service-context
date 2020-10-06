//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Distributed Tracing Baggage open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift Distributed Tracing Baggage project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Baggage
import Logging
import XCTest

final class BaggageContextTests: XCTestCase {
    func test_ExampleFrameworkContext_dumpBaggage() throws {
        var baggage = Baggage.topLevel
        let logger = Logger(label: "TheLogger")

        baggage.testID = 42
        let context = ExampleFrameworkContext(context: baggage, logger: logger)

        func frameworkFunctionDumpsBaggage(param: String, context: BaggageContext) -> String {
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

    func test_ExampleFrameworkContext_log_withBaggage() throws {
        let baggage = Baggage.topLevel
        let logging = TestLogging()
        let logger = Logger(label: "TheLogger", factory: { label in logging.make(label: label) })

        var context = ExampleFrameworkContext(context: baggage, logger: logger)

        context.baggage.secondTestID = "value"
        context.baggage.testID = 42
        context.logger.info("Hello")

        context.baggage.testID = nil
        context.logger.warning("World")

        context.baggage.secondTestID = nil
        context.logger[metadataKey: "metadata"] = "on-logger"
        context.logger.warning("!")

        // These implicitly exercise logger.updateMetadata

        logging.history.assertExist(level: .info, message: "Hello", metadata: [
            "TestIDKey": .stringConvertible(42),
            "secondIDExplicitlyNamed": "value",
        ])
        logging.history.assertExist(level: .warning, message: "World", metadata: [
            "secondIDExplicitlyNamed": "value",
        ])
        logging.history.assertExist(level: .warning, message: "!", metadata: [
            "metadata": "on-logger",
        ])
    }

    func test_DefaultContext_log_withBaggage() throws {
        let logging = TestLogging()
        let logger = Logger(label: "TheLogger", factory: { label in logging.make(label: label) })

        var context = DefaultContext.topLevel(logger: logger)

        context.baggage.secondTestID = "value"
        context.baggage.testID = 42
        context.logger.info("Hello")

        context.baggage.testID = nil
        context.logger.warning("World")

        context.baggage.secondTestID = nil
        context.logger[metadataKey: "metadata"] = "on-logger"
        context.logger.warning("!")

        // These implicitly exercise logger.updateMetadata

        logging.history.assertExist(level: .info, message: "Hello", metadata: [
            "TestIDKey": .stringConvertible(42),
            "secondIDExplicitlyNamed": "value",
        ])
        logging.history.assertExist(level: .warning, message: "World", metadata: [
            "secondIDExplicitlyNamed": "value",
        ])
        logging.history.assertExist(level: .warning, message: "!", metadata: [
            "metadata": "on-logger",
        ])
    }

    func test_ExampleFrameworkContext_log_prefersBaggageContextOverExistingLoggerMetadata() {
        let baggage = Baggage.topLevel
        let logging = TestLogging()
        var logger = Logger(label: "TheLogger", factory: { label in logging.make(label: label) })
        logger[metadataKey: "secondIDExplicitlyNamed"] = "set on logger"

        var context = ExampleFrameworkContext(context: baggage, logger: logger)

        context.baggage.secondTestID = "set on baggage"

        context.logger.info("Hello")

        logging.history.assertExist(level: .info, message: "Hello", metadata: [
            "secondIDExplicitlyNamed": "set on baggage",
        ])
    }
}

struct ExampleFrameworkContext: BaggageContext {
    var baggage: Baggage {
        willSet {
            self._logger.updateMetadata(previous: self.baggage, latest: newValue)
        }
    }

    var _logger: Logger
    var logger: Logger {
        get {
            return self._logger
        }
        set {
            self._logger = newValue
            self._logger.updateMetadata(previous: self.baggage, latest: self.baggage)
        }
    }

    init(context baggage: Baggage, logger: Logger) {
        self.baggage = baggage
        self._logger = logger
        self._logger.updateMetadata(previous: .topLevel, latest: baggage)
    }
}

struct CoolFrameworkContext: BaggageContext {
    var baggage: Baggage {
        willSet {
            self.logger.updateMetadata(previous: self.baggage, latest: newValue)
        }
    }

    var logger: Logger {
        didSet {
            self.logger.updateMetadata(previous: self.baggage, latest: self.baggage)
        }
    }

    // framework context defines other values as well
    let frameworkField: String

    // including the popular eventLoop
    let eventLoop: FakeEventLoop

    init() {
        self.baggage = .topLevel
        self.logger = Logger(label: "some-framework-logger")
        self.eventLoop = FakeEventLoop()
        self.frameworkField = ""
        self.logger.updateMetadata(previous: .topLevel, latest: self.baggage)
    }

    func forEachBaggageItem(_ body: (AnyBaggageKey, Any) throws -> Void) rethrows {
        return try self.baggage.forEach(body)
    }
}

struct FakeEventLoop {}

private extension Baggage {
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

private enum TestIDKey: Baggage.Key {
    typealias Value = Int
}

private enum SecondTestIDKey: Baggage.Key {
    typealias Value = String

    static let nameOverride: String? = "secondIDExplicitlyNamed"
}
