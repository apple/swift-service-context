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

/// A `ServiceContext` is a heterogeneous storage type with value semantics for keyed values in a type-safe fashion.
///
/// Its values are uniquely identified via ``ServiceContextKey``s (by type identity). These keys also dictate the type of
/// value allowed for a specific key-value pair through their associated type `Value`.
///
/// ## Defining keys and accessing values
/// ServiceContext keys are defined as types, most commonly case-less enums (as no actual instances are required)
/// which conform to the ``ServiceContextKey`` protocol:
///
///     private enum TestIDKey: ServiceContextKey {
///       typealias Value = String
///     }
///
/// While defining a key, one should also immediately declare an extension on `ServiceContext` to allow convenient and discoverable ways to interact
/// with the context item. The extension should take the form of:
///
///     extension ServiceContext {
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
/// Using a context container is fairly straight forward, as it boils down to using the prepared computed properties:
///
///     var context = ServiceContext.topLevel
///     // set a new value
///     context.testID = "abc"
///     // retrieve a stored value
///     let testID = context.testID ?? "default"
///     // remove a stored value
///     context.testIDKey = nil
///
/// Note that normally a context should not be "created" ad-hoc by user code, but rather it should be passed to it from
/// a runtime. A `ServiceContext` may already be available to you through ServiceContext.$current when using structured concurrency.
/// Otherwise, for example when working in an HTTP server framework, it is most likely that the context is already passed
/// directly or indirectly (e.g. in a `FrameworkContext`).
///
/// ### Accessing all values
///
/// The only way to access "all" values in a context is by using the `forEach` function.
/// `ServiceContext` does not expose more functions on purpose to prevent abuse and treating it as too much of an
/// arbitrary value smuggling container, but only make it convenient for tracing and instrumentation systems which need
/// to access either specific or all items carried inside a context.
public struct ServiceContext: Sendable {
    private var _storage = [AnyServiceContextKey: Sendable]()

    /// Internal on purpose, please use ``ServiceContext/TODO(_:function:file:line:)`` or ``ServiceContext/topLevel`` to create an "empty" context,
    /// which carries more meaning to other developers why an empty context was used.
    init() {}
}

// MARK: - Creating ServiceContext

extension ServiceContext {
    /// Creates a new empty "top level" context, generally used as an "initial" context to immediately be populated with
    /// some values by a framework or runtime. Another use case is for tasks starting in the "background" (e.g. on a timer),
    /// which don't have a "request context" per se that they can pick up, and as such they have to create a "top level"
    /// context for their work.
    ///
    /// ## Usage in frameworks and libraries
    /// This function is really only intended to be used by frameworks and libraries, at the "top-level" where a request's,
    /// message's or task's processing is initiated. For example, a framework handling requests, should create an empty
    /// context when handling a request only to immediately populate it with useful trace information extracted from e.g.
    /// request headers.
    ///
    /// ## Usage in applications
    /// Application code should never have to create an empty context during the processing lifetime of any request,
    /// and only should create context if some processing is performed in the background - thus the naming of this property.
    ///
    /// Usually, a framework such as an HTTP server or similar "request handler" would already provide users
    /// with a context to be passed along through subsequent calls, either implicitly through the task-local `ServiceContext.$current`
    /// or explicitly as part of some kind of "FrameworkContext".
    ///
    /// If unsure where to obtain a context from, prefer using `.TODO("Not sure where I should get a context from here?")`
    /// in order to inform other developers that the lack of context passing was not done on purpose, but rather because either
    /// not being sure where to obtain a context from, or other framework limitations -- e.g. the outer framework not being
    /// context aware just yet.
    public static var topLevel: ServiceContext {
        ServiceContext()
    }
}

extension ServiceContext {
    /// A context intended as a placeholder until a real value can be passed through a function call.
    ///
    /// It should ONLY be used while prototyping or when the passing of the proper context is not yet possible,
    /// e.g. because an external library did not pass it correctly and has to be fixed before the proper context
    /// can be obtained where the TO-DO is currently used.
    ///
    /// ## Crashing on TO-DO context creation
    /// You may set the `SERVICE_CONTEXT_CRASH_TODOS` variable while compiling a project in order to make calls to this function crash
    /// with a fatal error, indicating where a to-do context was used. This comes in handy when wanting to ensure that
    /// a project never ends up using code which initially was written as "was lazy, did not pass context", yet the
    /// project requires context passing to be done correctly throughout the application. Similar checks can be performed
    /// at compile time easily using linters (not yet implemented), since it is always valid enough to detect a to-do context
    /// being passed as illegal and warn or error when spotted.
    ///
    /// ## Example
    ///
    ///     let context = ServiceContext.TODO("The framework XYZ should be modified to pass us a context here, and we'd pass it along"))
    ///
    /// - Parameters:
    ///   - reason: Informational reason for developers, why a placeholder context was used instead of a proper one,
    ///   - function: The function to which the TODO refers.
    ///   - file: The file to which the TODO refers.
    ///   - line: The line to which the TODO refers.
    /// - Returns: Empty "to-do" context which should be eventually replaced with a carried through one, or `topLevel`.
    public static func TODO(
        _ reason: StaticString? = "",
        function: String = #function,
        file: String = #file,
        line: UInt = #line
    ) -> ServiceContext {
        var context = ServiceContext()
        #if BAGGAGE_CRASH_TODOS
        fatalError("BAGGAGE_CRASH_TODOS: at \(file):\(line) (function \(function)), reason: \(reason)")
        #elseif SERVICE_CONTEXT_CRASH_TODOS
        fatalError("SERVICE_CONTEXT_CRASH_TODOS: at \(file):\(line) (function \(function)), reason: \(reason)")
        #else
        context[TODOKey.self] = .init(file: file, line: line)
        return context
        #endif
    }

    private enum TODOKey: ServiceContextKey {
        typealias Value = TODOLocation
        static var nameOverride: String? {
            "todo"
        }
    }
}

/// Carried automatically by a "to do" context.
/// It can be used to track where a context originated and which "to do" context must be fixed into a real one to avoid this.
public struct TODOLocation: Sendable {
    /// Source file location where the to-do ``ServiceContext`` was created
    public let file: String
    /// Source line location where the to-do ``ServiceContext`` was created
    public let line: UInt
}

// MARK: - Interacting with ServiceContext

extension ServiceContext {
    /// Provides type-safe access to the context's values.
    /// This API should ONLY be used inside of accessor implementations.
    ///
    /// End users should use "accessors" the key's author MUST define rather than using this subscript, following this pattern:
    ///
    ///     internal enum TestID: ServiceContext.Key {
    ///         typealias Value = TestID
    ///     }
    ///
    ///     extension ServiceContext {
    ///         public internal(set) var testID: TestID? {
    ///             get {
    ///                 self[TestIDKey.self]
    ///             }
    ///             set {
    ///                 self[TestIDKey.self] = newValue
    ///             }
    ///         }
    ///     }
    ///
    /// This is in order to enforce a consistent style across projects and also allow for fine grained control over
    /// who may set and who may get such property. Just access control to the Key type itself lacks such fidelity.
    ///
    /// Note that specific context and context types MAY (and usually do), offer also a way to set context values,
    /// however in the most general case it is not required, as some frameworks may only be able to offer reading.
    public subscript<Key: ServiceContextKey>(_ key: Key.Type) -> Key.Value? {
        get {
            guard let value = self._storage[AnyServiceContextKey(key)] else { return nil }
            // safe to force-cast as this subscript is the only way to set a value.
            return (value as! Key.Value)
        }
        set {
            self._storage[AnyServiceContextKey(key)] = newValue
        }
    }
}

extension ServiceContext {
    /// The number of items in the context.
    public var count: Int {
        self._storage.count
    }

    /// A Boolean value that indicates whether the context is empty.
    public var isEmpty: Bool {
        self._storage.isEmpty
    }

    /// Iterate through all items in this `ServiceContext` by invoking the given closure for each item.
    ///
    /// The order of those invocations is NOT guaranteed and should not be relied on.
    ///
    /// - Parameter body: The closure to be invoked for each item stored in this `ServiceContext`,
    /// passing the type-erased key and the associated value.
    @preconcurrency
    public func forEach(_ body: (AnyServiceContextKey, any Sendable) throws -> Void) rethrows {
        // swift-format-ignore: ReplaceForEachWithForLoop
        try self._storage.forEach { key, value in
            try body(key, value)
        }
    }
}

// MARK: - Propagating ServiceContext

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension ServiceContext {
    /// A `ServiceContext` is automatically propagated through task-local storage. This API enables binding a top-level `ServiceContext` and
    /// implicitly passes it to child tasks when using structured concurrency.
    @TaskLocal public static var current: ServiceContext?

    /// Convenience API to bind the task-local ``ServiceContext/current`` to the passed `value`, and execute the passed `operation`.
    ///
    /// To access the task-local value, use `ServiceContext.current`.
    ///
    /// SeeAlso: [Swift Task Locals](https://developer.apple.com/documentation/swift/tasklocal)
    public static func withValue<T>(_ value: ServiceContext?, operation: () throws -> T) rethrows -> T {
        try ServiceContext.$current.withValue(value, operation: operation)
    }

    #if compiler(>=6.0)
    /// Convenience API to bind the task-local ``ServiceContext/current`` to the passed `value`, and execute the passed `operation`.
    ///
    /// To access the task-local value, use `ServiceContext.current`.
    ///
    /// SeeAlso: [Swift Task Locals](https://developer.apple.com/documentation/swift/tasklocal)
    public static func withValue<T>(
        _ value: ServiceContext?,
        isolation: isolated (any Actor)? = #isolation,
        operation: () async throws -> T
    ) async rethrows -> T {
        try await ServiceContext.$current.withValue(value, operation: operation)
    }

    @available(*, deprecated, message: "Use the method with the isolation parameter instead.")
    // Deprecated trick to avoid executor hop here; 6.0 introduces the proper replacement: #isolation
    @_disfavoredOverload
    public static func withValue<T>(_ value: ServiceContext?, operation: () async throws -> T) async rethrows -> T {
        try await ServiceContext.$current.withValue(value, operation: operation)
    }
    #else
    @_unsafeInheritExecutor
    public static func withValue<T>(_ value: ServiceContext?, operation: () async throws -> T) async rethrows -> T {
        try await ServiceContext.$current.withValue(value, operation: operation)
    }
    #endif
}
