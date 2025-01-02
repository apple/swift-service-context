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

/// Context keys provide type-safe access to ``ServiceContext``s by declaring the type of value they "key" at compile-time.
/// To give your `ServiceContextKey` an explicit name, override the ``ServiceContextKey/nameOverride-6shk1`` property.
///
/// In general, any `ServiceContextKey` should be `internal` or `private` to the part of a system using it.
///
/// All access to context items should be performed through an accessor computed property defined as shown below:
///
///     /// The Key type should be internal (or private).
///     enum TestIDKey: ServiceContextKey {
///         typealias Value = String
///         static var nameOverride: String? { "test-id" }
///     }
///
///     extension ServiceContext {
///         /// This is some useful property documentation.
///         public internal(set) var testID: String? {
///             get {
///                 self[TestIDKey.self]
///             }
///             set {
///                 self[TestIDKey.self] = newValue
///             }
///         }
///     }
///
/// This pattern allows library authors fine-grained control over which values may be set, and which only get by end-users.
public protocol ServiceContextKey: Sendable {
    /// The type of value uniquely identified by this key.
    associatedtype Value: Sendable

    /// The human-readable name of this key.
    /// This name will be used instead of the type name when a value is printed.
    ///
    /// It MAY also be picked up by an instrument (from Swift Tracing) which serializes context items and e.g. used as
    /// header name for carried metadata. Though generally speaking header names are NOT required to use the nameOverride,
    /// and MAY use their well known names for header names etc, as it depends on the specific transport and instrument used.
    ///
    /// For example, a context key representing the W3C "trace-state" header may want to return "trace-state" here,
    /// in order to achieve a consistent look and feel of this context item throughout logging and tracing systems.
    ///
    /// Defaults to `nil`.
    static var nameOverride: String? { get }
}

extension ServiceContextKey {
    public static var nameOverride: String? { nil }
}

/// A type-erased ``ServiceContextKey`` used when iterating through the ``ServiceContext`` using its `forEach` method.
public struct AnyServiceContextKey: Sendable {
    /// The key's type erased to `Any.Type`.
    public let keyType: Any.Type

    private let _nameOverride: String?

    /// A human-readable String representation of the underlying key.
    /// If no explicit name has been set on the wrapped key the type name is used.
    public var name: String {
        self._nameOverride ?? String(describing: self.keyType.self)
    }

    init<Key: ServiceContextKey>(_ keyType: Key.Type) {
        self.keyType = keyType
        self._nameOverride = keyType.nameOverride
    }
}

extension AnyServiceContextKey: Hashable {
    public static func == (lhs: AnyServiceContextKey, rhs: AnyServiceContextKey) -> Bool {
        ObjectIdentifier(lhs.keyType) == ObjectIdentifier(rhs.keyType)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self.keyType))
    }
}
