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

/// A `BaggageContext` is a heterogeneous storage type with value semantics for keyed values in a type-safe
/// fashion. Its values are uniquely identified via `BaggageContextKey`s. These keys also dictate the type of
/// value allowed for a specific key-value pair through their associated type `Value`.
///
/// ## Subscript access
/// You may access the stored values by subscripting with a key type conforming to `BaggageContextKey`.
///
///     enum TestIDKey: BaggageContextKey {
///       typealias Value = String
///     }
///
///     var context = BaggageContext()
///     // set a new value
///     context[TestIDKey.self] = "abc"
///     // retrieve a stored value
///     context[TestIDKey.self] ?? "default"
///     // remove a stored value
///     context[TestIDKey.self] = nil
///
/// ## Convenience extensions
///
/// Libraries may also want to provide an extension, offering the values that users are expected to reach for
/// using the following pattern:
///
///     extension BaggageContextProtocol {
///       var testID: TestIDKey.Value? {
///         get {
///           self[TestIDKey.self]
///         } set {
///           self[TestIDKey.self] = newValue
///         }
///       }
///     }
public struct BaggageContext: BaggageContextProtocol {
    private var _storage = [AnyBaggageContextKey: Any]()

    /// Create an empty `BaggageContext`.
    public init() {}

    public subscript<Key: BaggageContextKey>(_ key: Key.Type) -> Key.Value? {
        get {
            guard let value = self._storage[AnyBaggageContextKey(key)] else { return nil }
            // safe to force-cast as this subscript is the only way to set a value.
            return (value as! Key.Value)
        } set {
            self._storage[AnyBaggageContextKey(key)] = newValue
        }
    }

    public func forEach(_ body: (AnyBaggageContextKey, Any) throws -> Void) rethrows {
        try self._storage.forEach { key, value in
            try body(key, value)
        }
    }
}

extension BaggageContext: CustomStringConvertible {
    /// A context's description prints only keys of the contained values.
    /// This is in order to prevent spilling a lot of detailed information of carried values accidentally.
    ///
    /// `BaggageContext`s are not intended to be printed "raw" but rather inter-operate with tracing, logging and other systems,
    /// which can use the `forEach` function providing access to its underlying values.
    public var description: String {
        return "\(type(of: self).self)(keys: \(self._storage.map { $0.key.name }))"
    }
}

public protocol BaggageContextProtocol {
    /// Provides type-safe access to the baggage's values.
    ///
    /// Rather than using this subscript directly, users are encouraged to offer a convenience accessor to their values,
    /// using the following pattern:
    ///
    ///     extension BaggageContextProtocol {
    ///       var testID: TestIDKey.Value? {
    ///         get {
    ///           self[TestIDKey.self]
    ///         } set {
    ///           self[TestIDKey.self] = newValue
    ///         }
    ///       }
    ///     }
    subscript<Key: BaggageContextKey>(_ key: Key.Type) -> Key.Value? { get set }

    /// Calls the given closure on each key/value pair in the `BaggageContext`.
    ///
    /// - Parameter body: A closure invoked with the type erased key and value stored for the key in this baggage.
    func forEach(_ body: (AnyBaggageContextKey, Any) throws -> Void) rethrows
}

// ==== ------------------------------------------------------------------------
// MARK: Baggage keys

/// `BaggageContextKey`s are used as keys in a `BaggageContext`. Their associated type `Value` guarantees type-safety.
/// To give your `BaggageContextKey` an explicit name you may override the `name` property.
///
/// In general, `BaggageContextKey`s should be `internal` to the part of a system using it. It is strongly recommended to do
/// convenience extensions on `BaggageContextProtocol`, using the keys directly is considered an anti-pattern.
///
///     extension BaggageContextProtocol {
///       var testID: TestIDKey.Value? {
///         get {
///           self[TestIDKey.self]
///         } set {
///           self[TestIDKey.self] = newValue
///         }
///       }
///     }
public protocol BaggageContextKey {
    /// The type of `Value` uniquely identified by this key.
    associatedtype Value

    /// The human-readable name of this key. Defaults to `nil`.
    static var name: String? { get }
}

extension BaggageContextKey {
    public static var name: String? { return nil }
}

/// A type-erased `BaggageContextKey` used when iterating through the `BaggageContext` using its `forEach` method.
public struct AnyBaggageContextKey {
    /// The key's type represented erased to an `Any.Type`.
    public let keyType: Any.Type

    private let _name: String?

    /// A human-readable String representation of the underlying key.
    /// If no explicit name has been set on the wrapped key the type name is used.
    public var name: String {
        return self._name ?? String(describing: self.keyType.self)
    }

    init<Key>(_ keyType: Key.Type) where Key: BaggageContextKey {
        self.keyType = keyType
        self._name = keyType.name
    }
}

extension AnyBaggageContextKey: Hashable {
    public static func == (lhs: AnyBaggageContextKey, rhs: AnyBaggageContextKey) -> Bool {
        return ObjectIdentifier(lhs.keyType) == ObjectIdentifier(rhs.keyType)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self.keyType))
    }
}
