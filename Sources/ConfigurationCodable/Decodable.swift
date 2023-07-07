//
//  Decodable.swift
//  
//
//  Created by Yehor Popovych on 06/07/2023.
//

import Foundation
import CoreFoundation

public typealias CodableWithConfiguration =
    DecodableWithConfiguration & EncodableWithConfiguration

public protocol DecodableWithConfiguration {
    associatedtype DecodingConfiguration

    init(from decoder: Decoder, configuration: DecodingConfiguration) throws
}

public struct DecodableWrapper<Wrapped: DecodableWithConfiguration>: Decodable {
    public let value: Wrapped
    
    @inlinable
    public init(from decoder: Decoder) throws {
        guard let anyconf = Self.configuration() else {
            throw DecodingError.valueNotFound(
                Wrapped.DecodingConfiguration.self,
                DecodingError.Context(codingPath: decoder.codingPath,
                                      debugDescription: "Configuration is empty")
            )
        }
        guard let conf = anyconf as? Wrapped.DecodingConfiguration else {
            let error = "Configuration has different type \(type(of: anyconf))"
            throw DecodingError.typeMismatch(
                Wrapped.DecodingConfiguration.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: error
                )
            )
        }
        value = try Wrapped(from: decoder, configuration: conf)
    }
    
    public static func set(configuration: Wrapped.DecodingConfiguration) {
        DecodableThreadLocalKey.set(value: configuration)
    }
    
    // One time call. Will remove configuration from ThreadLocal
    // Any because body is unknown (try cast it)
    public static func configuration() -> Any? {
        DecodableThreadLocalKey.replace(with: nil)
    }
    
    public static var threadLocalKey: ThreadLocal<Any> { DecodableThreadLocalKey }
}

public extension JSONDecoder {
    @inlinable
    func decode<T: DecodableWithConfiguration>(
        _: T.Type, from data: Data, configuration: T.DecodingConfiguration
    ) throws -> T {
        DecodableWrapper<T>.set(configuration: configuration)
        return try decode(DecodableWrapper<T>.self, from: data).value
    }
}

public extension UnkeyedDecodingContainer {
    @inlinable
    mutating func decode<T: DecodableWithConfiguration>(
        _: T.Type, configuration: T.DecodingConfiguration
    ) throws -> T {
        DecodableWrapper<T>.set(configuration: configuration)
        return try decode(DecodableWrapper<T>.self).value
    }
}

public extension KeyedDecodingContainer {
    @inlinable
    func decode<T: DecodableWithConfiguration>(
        _: T.Type, forKey key: Key, configuration: T.DecodingConfiguration
    ) throws -> T {
        DecodableWrapper<T>.set(configuration: configuration)
        return try decode(DecodableWrapper<T>.self, forKey: key).value
    }
    
    @inlinable
    func decodeIfPresent<T: DecodableWithConfiguration>(
        _: T.Type, forKey key: Key, configuration: T.DecodingConfiguration
    ) throws -> T? {
        DecodableWrapper<T>.set(configuration: configuration)
        return try decodeIfPresent(DecodableWrapper<T>.self, forKey: key)?.value
    }
}

private let DecodableThreadLocalKey = ThreadLocal<Any>()
