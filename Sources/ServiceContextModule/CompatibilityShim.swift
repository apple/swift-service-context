//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Service Context open source project
//
// Copyright (c) 2020-2026 Apple Inc. and the Swift Service Context project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Service Context project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

// `ServiceContext`, `ServiceContextKey`, and `AnyServiceContextKey` now live in the
// `swift-distributed-tracing` package's `Instrumentation` module, renamed to `InstrumentationContext`,
// `InstrumentationContextKey`, and `AnyInstrumentationContextKey`. This module re-exports the module and
// declares its own, non-deprecated names so `import ServiceContextModule` keeps working unchanged, with no
// deprecation notice, for existing dependents of this package. `TODOLocation` kept its name, so this
// typealias just makes it reachable under this module too.
@_exported import Instrumentation

public typealias ServiceContext = Instrumentation.InstrumentationContext
public typealias ServiceContextKey = Instrumentation.InstrumentationContextKey
public typealias AnyServiceContextKey = Instrumentation.AnyInstrumentationContextKey
public typealias TODOLocation = Instrumentation.TODOLocation
