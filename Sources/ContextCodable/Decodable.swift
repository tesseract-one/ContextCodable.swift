//
//  Decodable.swift
//  
//
//  Created by Yehor Popovych on 06/07/2023.
//

import Foundation

public typealias ContextCodable = ContextDecodable & ContextEncodable

public protocol ContextDecodable {
    associatedtype DecodingContext

    init(from decoder: Decoder, context: DecodingContext) throws
}

public struct DecodableWrapper<Wrapped: ContextDecodable>: Decodable {
    public let value: Wrapped
    
    @inlinable
    public init(from decoder: Decoder) throws {
        guard let anyctx = Self.context() else {
            throw DecodingError.valueNotFound(
                Wrapped.DecodingContext.self,
                DecodingError.Context(codingPath: decoder.codingPath,
                                      debugDescription: "Context is empty")
            )
        }
        guard let context = anyctx as? Wrapped.DecodingContext else {
            let error = "Context has different type \(type(of: anyctx))"
            throw DecodingError.typeMismatch(
                Wrapped.DecodingContext.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: error
                )
            )
        }
        value = try Wrapped(from: decoder, context: context)
    }
    
    public static func set(context: Wrapped.DecodingContext) {
        DecodableThreadLocalKey.set(value: context)
    }
    
    // One time call. Will remove configuration from ThreadLocal
    // Any because body is unknown (try cast it)
    public static func context() -> Any? {
        DecodableThreadLocalKey.replace(with: nil)
    }
    
    public static var threadLocalKey: ThreadLocal<Any> { DecodableThreadLocalKey }
}

public extension JSONDecoder {
    @inlinable
    func decode<T: ContextDecodable>(
        _: T.Type, from data: Data, context: T.DecodingContext
    ) throws -> T {
        DecodableWrapper<T>.set(context: context)
        return try decode(DecodableWrapper<T>.self, from: data).value
    }
}

public extension UnkeyedDecodingContainer {
    @inlinable
    mutating func decode<T: ContextDecodable>(
        _: T.Type, context: T.DecodingContext
    ) throws -> T {
        DecodableWrapper<T>.set(context: context)
        return try decode(DecodableWrapper<T>.self).value
    }
}

public extension KeyedDecodingContainer {
    @inlinable
    func decode<T: ContextDecodable>(
        _: T.Type, forKey key: Key, context: T.DecodingContext
    ) throws -> T {
        DecodableWrapper<T>.set(context: context)
        return try decode(DecodableWrapper<T>.self, forKey: key).value
    }
    
    @inlinable
    func decodeIfPresent<T: ContextDecodable>(
        _: T.Type, forKey key: Key, context: T.DecodingContext
    ) throws -> T? {
        DecodableWrapper<T>.set(context: context)
        return try decodeIfPresent(DecodableWrapper<T>.self, forKey: key)?.value
    }
}

private let DecodableThreadLocalKey = ThreadLocal<Any>()
