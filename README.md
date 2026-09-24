# Swift Service Context

[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-ED523F.svg?style=flat)](https://swift.org/download/)
[![Swift 6.1](https://img.shields.io/badge/Swift-6.0-ED523F.svg?style=flat)](https://swift.org/download/)
[![Swift 6.2](https://img.shields.io/badge/Swift-6.0-ED523F.svg?style=flat)](https://swift.org/download/)

> **This package is now a thin compatibility layer.** The implementation of `ServiceContext` moved into
> [swift-distributed-tracing](https://github.com/apple/swift-distributed-tracing), where the type is named
> `TracingContext`. `import ServiceContextModule` keeps compiling and behaving exactly as it does today,
> with no code changes required.
>
> New projects, and existing ones that can freely update their code, should depend on
> swift-distributed-tracing directly and use `TracingContext` (or `Tracing`, if they also need spans)
> instead of adding this package.

`ServiceContext` is a minimal context propagation container: a value type, propagated through task-local
storage, that carries arbitrary key-value pairs across concurrent Swift code.

## Dependency

If you already depend on this package, you do not need to change anything.

For new code, depend on
[swift-distributed-tracing](https://github.com/apple/swift-distributed-tracing) directly instead:

```swift
dependencies: [
  .package(url: "https://github.com/apple/swift-distributed-tracing.git", from: "1.0.0")
]
```

```swift
targets: [
    .target(
        name: "MyAwesomeApp",
        dependencies: [
            .product(name: "Tracing", package: "swift-distributed-tracing")
        ]
    )
]
```

Depend on the `ContextStorage` product instead of `Tracing` if you only need context propagation, with no
tracing spans.

### Existing dependents

```swift
dependencies: [
  .package(url: "https://github.com/apple/swift-service-context.git", from: "1.0.0")
]
```

```swift
targets: [
    .target(
        name: "MyAwesomeApp",
        dependencies: [
            .product(name: "ServiceContextModule", package: "swift-service-context")
        ]
    )
]
```
