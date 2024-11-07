//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Service Context open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift Service Context project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Service Context project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Benchmark

let benchmarks = {
    let defaultMetrics: [BenchmarkMetric] = [
        .mallocCountTotal
    ]

    Benchmark(
        "PassAroundStaticStringsSmall",
        configuration: .init(
            metrics: defaultMetrics,
            scalingFactor: .mega,
            maxDuration: .seconds(10_000_000),
            maxIterations: 10
        )
    ) { benchmark in
        runPassAroundStaticStringsSmall(
            iterations: benchmark.scaledIterations.upperBound
        )
    }

    Benchmark(
        "PassAroundStaticStringsLarge",
        configuration: .init(
            metrics: defaultMetrics,
            scalingFactor: .mega,
            maxDuration: .seconds(10_000_000),
            maxIterations: 10
        )
    ) { benchmark in
        runPassAroundStaticStringsLarge(
            iterations: benchmark.scaledIterations.upperBound
        )
    }
}
