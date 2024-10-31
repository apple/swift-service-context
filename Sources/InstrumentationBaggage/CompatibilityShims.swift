//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Service Context open source project
//
// Copyright (c) 2020-2022 Apple Inc. and the Swift Service Context project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Service Context project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

@_exported import ServiceContextModule

@available(*, deprecated, message: "Use 'ServiceContext' from 'ServiceContextModule' instead.")
public typealias Baggage = ServiceContext
@available(*, deprecated, message: "Use 'ServiceContext' from 'ServiceContextModule' instead.")
public typealias BaggageKey = ServiceContextKey
@available(*, deprecated, message: "Use 'ServiceContext' from 'ServiceContextModule' instead.")
public typealias AnyBaggageKey = AnyServiceContextKey
