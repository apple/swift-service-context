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

// `ServiceContext` now lives in the `swift-distributed-tracing` package's `ServiceContextCore` module.
// This module re-exports it under its original name so `import ServiceContextModule` keeps working
// unchanged for existing dependents of this package.
@_exported import ServiceContextCore
