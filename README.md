# Baggage Context

[![Swift 5.2](https://img.shields.io/badge/Swift-5.2-ED523F.svg?style=flat)](https://swift.org/download/)
[![Swift 5.1](https://img.shields.io/badge/Swift-5.1-ED523F.svg?style=flat)](https://swift.org/download/)
[![Swift 5.0](https://img.shields.io/badge/Swift-5.0-ED523F.svg?style=flat)](https://swift.org/download/)
[![CI](https://github.com/slashmo/gsoc-swift-baggage-context/workflows/CI/badge.svg)](https://github.com/slashmo/gsoc-swift-baggage-context/actions?query=workflow%3ACI)

`BaggageContext` is a minimal (zero-dependency) "context" library meant to "carry" baggage (metadata) for cross-cutting
tools such as tracers. It is purposefully not tied to any specific use-case (in the spirit of the
[Tracing Plane paper](https://cs.brown.edu/~jcmace/papers/mace18universal.pdf)'s BaggageContext). However, it should
enable a vast majority of use cases cross-cutting tools need to support. Unlike mentioned in the paper, our
`BaggageContext` does not implement its own serialization scheme (today).

See https://github.com/slashmo/gsoc-swift-tracing for actual instrument types and implementations which can be used to
deploy various cross-cutting instruments all reusing the same baggage type. More information can be found in the
[SSWG meeting notes](https://gist.github.com/ktoso/4d160232407e4d5835b5ba700c73de37#swift-baggage-context--distributed-tracing).

## Installation

You can install the `BaggageContext` library through the Swift Package Manager. The library itself is called `Baggage`,
so that's what you'd import in your Swift files.

```swift
dependencies: [
  .package(
    name: "swift-baggage-context",
    url: "https://github.com/slashmo/gsoc-swift-baggage-context.git",
    from: "0.3.0"
  )
]
```

## Usage

`BaggageContext` is intended to be used in conjunction with the instrumentation of distributed systems. To make this
instrumentation work, all parties involved operate on the same `BaggageContext` type. These are the three common
parties, in no specific order, and guidance on how to use `BaggageContext`:

### End Users - explicit context passing

You'll likely interact with some API that takes a context. In most cases you already have a context at hand so you
should pass that along. If you're certain you don't have a context at hand, pass along an empty one after thinking about
why that's the case.

**TODO**: Document the reasoning behind `.background` & `.TODO` once merged ([#26](#26))

While this might seem like a burden to take on, this will allow you to immediately add instrumentation (e.g. tracing)
once your application grows. Let's say your profiling some troublesome performance regressions. You won't have the time
to go through the entire system to start passing contexts around.

> TL;DR: You should always pass around `BaggageContext`, so that you're ready for when you need it.

Once you are ready to instrument your application, you already have everything in place to get going. Instead of each
instrument operating on its own context type they'll be using the same `BaggageContext` that you're already passing
around to the various instrumentable libraries & frameworks you make use of, so you're free to mix & match any
compatible instrument(s) 🙌 Check out the [swift-tracing](https://github.com/slashmo/gsoc-swift-tracing) repository for
instructions on how to get up & running.

### Library & Framework Authors - passing context and instrumenting libraries

Developers creating frameworks/libraries (e.g. NIO, gRPC, AsyncHTTPClient, ...) which benefit from being instrumented
should adopt `BaggageContext` as part of their public API. AsyncHTTPClient for example might accept a context like this:

```swift
let context = BaggageContext()
client.get(url: "https://swift.org", context: context)
```

For more information on where to place this argument and how to name it, take a look at the
[Context-Passing Guidelines](#Context-Passing-Guidelines).

Generally speaking, frameworks and libraries should treat baggage as an _opaque container_ and simply thread it along
all asynchronous boundaries a call may have to go through. Libraries and frameworks should not attempt to reuse context
as a means of passing values that they need for "normal" operation.

At cross-cutting boundaries, e.g. right before sending an HTTP
request, they inject the `BaggageContext` into the HTTP headers, allowing context propagation. On the receiving side, an
HTTP server should extract the request headers into a `BaggageContext`. Injecting/extracting is part of the
`swift-tracing` libraries [and documented in its own repository](https://github.com/slashmo/gsoc-swift-tracing).

### Instrumentation Authors - defining, injecting and extracting baggage

When implementing instrumentation for cross-cutting tools, `BaggageContext` becomes the way you propagate metadata such
as trace ids. Because each instrument knows what values might be added to the `BaggageContext` they are the ones
creating `BaggageContextKey` types dictating the type of value associated with each key added to the context. To make
accessing values a bit more convenient, we encourage you to add computed properties to `BaggageContextProtocol`:

```swift
private enum TraceIDKey: BaggageContextKey {
  typealias Value = String
}

extension BaggageContextProtocol {
  var traceID: String? {
    get {
      return self[TraceIDKey.self]
    }
    set {
      self[TraceIDKey.self] = newValue
    }
  }
}

var context = BaggageContext()
context.traceID = "4bf92f3577b34da6a3ce929d0e0e4736"
print(context.traceID ?? "new trace id")
```

## Context-Passing Guidelines

For context-passing to feel consistent and Swifty among all server-side (and not only) libraries and frameworks
aiming to adopt `BaggageContext` (or any of its uses, such as Distributed Tracing), we suggest the following set of
guidelines:

### Argument naming/positioning

Propagating baggage context through your system is to be done explicitly, meaning as a parameter in function calls,
following the "flow" of execution.

When passing baggage context explicitly we strongly suggest sticking to the following style guideline:

- Assuming the general parameter ordering of Swift function is as follows (except DSL exceptions):
  1. Required non-function parameters (e.g. `(url: String)`),
  2. Defaulted non-function parameters (e.g. `(mode: Mode = .default)`),
  3. Required function parameters, including required trailing closures (e.g. `(onNext elementHandler: (Value) -> ())`),
  4. Defaulted function parameters, including optional trailing closures (e.g. `(onComplete completionHandler: (Reason) -> ()) = { _ in }`).
- Baggage Context should be passed as **the last parameter in the required non-function parameters group in a function declaration**.

This way when reading the call side, users of these APIs can learn to "ignore" or "skim over" the context parameter and
the method signature remains human-readable and “Swifty”.

Examples:

- `func request(_ url: URL,` **`context: BaggageContext`** `)`, which may be called as `httpClient.request(url, context: context)`
- `func handle(_ request: RequestObject,` **`context: BaggageContextCarrier`** `)`
  - if a "framework context" exists and _carries_ the baggage context already, it is permitted to pass that context
  together with the baggage;
  - it is _strongly recommended_ to store the baggage context as `baggage` property of `FrameworkContext` in such cases,
  in order to avoid the confusing spelling of `context.context`, and favoring the self-explanatory `context.baggage`
  spelling when the baggage is contained in a framework context object.
- `func receiveMessage(_ message: Message, context: FrameworkContext)`
- `func handle(element: Element,` **`context: BaggageContextCarrier`** `, settings: Settings? = nil)`
  - before any defaulted non-function parameters
- `func handle(element: Element,` **`context: BaggageContextCarrier`** `, settings: Settings? = nil, onComplete: () -> ())`
  - before defaulted parameters, which themselfes are before required function parameters
- `func handle(element: Element,` **`context: BaggageContextCarrier`** `, onError: (Error) -> (), onComplete: (() -> ())? = nil)`

In case there are _multiple_ "framework-ish" parameters, such as passing a NIO `EventLoop` or similar, we suggest:

- `func perform(_ work: Work, for user: User,` _`frameworkThing: Thing, eventLoop: NIO.EventLoop,`_ **`context: BaggageContext`** `)`
  - pass the baggage as **last** of such non-domain specific parameters as it will be _by far more_ omnipresent than any
  specific framework parameter - as it is expected that any framework should be accepting a context if it can do so.
  While not all libraries are necessarily going to be implemented using the same frameworks.

We feel it is important to preserve Swift's human-readable nature of function definitions. In other words, we intend to
keep the read-out-loud phrasing of methods to remain _"request that URL (ignore reading out loud the context parameter)"_
rather than _"request (ignore this context parameter when reading) that URL"_.

#### When to use what context type?

This library defines the following context (carrier) types:

- `struct BaggageContext` - which is the actual context object,
- `protocol BaggageContextCarrier` - which should be used whenever a library implements an API and does not necessarily
care where it gets a `context` value from
  - this pattern enables other frameworks to pass their `FrameworkContext`, like so:
  `get(context: MyFrameworkContext())` if they already have such context in scope (e.g. Vapor's `Request` object is a
  good example, or Lambda Runtime's `Lambda.Context`
- `protocol LoggingBaggageContextCarrier` - which in addition exposes a logger bound to the passed context

Finally, some frameworks will have APIs which accept the specific `MyFrameworkContext`, withing frameworks specifically
a lot more frequently than libraries one would hope. It is important when designing APIs to keep in mind -- can this API
work with any context, or is it always going to require _my framework context_, and erring on accepting the most
general type possible.

#### Existing context argument

When adapting an existing library/framework to support `BaggageContext` and it already has a "framework context" which
is expected to be passed through "everywhere", we suggest to follow these guidelines for adopting BaggageContext:

1. Add a `BaggageContext` as a property called `baggage` to your own `context` type, so that the call side for your
users becomes `context.baggage` (rather than the confusing `context.context`)
2. If you cannot or it would not make sense to carry baggage inside your framework's context object,
pass (and accept (!)) the `BaggageContext` in your framework functions like follows:
  - if they take no framework context, accept a `context: BaggageContext` which is the same guideline as for all other
  cases
  - if they already _must_ take a context object and you are out of words (or your API already accepts your framework
  context as "context"), pass the baggage as **last** parameter (see above) yet call the parameter `baggage` to
  disambiguate your `context` object from the `baggage` context object.

Examples:

- `Lamda.Context` may contain `baggage` and this way offer traceIDs and other values
  - passing context to a `Lambda.Context` unaware library becomes: `http.request(url: "...", context: context.baggage)`.
  - TODO: We are considering a protocol which would simplify this if it is known that Lambda.Context "carries" baggage...
- `ChannelHandlerContext` offers a way to set/get baggage on the underlying channel via `context.baggage = ...`
  - WorkInProgress, see: https://github.com/apple/swift-nio/pull/1574


## Contributing

Please make sure to run the `./scripts/sanity.sh` script when contributing, it checks formatting and similar things.

You can make ensure it always is run and passes before you push by installing a pre-push hook with git:

```
echo './scripts/sanity.sh' > .git/hooks/pre-push
```
