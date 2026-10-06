//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Service Context open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift Service Context project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Service Context project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import InstrumentationBaggage
import ServiceContextModule

enum MessageKey: ServiceContextKey {
    typealias Value = String
}
var context = ServiceContext.topLevel
context[MessageKey.self] = "CMake"
precondition(context[MessageKey.self] == "CMake")
