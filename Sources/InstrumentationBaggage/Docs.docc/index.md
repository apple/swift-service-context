# ``InstrumentationBaggage``

This type was renamed in the final API to `ServiceContext`, please use the `ServiceContextModule` module to obtain it.

## Overview

``ServiceContext`` is the legacy and deprecated name of this type, please use `ServiceContext` in your APIs.

Baggage, while being a term-of-art for distributed tracing, was not a suitable name for this type because
it was getting used in various situations which are not strictly distributed tracing related.

Please use the `ServiceContextModule` module instead.