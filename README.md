# 🧳 Distributed Tracing: Baggage

[![Swift 5.5](https://img.shields.io/badge/Swift-5.5-ED523F.svg?style=flat)](https://swift.org/download/)

`Baggage` is a minimal (zero-dependency) context propagation container, intended to "carry" baggage items
for purposes of cross-cutting tools to be built on top of it.

It is modeled after the concepts explained in [W3C Baggage](https://w3c.github.io/baggage/) and the 
in the spirit of [Tracing Plane](https://cs.brown.edu/~jcmace/papers/mace18universal.pdf) 's "Baggage Context" type,
although by itself it does not define a specific serialization format.

See https://github.com/apple/swift-distributed-tracing for actual instrument types and implementations which can be used to
deploy various cross-cutting instruments all reusing the same baggage type. More information can be found in the
[SSWG meeting notes](https://gist.github.com/ktoso/4d160232407e4d5835b5ba700c73de37#swift-baggage-context--distributed-tracing).

## Dependency

 In order to depend on this library you can use the Swift Package Manager, and add the following dependency to your `Package.swift`:

```swift
dependencies: [
  .package(
    url: "https://github.com/apple/swift-distributed-tracing-baggage-core.git",
    from: "0.1.0"
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
              name: "BaggageModule", 
              package: "swift-distributed-tracing-baggage"
            ),
        ]
    ),
    // ... 
]
```

## Documentation

Please refer to in-depth discussion and documentation in the [Swift Distributed Tracing](https://github.com/apple/swift-distributed-tracing) repository.

## Contributing

Please make sure to run the `./scripts/soundness.sh` script when contributing, it checks formatting and similar things.

You can ensure it always runs and passes before you push by installing a pre-push hook with git:

```
echo './scripts/soundness.sh' > .git/hooks/pre-push
chmod +x .git/hooks/pre-push
```
