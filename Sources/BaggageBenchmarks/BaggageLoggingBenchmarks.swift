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
import BaggageBenchmarkTools
import Dispatch
import class Foundation.NSLock
import Logging

private let message: Logger.Message = "Hello world how are you"

func pad(_ label: String) -> String {
    return "\(label)\(String(repeating: " ", count: max(0, 80 - label.count)))"
}

public let BaggageLoggingBenchmarks: [BenchmarkInfo] = [
    // ==== ----------------------------------------------------------------------------------------------------------------
    // MARK: Baseline
    BenchmarkInfo(
        name: pad("BaggageLoggingBenchmarks.0_log_noop_baseline_empty"),
        runFunction: { iters in
            let logger = Logger(label: "0_log_noop_baseline_empty", factory: { _ in SwiftLogNoOpLogHandler() })
            log_baseline(logger: logger, iters: iters)
        },
        tags: [
            .logging,
        ],
        setUpFunction: { setUp() },
        tearDownFunction: tearDown
    ),
    BenchmarkInfo(
        name: pad("BaggageLoggingBenchmarks.0_log_noop_baseline_smallMetadata"),
        runFunction: { iters in
            var logger = Logger(label: "0_log_noop_baseline_smallMetadata", factory: { _ in SwiftLogNoOpLogHandler() })
            logger[metadataKey: "k1"] = "k1-value"
            logger[metadataKey: "k2"] = "k2-value"
            logger[metadataKey: "k3"] = "k3-value"
            log_baseline(logger: logger, iters: iters)
        },
        tags: [
            .logging,
        ],
        setUpFunction: { setUp() },
        tearDownFunction: tearDown
    ),

    // ==== ----------------------------------------------------------------------------------------------------------------
    // MARK: Context / Baggage (Really do log)

    BenchmarkInfo(
        name: pad("BaggageLoggingBenchmarks.0_log_noop_loggerWithBaggage_small"),
        runFunction: { iters in
            let logger = Logger(label: "0_log_noop_loggerWithBaggage_small", factory: { _ in SwiftLogNoOpLogHandler() })
            var baggage = Baggage.topLevel
            baggage[TestK1.self] = "k1-value"
            baggage[TestK2.self] = "k2-value"
            baggage[TestK3.self] = "k3-value"
            log_loggerWithBaggage(logger: logger, baggage: baggage, iters: iters)
        },
        tags: [
            .logging,
        ],
        setUpFunction: { setUp() },
        tearDownFunction: tearDown
    ),
    BenchmarkInfo(
        name: pad("BaggageLoggingBenchmarks.0_log_noop_context_with_baggage_small"),
        runFunction: { iters in
            var context = DefaultLoggingContext.topLevel(logger: Logger(label: "0_log_noop_context_with_baggage_small", factory: { _ in SwiftLogNoOpLogHandler() }))
            context.baggage[TestK1.self] = "k1-value"
            context.baggage[TestK2.self] = "k2-value"
            context.baggage[TestK3.self] = "k3-value"
            log_throughContext(context: context, iters: iters)
        },
        tags: [
            .logging,
        ],
        setUpFunction: { setUp() },
        tearDownFunction: tearDown
    ),

    // ==== ----------------------------------------------------------------------------------------------------------------
    // MARK: Context / Baggage (do actually emit the logs)

    BenchmarkInfo(
        name: pad("BaggageLoggingBenchmarks.1_log_real_baseline_empty"),
        runFunction: { iters in
            let logger = Logger(label: "1_log_real_baseline_empty", factory: StreamLogHandler.standardError)
            log_baseline(logger: logger, iters: iters)
        },
        tags: [
            .logging,
        ],
        setUpFunction: { setUp() },
        tearDownFunction: tearDown
    ),
    BenchmarkInfo(
        name: pad("BaggageLoggingBenchmarks.1_log_real_baseline_smallMetadata"),
        runFunction: { iters in
            var logger = Logger(label: "1_log_real_baseline_smallMetadata", factory: StreamLogHandler.standardError)
            logger[metadataKey: "k1"] = "k1-value"
            logger[metadataKey: "k2"] = "k2-value"
            logger[metadataKey: "k3"] = "k3-value"
            log_baseline(logger: logger, iters: iters)
        },
        tags: [
            .logging,
        ],
        setUpFunction: { setUp() },
        tearDownFunction: tearDown
    ),

    BenchmarkInfo(
        name: pad("BaggageLoggingBenchmarks.1_log_real_loggerWithBaggage_small"),
        runFunction: { iters in
            let logger = Logger(label: "1_log_real_loggerWithBaggage_small", factory: StreamLogHandler.standardError)
            var baggage = Baggage.topLevel
            baggage[TestK1.self] = "k1-value"
            baggage[TestK2.self] = "k2-value"
            baggage[TestK3.self] = "k3-value"
            log_loggerWithBaggage(logger: logger, baggage: baggage, iters: iters)
        },
        tags: [
            .logging,
        ],
        setUpFunction: { setUp() },
        tearDownFunction: tearDown
    ),
    BenchmarkInfo(
        name: pad("BaggageLoggingBenchmarks.1_log_real_context_with_baggage_small"),
        runFunction: { iters in
            var context = DefaultLoggingContext.topLevel(logger: Logger(label: "1_log_real_context_with_baggage_small", factory: StreamLogHandler.standardError))
            context.baggage[TestK1.self] = "k1-value"
            context.baggage[TestK2.self] = "k2-value"
            context.baggage[TestK3.self] = "k3-value"
            log_throughContext(context: context, iters: iters)
        },
        tags: [
            .logging,
        ],
        setUpFunction: { setUp() },
        tearDownFunction: tearDown
    ),

    // ==== ----------------------------------------------------------------------------------------------------------------
    // MARK: Context / Baggage (log not emitted because logLevel)

    BenchmarkInfo(
        name: pad("BaggageLoggingBenchmarks.2_log_real-trace_baseline_empty"),
        runFunction: { iters in
            let logger = Logger(label: "trace_baseline_empty", factory: StreamLogHandler.standardError)
            log_baseline_trace(logger: logger, iters: iters)
        },
        tags: [
            .logging,
        ],
        setUpFunction: { setUp() },
        tearDownFunction: tearDown
    ),
    BenchmarkInfo(
        name: pad("BaggageLoggingBenchmarks.2_log_real-trace_baseline_smallMetadata"),
        runFunction: { iters in
            var logger = Logger(label: "2_log_real-trace_baseline_smallMetadata", factory: StreamLogHandler.standardError)
            logger[metadataKey: "k1"] = "k1-value"
            logger[metadataKey: "k2"] = "k2-value"
            logger[metadataKey: "k3"] = "k3-value"
            log_baseline_trace(logger: logger, iters: iters)
        },
        tags: [
            .logging,
        ],
        setUpFunction: { setUp() },
        tearDownFunction: tearDown
    ),

    BenchmarkInfo(
        name: pad("BaggageLoggingBenchmarks.2_log_real-trace_loggerWithBaggage_small"),
        runFunction: { iters in
            let logger = Logger(label: "2_log_real-trace_loggerWithBaggage_small", factory: StreamLogHandler.standardError)
            var baggage = Baggage.topLevel
            baggage[TestK1.self] = "k1-value"
            baggage[TestK2.self] = "k2-value"
            baggage[TestK3.self] = "k3-value"
            log_loggerWithBaggage_trace(logger: logger, baggage: baggage, iters: iters)
        },
        tags: [
            .logging,
        ],
        setUpFunction: { setUp() },
        tearDownFunction: tearDown
    ),
    BenchmarkInfo(
        name: pad("BaggageLoggingBenchmarks.2_log_real-trace_context_with_baggage_small"),
        runFunction: { iters in
            var context = DefaultLoggingContext.topLevel(logger: Logger(label: "2_log_real-trace_context_with_baggage_small", factory: StreamLogHandler.standardError))
            context.baggage[TestK1.self] = "k1-value"
            context.baggage[TestK2.self] = "k2-value"
            context.baggage[TestK3.self] = "k3-value"
            log_throughContext_trace(context: context, iters: iters)
        },
        tags: [
            .logging,
        ],
        setUpFunction: { setUp() },
        tearDownFunction: tearDown
    ),

    // ==== ----------------------------------------------------------------------------------------------------------------
    // MARK: materialize once once

    BenchmarkInfo(
        name: pad("BaggageLoggingBenchmarks.3_log_real_small_context_materializeOnce"),
        runFunction: { iters in
            var context = DefaultLoggingContext.topLevel(logger: Logger(label: "3_log_real_context_materializeOnce", factory: StreamLogHandler.standardError))
            context.baggage[TestK1.self] = "k1-value"
            context.baggage[TestK2.self] = "k2-value"
            context.baggage[TestK3.self] = "k3-value"
            log_materializeOnce(context: context, iters: iters)
        },
        tags: [
            .logging,
        ],
        setUpFunction: { setUp() },
        tearDownFunction: tearDown
    ),
    BenchmarkInfo(
        name: pad("BaggageLoggingBenchmarks.3_log_real-trace_small_context_materializeOnce"),
        runFunction: { iters in
            var context = DefaultLoggingContext.topLevel(logger: Logger(label: "3_log_real_context_materializeOnce", factory: StreamLogHandler.standardError))
            context.baggage[TestK1.self] = "k1-value"
            context.baggage[TestK2.self] = "k2-value"
            context.baggage[TestK3.self] = "k3-value"
            log_materializeOnce_trace(context: context, iters: iters)
        },
        tags: [
            .logging,
        ],
        setUpFunction: { setUp() },
        tearDownFunction: tearDown
    ),
]

private func setUp() {
    // ...
}

private func tearDown() {
    // ...
}

// ==== ----------------------------------------------------------------------------------------------------------------
// MARK: Benchmarks

@inline(never)
func log_baseline(logger: Logger, iters remaining: Int) {
    for _ in 0 ..< remaining {
        logger.warning(message)
    }
}

@inline(never)
func log_baseline_trace(logger: Logger, iters remaining: Int) {
    for _ in 0 ..< remaining {
        logger.trace(message)
    }
}

@inline(never)
func log_loggerWithBaggage(logger: Logger, baggage: Baggage, iters remaining: Int) {
    for _ in 0 ..< remaining {
        logger.with(baggage).warning(message)
    }
}

@inline(never)
func log_throughContext(context: LoggingContext, iters remaining: Int) {
    for _ in 0 ..< remaining {
        context.logger.warning(message)
    }
}

@inline(never)
func log_loggerWithBaggage_trace(logger: Logger, baggage: Baggage, iters remaining: Int) {
    for _ in 0 ..< remaining {
        logger.with(baggage).trace(message)
    }
}

@inline(never)
func log_throughContext_trace(context: LoggingContext, iters remaining: Int) {
    for _ in 0 ..< remaining {
        context.logger.trace(message)
    }
}

@inline(never)
func log_materializeOnce_trace(context: LoggingContext, iters remaining: Int) {
    var logger = context.logger
    context.baggage.forEach { key, value in
        logger[metadataKey: key.name] = "\(value)"
    }

    for _ in 0 ..< remaining {
        logger.trace(message)
    }
}

@inline(never)
func log_materializeOnce(context: LoggingContext, iters remaining: Int) {
    var logger = context.logger
    context.baggage.forEach { key, value in
        logger[metadataKey: key.name] = "\(value)"
    }

    for _ in 0 ..< remaining {
        logger.warning(message)
    }
}

// ==== ----------------------------------------------------------------------------------------------------------------
// MARK: Baggage Keys

private enum TestK1: BaggageKey {
    typealias Value = String
}

private enum TestK2: BaggageKey {
    typealias Value = String
}

private enum TestK3: BaggageKey {
    typealias Value = String
}

private enum TestK4: BaggageKey {
    typealias Value = String
}

private enum TestKD1: BaggageKey {
    typealias Value = [String: String]
}

extension Baggage {
    fileprivate var k1: TestK1.Value? {
        get { return self[TestK1.self] }
        set { self[TestK1.self] = newValue }
    }

    fileprivate var k2: TestK2.Value? {
        get { return self[TestK2.self] }
        set { self[TestK2.self] = newValue }
    }

    fileprivate var k3: TestK3.Value? {
        get { return self[TestK3.self] }
        set { self[TestK3.self] = newValue }
    }

    fileprivate var k4: TestK4.Value? {
        get { return self[TestK4.self] }
        set { self[TestK4.self] = newValue }
    }

    fileprivate var kd1: TestKD1.Value? {
        get { return self[TestKD1.self] }
        set { self[TestKD1.self] = newValue }
    }
}
