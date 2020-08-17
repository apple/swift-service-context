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
import Dispatch
import class Foundation.NSLock
import SwiftBenchmarkTools
public let BaggagePassingBenchmarks: [BenchmarkInfo] = [
    // ==== ----------------------------------------------------------------------------------------------------------------
    // MARK: "Read only" context passing around
    BenchmarkInfo(
        name: "BaggagePassingBenchmarks.pass_async_empty_100_000         ",
        runFunction: { _ in
            let context = BaggageContext()
            pass_async(context: context, times: 100_000)
        },
        tags: [],
        setUpFunction: { setUp() },
        tearDownFunction: tearDown
    ),
    BenchmarkInfo(
        name: "BaggagePassingBenchmarks.pass_async_smol_100_000          ",
        runFunction: { _ in
            var context = BaggageContext()
            context.k1 = "one"
            context.k2 = "two"
            context.k3 = "three"
            context.k4 = "four"
            pass_async(context: context, times: 100_000)
        },
        tags: [],
        setUpFunction: { setUp() },
        tearDownFunction: tearDown
    ),
    BenchmarkInfo(
        name: "BaggagePassingBenchmarks.pass_async_small_nonconst_100_000",
        runFunction: { _ in
            var context = BaggageContext()
            context.k1 = "\(Int.random(in: 1 ... Int.max))"
            context.k2 = "\(Int.random(in: 1 ... Int.max))"
            context.k3 = "\(Int.random(in: 1 ... Int.max))"
            context.k4 = "\(Int.random(in: 1 ... Int.max))"
            pass_async(context: context, times: 100_000)
        },
        tags: [],
        setUpFunction: { setUp() },
        tearDownFunction: tearDown
    ),

    // ==== ------------------------------------------------------------------------------------------------------------
    // MARK: Passing & Mutating
    // Since the context is backed by a dictionary (and nothing else) we rely on its CoW semantics, those writes cause copies
    // whilst the previous benchmarks which are read-only do not cause copies of the underlying storage (dictionary).

    BenchmarkInfo(
        name: "BaggagePassingBenchmarks.pass_mut_async_small_100_000     ",
        runFunction: { _ in
            var context = BaggageContext()
            context.k1 = "\(Int.random(in: 1 ... Int.max))"
            context.k2 = "\(Int.random(in: 1 ... Int.max))"
            context.k3 = "\(Int.random(in: 1 ... Int.max))"
            context.k4 = "\(Int.random(in: 1 ... Int.max))"
            pass_mut_async(context: context, times: 100_000)
        },
        tags: [],
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

@inline(never)
func pass_async(context: BaggageContext, times remaining: Int) {
    let latch = CountDownLatch(from: 1)

    func pass_async0(context: BaggageContext, times remaining: Int) {
        if remaining == 0 {
            latch.countDown()
        }
        DispatchQueue.global().async {
            pass_async0(context: context, times: remaining - 1)
        }
    }

    pass_async0(context: context, times: remaining - 1)

    latch.wait()
}

@inline(never)
func pass_mut_async(context: BaggageContext, times remaining: Int) {
    var context = context
    let latch = CountDownLatch(from: 1)

    func pass_async0(context: BaggageContext, times remaining: Int) {
        if remaining == 0 {
            latch.countDown()
        }

        DispatchQueue.global().async {
            // mutate the context
            var context = context
            context.passCounter = remaining

            pass_async0(context: context, times: remaining - 1)
        }
    }

    context.passCounter = remaining
    pass_async0(context: context, times: remaining - 1)

    latch.wait()
}

// ==== ----------------------------------------------------------------------------------------------------------------
// MARK: Baggage Keys

private enum TestPassCounterKey: BaggageContextKey {
    typealias Value = Int
}

private enum TestK1: BaggageContextKey {
    typealias Value = String
}

private enum TestK2: BaggageContextKey {
    typealias Value = String
}

private enum TestK3: BaggageContextKey {
    typealias Value = String
}

private enum TestK4: BaggageContextKey {
    typealias Value = String
}

private enum TestKD1: BaggageContextKey {
    typealias Value = [String: String]
}

extension BaggageContext {
    fileprivate var passCounter: TestPassCounterKey.Value {
        get { return self[TestPassCounterKey.self] ?? 0 }
        set { self[TestPassCounterKey.self] = newValue }
    }

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
