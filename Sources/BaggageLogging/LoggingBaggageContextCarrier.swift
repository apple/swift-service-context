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
import Logging

/// A `LoggingBaggageContextCarrier` purpose is to be adopted by frameworks which already provide a "FrameworkContext",
/// and to such frameworks to pass their context as `BaggageContextCarrier`.
public protocol LoggingBaggageContextCarrier: BaggageContextCarrier {
    /// The logger associated with this context carrier.
    ///
    /// It should automatically populate the loggers metadata based on the `BaggageContext` associated with this context object.
    ///
    /// ### Implementation note
    ///
    /// Libraries and/or frameworks which conform to this protocol with their "Framework Context" types,
    /// SHOULD implement this logger by wrapping the "raw" logger associated with this context with the `logger.with(BaggageContext:)` function,
    /// which efficiently handles the bridging of baggage to logging metadata values.
    ///
    /// ### Example implementation
    ///
    /// Writes to the `logger` metadata SHOULD NOT be reflected in the `baggage`,
    /// however writes to the underlying `baggage` SHOULD be reflected in the `logger`.
    ///
    ///     struct MyFrameworkContext: LoggingBaggageContextCarrier {
    ///       var baggage = BaggageContext()
    ///       private let _logger: Logger
    ///
    ///       var logger: Logger {
    ///         return self._logger.with(context: self.baggage)
    ///       }
    ///     }
    var logger: Logger { get }
}
