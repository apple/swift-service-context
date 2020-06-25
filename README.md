# Baggage Context

[![Swift 5.2](https://img.shields.io/badge/Swift-5.2-ED523F.svg?style=flat)](https://swift.org/download/)
[![CI](https://github.com/slashmo/gsoc-swift-baggage-context/workflows/CI/badge.svg)](https://github.com/slashmo/gsoc-swift-baggage-context/actions?query=workflow%3ACI)

`BaggageContext` originated in [this repo](https://github.com/slashmo/gsoc-swift-tracing), but had to be factored out so that we can depend on it in our [NIO fork](https://github.com/slashmo/swift-nio).

## Contributing

Please make sure to run the `./scripts/sanity.sh` script when contributing, it checks formatting and similar things.

You can make ensure it always is run and passes before you push by installing a pre-push hook with git:

```
echo './scripts/sanity.sh' > .git/hooks/pre-push
```
