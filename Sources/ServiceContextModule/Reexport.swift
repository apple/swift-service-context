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

// The `ServiceContextModule` module lives in the `swift-distributed-tracing` package. It declares `ServiceContext`,
// `ServiceContextKey`, `AnyServiceContextKey`, and `TODOLocation` as non-deprecated names for the types in that
// package's `Instrumentation` module.
//
// This target declares no types. It keeps the `ServiceContextModule` library product of this package, so existing
// dependents keep resolving. Target names are unique across the package graph, so this package cannot declare a
// target named `ServiceContextModule`.
@_exported import ServiceContextModule
