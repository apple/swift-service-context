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

//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Distributed Tracing open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift Distributed Tracing project
// authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Benchmark
import ServiceContextModule

func runPassAroundStaticStringsSmall(iterations: Int) {
    var context = ServiceContext.topLevel
    // static allocated strings
    context[StringKey1.self] = "one"
    context[StringKey2.self] = "two"
    context[StringKey3.self] = "three"

    for _ in 0..<iterations {
        let res = take1(context: context)
        precondition(res == 42)
    }
}

func runPassAroundStaticStringsLarge(iterations: Int) {
    var context = ServiceContext.topLevel
    // static allocated strings
    context[StringKey1.self] = String(repeating: "a", count: 30)
    context[StringKey2.self] = String(repeating: "b", count: 12)
    context[StringKey3.self] = String(repeating: "c", count: 20)

    for _ in 0..<iterations {
        let res = take1(context: context)
        precondition(res == 42)
    }
}
