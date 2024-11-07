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
// Copyright (c) 2020-2021 Apple Inc. and the Swift Distributed Tracing project
// authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation
import ServiceContextModule

@inline(never)
func take1(context: ServiceContext) -> Int {
    take2(context: context)
}

@inline(never)
func take2(context: ServiceContext) -> Int {
    take3(context: context)
}

@inline(never)
func take3(context: ServiceContext) -> Int {
    take4(context: context)
}

@inline(never)
func take4(context: ServiceContext) -> Int {
    42
}

enum StringKey1: ServiceContextKey {
    typealias Value = String
}

enum StringKey2: ServiceContextKey {
    typealias Value = String
}

enum StringKey3: ServiceContextKey {
    typealias Value = String
}
