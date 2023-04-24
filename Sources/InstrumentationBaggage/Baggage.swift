//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Distributed Tracing Baggage
// open source project
//
// Copyright (c) 2020-2022 Apple Inc. and the Swift Distributed Tracing Baggage
// project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

#if swift(>=5.5) && canImport(_Concurrency)
public typealias _Baggage_Sendable = Swift.Sendable
#else
public typealias _Baggage_Sendable = Any
#endif

/// A `Baggage` is a heterogeneous storage type with value semantics for keyed values in a type-safe fashion.
///
/// Its values are uniquely identified via ``BaggageKey``s (by type identity). These keys also dictate the type of
/// value allowed for a specific key-value pair through their associated type `Value`.
///
/// ## Defining keys and accessing values
/// Baggage keys are defined as types, most commonly case-less enums (as no actual instances are required)
/// which conform to the ``BaggageKey`` protocol:
///
///     private enum TestIDKey: BaggageKey {
///       typealias Value = String
///     }
///
/// While defining a key, one should also immediately declare an extension on `Baggage` to allow convenient and discoverable ways to interact
/// with the baggage item. The extension should take the form of:
///
///     extension Baggage {
///       var testID: String? {
///         get {
///           self[TestIDKey.self]
///         } set {
///           self[TestIDKey.self] = newValue
///         }
///       }
///     }
///
/// For consistency, it is recommended to name key types with the `...Key` suffix (e.g. `SomethingKey`) and the property
/// used to access a value identifier by such key the prefix of the key (e.g. `something`). Please also observe the usual
/// Swift naming conventions, e.g. prefer `ID` to `Id` etc.
///
/// ## Usage
/// Using a baggage container is fairly straight forward, as it boils down to using the prepared computed properties:
///
///     var baggage = Baggage.topLevel
///     // set a new value
///     baggage.testID = "abc"
///     // retrieve a stored value
///     let testID = baggage.testID ?? "default"
///     // remove a stored value
///     baggage.testIDKey = nil
///
/// Note that normally a baggage should not be "created" ad-hoc by user code, but rather it should be passed to it from
/// a runtime. A `Baggage` may already be available to you through Baggage.$current when using structured concurrency.
/// Otherwise, for example when working in an HTTP server framework, it is most likely that the baggage is already passed
/// directly or indirectly (e.g. in a `FrameworkContext`).
///
/// ### Accessing all values
///
/// The only way to access "all" values in a baggage is by using the `forEach` function.
/// `Baggage` does not expose more functions on purpose to prevent abuse and treating it as too much of an
/// arbitrary value smuggling container, but only make it convenient for tracing and instrumentation systems which need
/// to access either specific or all items carried inside a baggage.
public struct Baggage: _Baggage_Sendable {
    private var _storage = [AnyBaggageKey: _Baggage_Sendable]()

    /// Internal on purpose, please use ``Baggage/TODO(_:function:file:line:)`` or ``Baggage/topLevel`` to create an "empty" baggage,
    /// which carries more meaning to other developers why an empty baggage was used.
    init() {}
}

// MARK: - Creating Baggage

extension Baggage {
    /// Creates a new empty "top level" baggage, generally used as an "initial" baggage to immediately be populated with
    /// some values by a framework or runtime. Another use case is for tasks starting in the "background" (e.g. on a timer),
    /// which don't have a "request context" per se that they can pick up, and as such they have to create a "top level"
    /// baggage for their work.
    ///
    /// ## Usage in frameworks and libraries
    /// This function is really only intended to be used by frameworks and libraries, at the "top-level" where a request's,
    /// message's or task's processing is initiated. For example, a framework handling requests, should create an empty
    /// baggage when handling a request only to immediately populate it with useful trace information extracted from e.g.
    /// request headers.
    ///
    /// ## Usage in applications
    /// Application code should never have to create an empty baggage during the processing lifetime of any request,
    /// and only should create baggages if some processing is performed in the background - thus the naming of this property.
    ///
    /// Usually, a framework such as an HTTP server or similar "request handler" would already provide users
    /// with a context to be passed along through subsequent calls, either implicitly through the task-local `Baggage.$current`
    /// or explicitly as part of some kind of "FrameworkContext".
    ///
    /// If unsure where to obtain a baggage from, prefer using `.TODO("Not sure where I should get a context from here?")`
    /// in order to inform other developers that the lack of baggage passing was not done on purpose, but rather because either
    /// not being sure where to obtain a baggage from, or other framework limitations -- e.g. the outer framework not being
    /// baggage aware just yet.
    public static var topLevel: Baggage {
        Baggage()
    }
}

extension Baggage {
    /// A baggage intended as a placeholder until a real value can be passed through a function call.
    ///
    /// It should ONLY be used while prototyping or when the passing of the proper baggage is not yet possible,
    /// e.g. because an external library did not pass it correctly and has to be fixed before the proper baggage
    /// can be obtained where the TO-DO is currently used.
    ///
    /// ## Crashing on TO-DO context creation
    /// You may set the `BAGGAGE_CRASH_TODOS` variable while compiling a project in order to make calls to this function crash
    /// with a fatal error, indicating where a to-do baggage was used. This comes in handy when wanting to ensure that
    /// a project never ends up using code which initially was written as "was lazy, did not pass baggage", yet the
    /// project requires baggage passing to be done correctly throughout the application. Similar checks can be performed
    /// at compile time easily using linters (not yet implemented), since it is always valid enough to detect a to-do context
    /// being passed as illegal and warn or error when spotted.
    ///
    /// ## Example
    ///
    ///     let baggage = Baggage.TODO("The framework XYZ should be modified to pass us a baggage here, and we'd pass it along"))
    ///
    /// - Parameters:
    ///   - reason: Informational reason for developers, why a placeholder context was used instead of a proper one,
    /// - Returns: Empty "to-do" baggage which should be eventually replaced with a carried through one, or `topLevel`.
    public static func TODO(
        _ reason: StaticString? = "",
        function: String = #function,
        file: String = #file,
        line: UInt = #line
    ) -> Baggage {
        var baggage = Baggage()
        #if BAGGAGE_CRASH_TODOS
        fatalError("BAGGAGE_CRASH_TODOS: at \(file):\(line) (function \(function)), reason: \(reason)")
        #else
        baggage[TODOKey.self] = .init(file: file, line: line)
        return baggage
        #endif
    }

    private enum TODOKey: BaggageKey {
        typealias Value = TODOLocation
        static var nameOverride: String? {
            "todo"
        }
    }
}

/// Carried automatically by a "to do" baggage.
/// It can be used to track where a baggage originated and which "to do" baggage must be fixed into a real one to avoid this.
public struct TODOLocation: _Baggage_Sendable {
    /// Source file location where the to-do ``Baggage`` was created
    public let file: String
    /// Source line location where the to-do ``Baggage`` was created
    public let line: UInt
}

// MARK: - Interacting with Baggage

extension Baggage {
    /// Provides type-safe access to the baggage's values.
    /// This API should ONLY be used inside of accessor implementations.
    ///
    /// End users should use "accessors" the key's author MUST define rather than using this subscript, following this pattern:
    ///
    ///     internal enum TestID: Baggage.Key {
    ///         typealias Value = TestID
    ///     }
    ///
    ///     extension Baggage {
    ///       public internal(set) var testID: TestID? {
    ///         get {
    ///           self[TestIDKey.self]
    ///         }
    ///         set {
    ///           self[TestIDKey.self] = newValue
    ///         }
    ///       }
    ///     }
    ///
    /// This is in order to enforce a consistent style across projects and also allow for fine grained control over
    /// who may set and who may get such property. Just access control to the Key type itself lacks such fidelity.
    ///
    /// Note that specific baggage and context types MAY (and usually do), offer also a way to set baggage values,
    /// however in the most general case it is not required, as some frameworks may only be able to offer reading.
    public subscript<Key: BaggageKey>(_ key: Key.Type) -> Key.Value? {
        get {
            guard let value = self._storage[AnyBaggageKey(key)] else { return nil }
            // safe to force-cast as this subscript is the only way to set a value.
            return (value as! Key.Value)
        }
        set {
            self._storage[AnyBaggageKey(key)] = newValue
        }
    }
}

extension Baggage {
    /// The number of items in the baggage.
    public var count: Int {
        self._storage.count
    }

    /// A Boolean value that indicates whether the baggage is empty.
    public var isEmpty: Bool {
        self._storage.isEmpty
    }

    /// Iterate through all items in this `Baggage` by invoking the given closure for each item.
    ///
    /// The order of those invocations is NOT guaranteed and should not be relied on.
    ///
    /// - Parameter body: The closure to be invoked for each item stored in this `Baggage`,
    /// passing the type-erased key and the associated value.
    public func forEach(_ body: (AnyBaggageKey, Any) throws -> Void) rethrows {
        try self._storage.forEach { key, value in
            try body(key, value)
        }
    }
}

// MARK: - Propagating Baggage

#if swift(>=5.5) && canImport(_Concurrency)
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension Baggage {
    /// A `Baggage` automatically propagated through task-local storage. This API enables binding a top-level `Baggage` and passing it
    /// implicitly to any child tasks when using structured concurrency.
    @TaskLocal public static var current: Baggage?

    /// Convenience API to bind the task-local ``Baggage/current`` to the passed `value`, and execute the passed `operation`.
    ///
    /// To access the task-local value, use `Baggage.current`.
    ///
    /// SeeAlso: [Swift Task Locals](https://developer.apple.com/documentation/swift/tasklocal)
    public static func withValue<T>(_ value: Baggage?, operation: () throws -> T) rethrows -> T {
        try Baggage.$current.withValue(value, operation: operation)
    }

    /// Convenience API to bind the task-local ``Baggage/current`` to the passed `value`, and execute the passed `operation`.
    ///
    /// To access the task-local value, use `Baggage.current`.
    ///
    /// SeeAlso: [Swift Task Locals](https://developer.apple.com/documentation/swift/tasklocal)
    @_unsafeInheritExecutor // same as withValue declared in the stdlib; because we do not want to hop off the executor at all
    public static func withValue<T>(_ value: Baggage?, operation: () async throws -> T) async rethrows -> T {
        try await Baggage.$current.withValue(value, operation: operation)
    }
}
#endif
