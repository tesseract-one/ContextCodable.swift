//
//  Encodable.swift
//  
//
//  Created by Yehor Popovych on 06/07/2023.
//

import Foundation

public protocol ContextEncodable {
    associatedtype EncodingContext

    func encode(to encoder: Encoder, context: EncodingContext) throws
}

public struct EncodableWrapper<Wrapped: ContextEncodable>: Encodable {
    public let value: Wrapped
    public let context: Wrapped.EncodingContext
    
    @inlinable
    public init(_ v: Wrapped, context: Wrapped.EncodingContext) {
        self.value = v
        self.context = context
    }
    
    @inlinable
    public func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder, context: context)
    }
}

public extension JSONEncoder {
    @inlinable
    func encode<T>(
        _ value: T, context: T.EncodingContext
    ) throws -> Data where T: ContextEncodable {
        try encode(EncodableWrapper(value, context: context))
    }
}

public extension UnkeyedEncodingContainer {
    @inlinable
    mutating func encode<T: ContextEncodable>(
        _ value: T, context: T.EncodingContext
    ) throws {
        try encode(EncodableWrapper(value, context: context))
    }
}

public extension KeyedEncodingContainer {
    @inlinable
    mutating func encode<T: ContextEncodable>(
        _ value: T, forKey key: Key, context: T.EncodingContext
    ) throws {
        try encode(EncodableWrapper(value, context: context),
                   forKey: key)
    }
    
    @inlinable
    mutating func encodeIfPresent<T: ContextEncodable>(
        _ value: T?, forKey key: Key, context: T.EncodingContext
    ) throws {
        try encodeIfPresent(
            value.map { EncodableWrapper($0, context: context) },
            forKey: key
        )
    }
}
