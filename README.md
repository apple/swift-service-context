# Swift Service Context

[![](https://img.shields.io/badge/docc-read_documentation-blue)](https://swiftpackageindex.com/apple/swift-service-context/documentation)
[![](https://img.shields.io/github/v/release/apple/swift-service-context)](https://github.com/apple/swift-service-context/releases)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fapple%2Fswift-service-context%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/apple/swift-service-context)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fapple%2Fswift-service-context%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/apple/swift-service-context)

`ServiceContext` is a minimal (zero-dependency) context propagation container, intended to "carry" items for purposes of cross-cutting tools to be built on top of it.

It is modeled after the concepts explained in [W3C Baggage](https://w3c.github.io/baggage/) and 
in the spirit of [Tracing Plane](https://cs.brown.edu/~jcmace/papers/mace18universal.pdf) 's "Baggage Context" type,
although by itself it does not define a specific serialization format.

See https://github.com/apple/swift-distributed-tracing for actual instrument types and implementations which can be used to
deploy various cross-cutting instruments all reusing the same baggage type. More information can be found in the
[SSWG meeting notes](https://gist.github.com/ktoso/4d160232407e4d5835b5ba700c73de37#swift-baggage-context--distributed-tracing).

## Overview

`ServiceContext` serves as currency type for carrying around additional contextual information between Swift tasks and functions.

One generally starts from a "top level" (empty) or the "current" (`ServiceContext.current`) context and then adds values to it.

The context is a value type and is propagated using task-local values so it can be safely used from concurrent contexts like this:

```swift
var context = ServiceContext.topLevel
context[FirstTestKey.self] = 42

func exampleFunction() async -> Int {
    guard let context = ServiceContext.current else {
        return 0
    }
    guard let value = context[FirstTestKey.self] else {
        return 0
    }
    print("test = \(value)") // test = 42
    return value
}

let c = await ServiceContext.withValue(context) {
    await exampleFunction()
}
assert(c == 42)
```

`ServiceContext` is a fundamental building block for how distributed tracing propagates trace identifiers.

## Dependency

In order to depend on this library you can use the Swift Package Manager, and add the following dependency to your `Package.swift`:

```swift
dependencies: [
  .package(
    url: "https://github.com/apple/swift-service-context.git",
    from: "1.0.0"
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

## Building with CMake

See [the CMake build instructions](cmake/README.md) for library builds and consumer validation.
