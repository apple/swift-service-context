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

extension Logger {
    /// Returns a logger that in addition to any explicit metadata passed to log statements,
    /// also includes the `BaggageContext` adapted into metadata values.
    ///
    /// The rendering of baggage values into metadata values is performed on demand,
    /// whenever a log statement is effective (i.e. will be logged, according to active `logLevel`).
    public func with(context: BaggageContext) -> Logger {
        Logger(
            label: self.label,
            factory: { _ in BaggageMetadataLogHandler(logger: self, context: context) }
        )
    }
}
