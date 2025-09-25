# ``ServiceContextModule``

Common currency type for type-safe and Swift concurrency aware context propagation.

## Overview

``ServiceContext`` is a minimal (zero-dependency) context propagation container, intended to "carry" context items
for purposes of cross-cutting tools to be built on top of it.

It is modeled after the concepts explained in [W3C Baggage](https://w3c.github.io/baggage/) and the
in the spirit of [Tracing Plane](https://cs.brown.edu/~jcmace/papers/mace18universal.pdf)'s "Baggage Context" type,
although by itself it doesn't define a specific serialization format.

See the [Swift Distributed Tracing](https://github.com/apple/swift-distributed-tracing) repository for instrument types
and implementations you can use to deploy various cross-cutting instruments that all reuse the same context type. 
More information can be found in the
[SSWG meeting notes](https://gist.github.com/ktoso/4d160232407e4d5835b5ba700c73de37#swift-baggage-context--distributed-tracing).

> Note: Automatic propagation through task-locals by using `ServiceContext.current` is supported in Swift version 5.5 or later.

## Getting started

In order to depend on this library you can use the Swift Package Manager, and add the following dependency to your `Package.swift`:

```swift
dependencies: [
  .package(
    url: "https://github.com/apple/swift-service-context.git",
    from: "0.2.0"
  )
]
```

and depend on the module in your target:

```swift
targets: [
    .target(
        name: "MyAwesomeApp",
        dependencies: [
            .product(
              name: "ServiceContextModule",
              package: "swift-service-context"
            ),
        ]
    ),
    // ...
]
```

### Usage

Please refer to in-depth discussion and documentation in the [Swift Distributed Tracing](https://github.com/apple/swift-distributed-tracing) repository.

## Topics

- ``ServiceContext``
- ``ServiceContextKey``
- ``AnyServiceContextKey``
- ``TODOLocation``

