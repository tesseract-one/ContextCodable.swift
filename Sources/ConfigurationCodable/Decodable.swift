//
//  Decodable.swift
//  
//
//  Created by Yehor Popovych on 06/07/2023.
//

import Foundation

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
        guard let configuration = Self.configuration else {
            throw DecodingError.valueNotFound(
                Wrapped.DecodingConfiguration.self,
                DecodingError.Context(codingPath: decoder.codingPath,
                                      debugDescription: "Configuration is empty")
            )
        }
        value = try Wrapped(from: decoder, configuration: configuration)
    }
    
    @inlinable
    public static func set(configuration: Wrapped.DecodingConfiguration) {
        Thread.current.threadDictionary[threadLocalKey] = configuration
    }
    
    @inlinable
    public static var configuration: Wrapped.DecodingConfiguration? {
        defer { clear() }
        guard let conf = Thread.current.threadDictionary[threadLocalKey] else {
            return nil
        }
        return conf as? Wrapped.DecodingConfiguration
    }
    
    @inlinable
    public static func clear() {
        Thread.current.threadDictionary.removeObject(forKey: threadLocalKey)
    }
    
    @inlinable
    public static var threadLocalKey: String { "__DecodableConfigurationThreadLocalKey__" }
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
