//
//  DecodableTests.swift
//  
//
//  Created by Yehor Popovych on 06/07/2023.
//

import Foundation
import XCTest
@testable import ContextCodable

final class DecodableTests: XCTestCase {
    func testSimple() throws {
        let expected = self.randomObject()
        let encoded = try JSONEncoder().encode(expected)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Obj.self,
                                         from: encoded,
                                         context: expected.context)
        XCTAssertEqual(decoded, expected)
    }
    
    func testMultiThreaded() throws {
        let encoder = JSONEncoder()
        
        let tasks = try (0..<1000).map { index in
            let expectation = self.expectation(description: "call: \(index)")
            
            let expected = self.randomObject()
            
            let data = try encoder.encode(expected)
            
            return (expected, data, expectation)
        }
        
        let decoder = JSONDecoder()
        
        for (expected, data, expect) in tasks {
            DispatchQueue.global().async {
                defer { expect.fulfill() }
                do {
                    let decoded = try decoder.decode(Obj.self,
                                                     from: data,
                                                     context: expected.context)
                    XCTAssertEqual(decoded, expected)
                } catch {
                    XCTFail("error: \(error)")
                }
            }
        }
        
        wait(for: tasks.map { $0.2 }, timeout: 5)
    }
    
    private func randomObject() -> Obj {
        Obj(
            intStr: .init(
                int: .random(in: 0..<999999),
                string: UUID().uuidString
            ),
            array: .init(
                array: Array(Int.random(in: 1..<5)..<Int.random(in: 6..<15)),
                date: Date(timeIntervalSince1970: .random(in: 0..<999999))
            ),
            null: .init(double: .random(in: 0..<9999999)),
            int: .random(in: 0..<99999999),
            string: UUID().uuidString
        )
    }
}

private struct Obj:
    Equatable, Encodable, ContextDecodable
{
    typealias DecodingContext = (date: Date, int: Int, string: String, double: Double)
    
    let intAndStr: IntAndStr
    let arrayAndDate: ArrayAndDate
    let nullAndDouble: NullAndDouble
    let int: Int
    let string: String
    
    enum CodingKeys: CodingKey {
        case int
        case array
        case null
        case string
    }
    
    init(intStr: IntAndStr, array: ArrayAndDate,
         null: NullAndDouble, int: Int, string: String)
    {
        intAndStr = intStr
        arrayAndDate = array
        nullAndDouble = null
        self.int = int
        self.string = string
    }
    
    init(from decoder: Decoder, context: DecodingContext) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        intAndStr = try container.decode(IntAndStr.self,
                                         forKey: .int,
                                         context: context.string)
        arrayAndDate = try container.decode(ArrayAndDate.self,
                                            forKey: .array,
                                            context: context.date)
        nullAndDouble = try container.decode(NullAndDouble.self,
                                             forKey: .null,
                                             context: context.double)
        int = context.int
        string = try container.decode(String.self, forKey: .string)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(intAndStr, forKey: .int)
        try container.encode(arrayAndDate, forKey: .array)
        try container.encode(nullAndDouble, forKey: .null)
        try container.encode(string, forKey: .string)
    }
    
    var context: DecodingContext {
        (date: arrayAndDate.date, int: int,
         string: intAndStr.string, double: nullAndDouble.double)
    }
}

private struct IntAndStr:
    Equatable, Encodable, ContextDecodable
{
    typealias DecodingContext = String
    
    let int: Int
    let string: String
    
    init(int: Int, string: String) {
        self.int = int
        self.string = string
    }
    
    init(from decoder: Decoder, context: DecodingContext) throws {
        int = try Int(from: decoder)
        string = context
    }
    
    func encode(to encoder: Encoder) throws {
        try int.encode(to: encoder)
    }
}

private struct ArrayAndDate:
    Equatable, Encodable, ContextDecodable
{
    typealias DecodingContext = Date
    
    let array: Array<Int>
    let date: Date
    
    init(array: Array<Int>, date: Date) {
        self.array = array
        self.date = date
    }
    
    init(from decoder: Decoder, context: DecodingContext) throws {
        array = try Array<Int>(from: decoder)
        date = context
    }
    
    func encode(to encoder: Encoder) throws {
        try array.encode(to: encoder)
    }
}

private struct NullAndDouble:
    Equatable, Encodable, ContextDecodable
{
    typealias DecodingContext = Double
    
    let double: Double
    
    init(double: Double) {
        self.double = double
    }
    
    init(from decoder: Decoder, context: DecodingContext) throws {
        let nl = try decoder.singleValueContainer().decodeNil()
        assert(nl)
        double = context
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}
