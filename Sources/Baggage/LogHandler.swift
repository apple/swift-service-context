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

// ==== ----------------------------------------------------------------------------------------------------------------
// MARK: Logger with Baggage

extension Logger {
    /// Returns a logger that in addition to any explicit metadata passed to log statements,
    /// also includes the `Baggage` adapted into metadata values.
    ///
    /// The rendering of baggage values into metadata values is performed on demand,
    /// whenever a log statement is effective (i.e. will be logged, according to active `logLevel`).
    ///
    /// Note that when it is known that multiple log statements will be performed with the baggage it is preferable to
    /// modify the logger's metadata by issuing `logger.updateMetadata(previous: baggage, latest: baggage)` instead.
    ///
    /// - SeeAlso:
    public func with(_ baggage: Baggage) -> Logger {
        return Logger(
            label: self.label,
            factory: { _ in BaggageMetadataLogHandler(logger: self, baggage: baggage) }
        )
    }

    /// Update the logger's metadata in accordance to the passed in baggage.
    ///
    /// Items which were previously present in the baggage but are now removed will also be removed from the logger's
    /// metadata.
    ///
    /// - Parameters:
    ///   - previous: baggage which was previously used to set metadata on this logger (pass `.topLevel` if unknown or none)
    ///   - latest: the current, latest, state of the baggage container; all of it's loggable values will be set as the `Logger`'s metadata
    public mutating func updateMetadata(previous: Baggage, latest: Baggage) {
        var removedKeys: Set<AnyBaggageKey> = []
        removedKeys.reserveCapacity(previous.count)
        previous.forEach { key, _ in
            removedKeys.insert(key)
        }
        latest.forEach { key, value in
            removedKeys.remove(key)
            if let convertible = value as? String {
                self[metadataKey: key.name] = .string(convertible)
            } else if let convertible = value as? CustomStringConvertible {
                self[metadataKey: key.name] = .stringConvertible(convertible)
            } else {
                self[metadataKey: key.name] = .stringConvertible(BaggageValueCustomStringConvertible(value))
            }
        }
        removedKeys.forEach { removedKey in
            self[metadataKey: removedKey.name] = nil
        }
    }
}

// ==== ----------------------------------------------------------------------------------------------------------------
// MARK: Baggage (as additional Logger.Metadata) LogHandler

/// Proxying log handler which adds `Baggage` as metadata when log events are to be emitted.
///
/// The values stored in the `Baggage` are merged with the existing metadata on the logger. If both contain values for the same key,
/// the `Baggage` values are preferred.
public struct BaggageMetadataLogHandler: LogHandler {
    private var underlying: Logger
    private let baggage: Baggage

    public init(logger underlying: Logger, baggage: Baggage) {
        self.underlying = underlying
        self.baggage = baggage
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
    /// into a baggage with String keys through this handler (as that is not a capability `Baggage` offers in any case.
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
        self.baggage.forEach { key, value in
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
