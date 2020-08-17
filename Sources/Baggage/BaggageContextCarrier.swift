//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Context Propagation open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift Baggage Context project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

// ==== ----------------------------------------------------------------------------------------------------------------
// MARK: Framework Context Protocols

/// Framework context protocols may conform to this protocol if they are used to carry a baggage object.
///
/// Notice that the baggage context property is spelled as `baggage`, this is purposefully designed in order to read well
/// with framework context's which often will be passed as `context: FrameworkContext` and used as `context.baggage`.
///
/// Such carrier protocol also conforms to `BaggageContextProtocol` meaning that it has the same convenient accessors
/// as the actual baggage type. Users should be able to use the `context.myValue` the same way if a raw baggage context,
/// or a framework context was passed around as `context` parameter, allowing for easier migrations between those two when needed.
public protocol BaggageContextCarrier: BaggageContextProtocol {
    /// The underlying `BaggageContext`.
    var baggage: BaggageContext { get set }
}

extension BaggageContextCarrier {
    public subscript<Key: BaggageContextKey>(baggageKey: Key.Type) -> Key.Value? {
        get {
            return self.baggage[baggageKey]
        } set {
            self.baggage[baggageKey] = newValue
        }
    }

    public func forEach(_ callback: (AnyBaggageContextKey, Any) -> Void) {
        self.baggage.forEach(callback)
    }
}

/// A baggage itself also is a carrier of _itself_.
extension BaggageContext: BaggageContextCarrier {
    public var baggage: BaggageContext {
        get {
            return self
        }
        set {
            self = newValue
        }
    }
}
