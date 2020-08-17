# Baggage Context

[![Swift 5.2](https://img.shields.io/badge/Swift-5.2-ED523F.svg?style=flat)](https://swift.org/download/)
[![CI](https://github.com/slashmo/gsoc-swift-baggage-context/workflows/CI/badge.svg)](https://github.com/slashmo/gsoc-swift-baggage-context/actions?query=workflow%3ACI)

`BaggageContext` is a minimal (zero-dependency) "context" library meant to "carry" baggage (metadata) for cross-cutting tools such as tracers.
It is purposefully not tied to any specific use-case (in the spirit of the [Tracing Plane paper](https://cs.brown.edu/~jcmace/papers/mace18universal.pdf)'s BaggageContext), however it should enable a vast majority of use cases cross-cutting tools need to support. Unlike mentioned in the paper, our `BaggageContext` does not implement its own serialization scheme (today).

See https://github.com/slashmo/gsoc-swift-tracing for actual instrument types and implementations which can be used to deploy various cross-cutting instruments all reusing the same baggage type. More information can be found in the [SSWG meeting notes](https://gist.github.com/ktoso/4d160232407e4d5835b5ba700c73de37#swift-baggage-context--distributed-tracing).

## Installation

You can install the `BaggageContext` library through the Swift Package Manager. The library itself is called `Baggage`, so that's what you'd import in your Swift files.

```swift
dependencies: [
  .package(
    name: "swift-baggage-context",
    url: "https://github.com/slashmo/gsoc-swift-baggage-context.git",
    from: "0.3.0"
  )
]
```

## Context-Passing Guidelines

In order for context-passing to feel consistent and Swifty among all server-side (and not only) libraries and frameworks
aiming to adopt `BaggageContext` (or any of its uses, such as Distributed Tracing), we suggest the following set of guidelines:

### Argument naming/positioning

In order to propagate baggage through function calls (and asynchronous-boundaries it may often be necessary to pass it explicitly (unless wrapper APIs are provided which handle the propagation automatically).

When passing baggage context explicitly we strongly suggest sticking to the following style guideline:

- Assuming the general parameter ordering of Swift function is as follows (except DSL exceptions):
  1. Required non-function parameters (e.g. `(url: String)`),
  2. Defaulted non-function parameters (e.g. `(mode: Mode = .default)`),
  3. Required function parameters, including required trailing closures (e.g. `(onNext elementHandler: (Value) -> ())`),
  4. Defaulted function parameters, including optional trailing closures (e.g. `(onComplete completionHandler: (Reason) -> ()) = { _ in }`).
- Baggage Context should be passed as: **the last parameter in the required non-function parameters group in a function declaration**.

This way when reading the call side, users of these APIs can learn to "ignore" or "skim over" the context parameter and the method signature remains human-readable and “Swifty”.

Examples:

- `func request(_ url: URL,` **`context: BaggageContext`** `)`, which may be called as `httpClient.request(url, context: context)`
- `func handle(_ request: RequestObject,` **`context: BaggageContextCarrier`** `)`
  - if a "framework context" exists and _carries_ the baggage context already, it is permitted to pass that context together with the baggage;
  - it is _strongly recommended_ to store the baggage context as `baggage` property of `FrameworkContext` in such cases, in order to avoid the confusing spelling of `context.context`, and favoring the self-explanatory `context.baggage` spelling when the baggage is contained in a framework context object.
- `func receiveMessage(_ message: Message, context: FrameworkContext)`
- `func handle(element: Element,` **`context: BaggageContextCarrier`** `, settings: Settings? = nil)`
  - before any defaulted non-function parameters
- `func handle(element: Element,` **`context: BaggageContextCarrier`** `, settings: Settings? = nil, onComplete: () -> ())`
  - before defaulted parameters, which themselfes are before required function parameters
- `func handle(element: Element,` **`context: BaggageContextCarrier`** `, onError: (Error) -> (), onComplete: (() -> ())? = nil)`

In case there are _multiple_ "framework-ish" parameters, such as passing a NIO `EventLoop` or similar, we suggest:

- `func perform(_ work: Work, for user: User,` _`frameworkThing: Thing, eventLoop: NIO.EventLoop,`_ **`context: BaggageContext`** `)`
  - pass the baggage as **last** of such non-domain specific parameters as it will be _by far more_ omnipresent than any specific framework parameter - as it is expected that any framework should be accepting a context if it is able to do so. While not all libraries are necessarily going to be implemented using the same frameworks.

We feel it is important to preserve Swift's human-readable nature of function definitions. In other words, we intend to keep the read-out-loud phrasing of methods to remain _"request that url (ignore reading out loud the context parameter)"_ rather than _"request (ignore this context parameter when reading) that url"_.

#### When to use what context type?

This library defines the following context (carrier) types:

- `struct BaggageContext` - which is the actual context object,
- `protocol BaggageContextCarrier` - which should be used whenever a library implements an API and does not necessarily care where it gets a `context` value from
  - this pattern enables other frameworks to pass their `FrameworkContext`, like so: `get(context: MyFrameworkContext())` if they already have such context in scope (e.g. Vapor's `Request` object is a good example, or Lambda Runtime's `Lambda.Context`
- `protocol LoggingBaggageContextCarrier` - which in addition exposes a logger bound to the passed context

Finally, some frameworks will have APIs which accept the specific `MyFrameworkContext`, withing frameworks specifically a lot more frequently than libraries one would hope. It is important when designing APIs to keep in mind -- can this API work with any context, or is it always going to require _my framework context_, and erring on accepting the most general type possible.

#### Existing context argument

When adapting an existing library/framework to support `BaggageContext` and it already has a "framework context" which is expected to be passed through "everywhere", we suggest to follow these guidelines to adopting BaggageContext:

1. Add a `BaggageContext` as a property called `baggage` to your own `context` type, so that the call side for your users becomes `context.baggage` (rather than the confusing `context.context`)
2. If you cannot or it would not make sense to carry baggage inside your framework's context object, pass (and accept (!)) the `BaggageContext` in your framework functions like follows:
  - if they take no framework context, accept a `context: BaggageContext` which is the same guideline as for all other cases
  - if they already _must_ take a context object and you are out of words (or your API already accepts your framework context as "context"), pass the baggage as **last** parameter (see above) yet call the parameter `baggage` to disambiguate your `context` object from the `baggage` context object.

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
