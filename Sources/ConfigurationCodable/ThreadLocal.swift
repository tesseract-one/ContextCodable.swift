//
//  ThreadLocal.swift
//  
//
//  Created by Yehor Popovych on 07/07/2023.
//

import Foundation
#if canImport(Glibc)
import Glibc
#endif

public final class Box<V> {
    public let value: V
    
    public init(_ value: V) {
        self.value = value
    }
    
    public func retained() -> UnsafeMutableRawPointer {
        Unmanaged.passRetained(self).toOpaque()
    }
    
    public func unretained() -> UnsafeMutableRawPointer {
        Unmanaged.passUnretained(self).toOpaque()
    }
    
    public static func retained(ptr: UnsafeRawPointer) -> Self {
        Unmanaged<Self>.fromOpaque(ptr).takeRetainedValue()
    }
    
    public static func unretained(ptr: UnsafeRawPointer) -> Self {
        Unmanaged<Self>.fromOpaque(ptr).takeUnretainedValue()
    }
}

public final class ThreadLocal<V> {
    var key: pthread_key_t
    
    public init() {
        key = pthread_key_t()
        let result = pthread_key_create(&key) { ptr in
            guard let ptr = (ptr as UnsafeMutableRawPointer?) else {
                return
            }
            let _ = Box<Any>.retained(ptr: ptr)
        }
        precondition(result == 0, "pthread_key_create failed")
    }
    
    public func get() -> V? {
        pthread_getspecific(key).map { Box<V>.unretained(ptr: $0).value }
    }
    
    public func replace(with value: V?) -> V? {
        let ptr = pthread_getspecific(key)
        let result = pthread_setspecific(key, value.map { Box($0).retained() })
        precondition(result == 0, "pthread_setspecific failed")
        return ptr.map { Box<V>.retained(ptr: $0).value }
    }
    
    @inlinable public func set(value: V?) { let _ = replace(with: value) }
    
    @inlinable public func remove() { let _ = replace(with: nil) }
    
    deinit {
        let result = pthread_key_delete(key)
        precondition(result == 0, "pthread_key_delete failed")
    }
}
