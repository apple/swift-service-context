# Swift Service Context

[![](https://img.shields.io/badge/docc-read_documentation-blue)](https://swiftpackageindex.com/apple/swift-service-context/documentation)
[![](https://img.shields.io/github/v/release/apple/swift-service-context)](https://github.com/apple/swift-service-context/releases)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fapple%2Fswift-service-context%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/apple/swift-service-context)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fapple%2Fswift-service-context%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/apple/swift-service-context)

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
