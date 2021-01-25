# 🧳 Distributed Tracing: LoggingContext / Baggage

[![Swift 5.2](https://img.shields.io/badge/Swift-5.2-ED523F.svg?style=flat)](https://swift.org/download/)
[![Swift 5.1](https://img.shields.io/badge/Swift-5.1-ED523F.svg?style=flat)](https://swift.org/download/)
[![Swift 5.0](https://img.shields.io/badge/Swift-5.0-ED523F.svg?style=flat)](https://swift.org/download/)

`LoggingContext` is a minimal (zero-dependency) "context" library meant to "carry" baggage (metadata) for cross-cutting
tools such as tracers. It is purposefully not tied to any specific use-case (in the spirit of the
[Tracing Plane paper](https://cs.brown.edu/~jcmace/papers/mace18universal.pdf)'s BaggageContext). However, it should
enable a vast majority of use cases cross-cutting tools need to support. Unlike mentioned in the paper, our
`LoggingContext` does not implement its own serialization scheme (today).

See https://github.com/apple/swift-distributed-tracing for actual instrument types and implementations which can be used to
deploy various cross-cutting instruments all reusing the same baggage type. More information can be found in the
[SSWG meeting notes](https://gist.github.com/ktoso/4d160232407e4d5835b5ba700c73de37#swift-baggage-context--distributed-tracing).

## Installation

You can install the `LoggingContext` library through the Swift Package Manager. The library itself is called `Baggage`,
so that's what you'd import in your Swift files.

```swift
dependencies: [
  // ... 
  .package(url: "https://github.com/apple/swift-distributed-tracing-baggage.git", from: "0.1.0"),
]
```

## Documentation

Please refer to in-depth discussion and documentation in the [Swift Distributed Tracing](https://github.com/apple/swift-distributed-tracing) repository.

## Contributing

Please make sure to run the `./scripts/soundness.sh` script when contributing, it checks formatting and similar things.

You can make ensure it always is run and passes before you push by installing a pre-push hook with git:

```
echo './scripts/soundness.sh' > .git/hooks/pre-push
```
