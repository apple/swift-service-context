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

// ==== ----------------------------------------------------------------------------------------------------------------
// MARK: BaggageContext (as additional Logger.Metadata) LogHandler

/// Proxying log handler which adds `BaggageContext` as metadata when log events are to be emitted.
public struct BaggageMetadataLogHandler: LogHandler {
    var underlying: Logger
    let context: BaggageContext

    public init(logger underlying: Logger, context: BaggageContext) {
        self.underlying = underlying
        self.context = context
    }

    public var logLevel: Logger.Level {
        get {
            return self.underlying.logLevel
        }
        set {
            self.underlying.logLevel = newValue
        }
    }

    public func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata: Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) {
        guard self.underlying.logLevel <= level else {
            return
        }

        var effectiveMetadata = self.baggageAsMetadata()
        if let metadata = metadata {
            effectiveMetadata.merge(metadata, uniquingKeysWith: { _, r in r })
        }
        self.underlying.log(level: level, message, metadata: effectiveMetadata, source: source, file: file, function: function, line: line)
    }

    public var metadata: Logger.Metadata {
        get {
            return [:]
        }
        set {
            newValue.forEach { k, v in
                self.underlying[metadataKey: k] = v
            }
        }
    }

    /// Note that this does NOT look up inside the baggage.
    ///
    /// This is because a context lookup either has to use the specific type key, or iterate over all keys to locate one by name,
    /// which may be incorrect still, thus rather than making an potentially slightly incorrect lookup, we do not implement peeking
    /// into a baggage with String keys through this handler (as that is not a capability `BaggageContext` offers in any case.
    public subscript(metadataKey metadataKey: Logger.Metadata.Key) -> Logger.Metadata.Value? {
        get {
            return self.underlying[metadataKey: metadataKey]
        }
        set {
            self.underlying[metadataKey: metadataKey] = newValue
        }
    }

    private func baggageAsMetadata() -> Logger.Metadata {
        var effectiveMetadata: Logger.Metadata = [:]
        self.context.forEach { key, value in
            if let convertible = value as? String {
                effectiveMetadata[key.name] = .string(convertible)
            } else if let convertible = value as? CustomStringConvertible {
                effectiveMetadata[key.name] = .stringConvertible(convertible)
            } else {
                effectiveMetadata[key.name] = .stringConvertible(BaggageValueCustomStringConvertible(value))
            }
        }

        return effectiveMetadata
    }

    struct BaggageValueCustomStringConvertible: CustomStringConvertible {
        let value: Any

        init(_ value: Any) {
            self.value = value
        }

        var description: String {
            return "\(self.value)"
        }
    }
}
