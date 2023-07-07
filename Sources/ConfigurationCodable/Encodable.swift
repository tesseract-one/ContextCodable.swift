//
//  Encodable.swift
//  
//
//  Created by Yehor Popovych on 06/07/2023.
//

import Foundation

public protocol EncodableWithConfiguration {
    associatedtype EncodingConfiguration

    func encode(to encoder: Encoder, configuration: EncodingConfiguration) throws
}

public struct EncodableWrapper<Wrapped: EncodableWithConfiguration>: Encodable {
    public let value: Wrapped
    public let configuration: Wrapped.EncodingConfiguration
    
    @inlinable
    public init(_ v: Wrapped, configuration: Wrapped.EncodingConfiguration) {
        self.value = v
        self.configuration = configuration
    }
    
    @inlinable
    public func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder, configuration: configuration)
    }
}

public extension JSONEncoder {
    @inlinable
    func encode<T>(
        _ t: T, configuration: T.EncodingConfiguration
    ) throws -> Data where T: EncodableWithConfiguration {
        try encode(EncodableWrapper(t, configuration: configuration))
    }
}

public extension UnkeyedEncodingContainer {
    @inlinable
    mutating func encode<T: EncodableWithConfiguration>(
        _ value: T, configuration: T.EncodingConfiguration
    ) throws {
        try encode(EncodableWrapper(value, configuration: configuration))
    }
}

public extension KeyedEncodingContainer {
    @inlinable
    mutating func encode<T: EncodableWithConfiguration>(
        _ value: T, forKey key: Key, configuration: T.EncodingConfiguration
    ) throws {
        try encode(EncodableWrapper(value, configuration: configuration),
                   forKey: key)
    }
    
    @inlinable
    mutating func encodeIfPresent<T: EncodableWithConfiguration>(
        _ value: T?, forKey key: Key, configuration: T.EncodingConfiguration
    ) throws {
        try encodeIfPresent(
            value.map { EncodableWrapper($0, configuration: configuration) },
            forKey: key
        )
    }
}
