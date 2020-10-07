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

@_exported import CoreBaggage
@_exported import Logging

extension Baggage {
    /// Creates a `DefaultLoggingContext` with the passed in `Logger`.
    ///
    /// This can be useful when for some reason one was handed only a baggage yet needs to invoke an API that accepts
    /// a `LoggingContext`. E.g. when inside a NIO handler wanting to carry the `context.baggage` from the channel handler,
    /// however the API we want to call (e.g. `HTTPClient`) needs a `LoggingContext`, this function enables creating
    /// a context for the purpose of this call easily inside the parameter being passed.
    ///
    /// - Parameter logger: to be used in the returned `DefaultLoggingContext`, it will be populated with loggable baggage values.
    public func context(logger: Logger) -> DefaultLoggingContext {
        .init(logger: logger, baggage: self)
    }
}
