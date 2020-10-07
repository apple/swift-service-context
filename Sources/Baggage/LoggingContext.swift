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
// MARK: LoggingContext

/// The `LoggingContext` MAY be adopted by specific "framework contexts" such as e.g. `CoolFramework.Context` in
/// order to allow users to pass such context directly to libraries accepting any context.
///
/// This allows frameworks and library authors to offer APIs which compose more easily.
/// Please refer to the "Reference Implementation" notes on each of the requirements to know how to implement this protocol correctly.
///
/// ### Implementation notes
/// Conforming types MUST exhibit Value Semantics (i.e. be a pure `struct`, or implement the Copy-on-Write pattern),
/// in order to implement the `set` requirements of the baggage and logger effectively, and also for their user's sanity,
/// as a reference semantics context type can be very confusing to use when shared between multiple threads, as often is the case in server side environments.
///
/// It is STRONGLY encouraged to use the `DefaultLoggingContext` as inspiration for a correct implementation of a `LoggingContext`,
/// as the relationship between `Logger` and `Baggage` can be tricky to wrap your head around at first.
public protocol LoggingContext {
    /// Get the `Baggage` container.
    ///
    /// ### Implementation notes
    /// Libraries and/or frameworks which conform to this protocol with their "Framework Context" types MUST
    /// ensure that a modification of the baggage is properly represented in the associated `logger`. Users expect values
    /// from the baggage be visible in their log statements issued via `context.logger.info()`.
    ///
    /// Please refer to `DefaultLoggingContext`'s implementation for a reference implementation,
    /// here a short snippet of how the baggage itself should be implemented:
    ///
    ///     public var baggage: Baggage {
    ///         willSet {
    ///             self._logger.updateMetadata(previous: self.baggage, latest: newValue)
    ///         }
    ///     }
    ///
    /// #### Thread Safety
    /// Implementations / MUST take care of thread-safety of modifications of the baggage. They can achieve this by such
    /// context type being a pure `struct` or by implementing Copy-on-Write semantics for their type, the latter gives
    /// many benefits, allowing the context to avoid being copied unless needed to (e.g. if the context type contains
    /// many other values, in addition to the baggage).
    var baggage: Baggage { get set }

    /// The `Logger` associated with this context carrier.
    ///
    /// It automatically populates the loggers metadata based on the `Baggage` associated with this context object.
    ///
    /// ### Implementation notes
    /// Libraries and/or frameworks which conform to this protocol with their "Framework Context" types,
    /// SHOULD implement this logger by wrapping the "raw" logger associated with  `_logger.with(self.baggage)` function,
    /// which efficiently handles the bridging of baggage to logging metadata values.
    ///
    /// If a new logger is set, it MUST populate itself with the latest (current) baggage of the context,
    /// this is to ensure that even if users set a new logger (completely "fresh") here, the metadata from the baggage
    /// still will properly be logged in other pieces of the application where the context might be passed to.
    ///
    /// A correct implementation might look like the following:
    ///
    ///     public var _logger: Logger
    ///         public var logger: Logger {
    ///             get {
    ///                 return self._logger
    ///             }
    ///             set {
    ///                 self._logger = newValue
    ///                 // Since someone could have completely replaced the logger (not just changed the log level),
    ///                 // we have to update the baggage again, since perhaps the new logger has empty metadata.
    ///                 self._logger.updateMetadata(previous: .topLevel, latest: self.baggage)
    ///             }
    ///         }
    ///     }
    ///
    ///
    /// #### Thread Safety
    /// Implementations MUST ensure the thread-safety of mutating the logger. This is usually handled best by the
    /// framework context itself being a Copy-on-Write type, however the exact safety mechanism is left up to the libraries.
    var logger: Logger { get set }
}

/// A default `LoggingContext` type.
///
/// It is a carrier of contextual `Baggage` and related `Logger`, allowing to log and trace throughout a system.
///
/// Any values set on the `baggage` will be made accessible to the logger as call-site metadata, allowing it to log those.
///
/// ### Logged Metadata and Baggage Items
///
/// Please refer to your configured log handler documentation about how to configure which metadata values should be logged
/// and which not, as each log handler may handle and configure those differently. The default implementations log *all*
/// metadata/baggage values present, which often is the right thing, however in larger systems one may want to choose a
/// log handler which allows for configuring these details.
///
/// ### Accepting context types in APIs
///
/// It is preferred to accept values of `LoggingContext` in public library APIs, e.g.:
///
///     func call(string: String, context: LoggingContext) -> Thing
///
/// The context parameter SHOULD be positioned as the *last non-optional not-function parameter*.
/// If unsure how to pass/accept the context, please refer to the project's README for more examples and exact context passing guidelines.
///
/// - SeeAlso: `CoreBaggage.Baggage`
/// - SeeAlso: `Logging.Logger`
public struct DefaultLoggingContext: LoggingContext {
    // We need to store the logger as `_logger` in order to avoid cyclic updates triggering when baggage changes
    public var _logger: Logger
    public var logger: Logger {
        get {
            return self._logger
        }
        set {
            self._logger = newValue
            // Since someone could have completely replaced the logger (not just changed the log level),
            // we have to update the baggage again, since perhaps the new logger has empty metadata.
            self._logger.updateMetadata(previous: .topLevel, latest: self.baggage)
        }
    }

    /// The `Baggage` carried with this context.
    /// It's values will automatically be made available to the `logger` as metadata when logging.
    ///
    /// Baggage values are different from plain logging metadata in that they are intended to be
    /// carried across process and node boundaries (serialized and deserialized) and are made
    /// available to instruments using `swift-distributed-tracing`.
    public var baggage: Baggage {
        willSet {
            // every time the baggage changes, we need to update the logger;
            // values removed from the baggage are also removed from the logger metadata.
            //
            // This implementation generally is a tradeoff, we bet on logging being performed far more often than baggage
            // being changed; We do this logger update eagerly, so even if we never log anything, the logger has to be updated.
            // Systems which never or rarely log will take the hit for it here. The alternative tradeoff to map lazily as `logger.with(baggage)`
            // is available as well, but users would have to build their own context and specifically make use of that then -- that approach
            // allows to not pay the mapping cost up front, but only if a log statement is made (but then again, the cost is paid every time we log something).
            self._logger.updateMetadata(previous: self.baggage, latest: newValue)
        }
    }

    /// Create a default context, which will update the logger any time the context.baggage is modified.
    public init(logger: Logger, baggage: Baggage) {
        self._logger = logger
        self.baggage = baggage
        self._logger.updateMetadata(previous: .topLevel, latest: baggage)
    }

    /// Create a default context, which will update the logger any time the context.baggage is modified.
    public init(context: LoggingContext) {
        self._logger = context.logger
        self.baggage = context.baggage
        self._logger.updateMetadata(previous: .topLevel, latest: self.baggage)
    }
}

// ==== ----------------------------------------------------------------------------------------------------------------
// MARK: `with...` functions

extension DefaultLoggingContext {
    /// Fluent API allowing for modification of underlying logger when passing the context to other functions.
    ///
    /// - Parameter logger: Logger that should replace the underlying logger of this context.
    /// - Returns: new context, with the passed in `logger`
    public func withLogger(_ logger: Logger) -> DefaultLoggingContext {
        var copy = self
        copy.logger = logger
        return copy
    }

    /// Fluent API allowing for modification of underlying logger when passing the context to other functions.
    ///
    /// - Parameter logger: Logger that should replace the underlying logger of this context.
    /// - Returns: new context, with the passed in `logger`
    public func withLogger(_ function: (inout Logger) -> Void) -> DefaultLoggingContext {
        var logger = self.logger
        function(&logger)
        return .init(logger: logger, baggage: self.baggage)
    }

    /// Fluent API allowing for modification of underlying log level when passing the context to other functions.
    ///
    /// - Parameter logLevel: New log level which should be used to create the new context
    /// - Returns: new context, with the passed in `logLevel` used for the underlying logger
    public func withLogLevel(_ logLevel: Logger.Level) -> DefaultLoggingContext {
        var copy = self
        copy.logger.logLevel = logLevel
        return copy
    }

    /// Fluent API allowing for modification a few baggage values when passing the context to other functions, e.g.
    ///
    ///     makeRequest(url, context: context.withBaggage {
    ///         $0.traceID = "fake-value"
    ///         $0.calledFrom = #function
    ///     })
    ///
    /// - Parameter function:
    public func withBaggage(_ function: (inout Baggage) -> Void) -> DefaultLoggingContext {
        var baggage = self.baggage
        function(&baggage)
        return self.withBaggage(baggage)
    }

    /// Fluent API allowing for replacement of underlying baggage when passing the context to other functions.
    ///
    /// - Warning: Use with caution, generally it is not recommended to modify an entire baggage, but rather only add a few values to it.
    ///
    /// - Parameter baggage: baggage that should *replace* the context's current baggage.
    /// - Returns: new context, with the passed in baggage
    public func withBaggage(_ baggage: Baggage) -> DefaultLoggingContext {
        var copy = self
        copy.baggage = baggage
        return copy
    }
}

// ==== ----------------------------------------------------------------------------------------------------------------
// MARK: Context Initializers

extension DefaultLoggingContext {
    /// Creates a new empty "top level" default baggage context, generally used as an "initial" context to immediately be populated with
    /// some values by a framework or runtime. Another use case is for tasks starting in the "background" (e.g. on a timer),
    /// which don't have a "request context" per se that they can pick up, and as such they have to create a "top level"
    /// baggage for their work.
    ///
    /// It is typically used by the main function, initialization, and tests, and as the top-level Context for incoming requests.
    ///
    /// ### Usage in frameworks and libraries
    /// This function is really only intended to be used frameworks and libraries, at the "top-level" where a request's,
    /// message's or task's processing is initiated. For example, a framework handling requests, should create an empty
    /// context when handling a request only to immediately populate it with useful trace information extracted from e.g.
    /// request headers.
    ///
    /// ### Usage in applications
    /// Application code should never have to create an empty context during the processing lifetime of any request,
    /// and only should create contexts if some processing is performed in the background - thus the naming of this property.
    ///
    /// Usually, a framework such as an HTTP server or similar "request handler" would already provide users
    /// with a context to be passed along through subsequent calls.
    ///
    /// If unsure where to obtain a context from, prefer using `.TODO("Not sure where I should get a context from here?")`,
    /// such that other developers are informed that the lack of context was not done on purpose, but rather because either
    /// not being sure where to obtain a context from, or other framework limitations -- e.g. the outer framework not being
    /// context aware just yet.
    public static func topLevel(logger: Logger) -> DefaultLoggingContext {
        return .init(logger: logger, baggage: .topLevel)
    }
}

extension DefaultLoggingContext {
    /// A baggage context intended as a placeholder until a real value can be passed through a function call.
    ///
    /// It should ONLY be used while prototyping or when the passing of the proper context is not yet possible,
    /// e.g. because an external library did not pass it correctly and has to be fixed before the proper context
    /// can be obtained where the TO-DO is currently used.
    ///
    /// ## Crashing on TO-DO context creation
    /// You may set the `BAGGAGE_CRASH_TODOS` variable while compiling a project in order to make calls to this function crash
    /// with a fatal error, indicating where a to-do baggage context was used. This comes in handy when wanting to ensure that
    /// a project never ends up using with code initially was written as "was lazy, did not pass context", yet the
    /// project requires context passing to be done correctly throughout the application. Similar checks can be performed
    /// at compile time easily using linters (not yet implemented), since it is always valid enough to detect a to-do context
    /// being passed as illegal and warn or error when spotted.
    ///
    /// ## Example
    ///
    ///     frameworkHandler { what in
    ///         hello(who: "World", baggage: .TODO(logger: logger, "The framework XYZ should be modified to pass us a context here, and we'd pass it along"))
    ///     }
    ///
    /// - Parameters:
    ///   - reason: Informational reason for developers, why a placeholder context was used instead of a proper one,
    /// - Returns: Empty "to-do" baggage context which should be eventually replaced with a carried through one, or `background`.
    public static func TODO(logger: Logger, _ reason: StaticString? = "", function: String = #function, file: String = #file, line: UInt = #line) -> DefaultLoggingContext {
        let baggage = Baggage.TODO(reason, function: function, file: file, line: line)
        #if BAGGAGE_CRASH_TODOS
        fatalError("BAGGAGE_CRASH_TODOS: at \(file):\(line) (function \(function)), reason: \(reason)", file: file, line: line)
        #else
        return .init(logger: logger, baggage: baggage)
        #endif
    }
}
