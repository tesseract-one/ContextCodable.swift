//
//  EncodableTests.swift
//  
//
//  Created by Yehor Popovych on 06/07/2023.
//

import Foundation
import XCTest
@testable import ContextCodable

final class EncodableTests: XCTestCase {
    func testSimple() throws {
        let expected = randomObject()
        let encodable = expected.enc
        let encoded = try JSONEncoder().encode(encodable,
                                               context: expected.context)
        let decoded = try JSONDecoder().decode(DecObj.self, from: encoded)
        XCTAssertEqual(decoded, expected)
    }
    
    func testMultiThreaded() throws {
        let tasks = (0..<1000).map { index in
            let expectation = self.expectation(description: "call: \(index)")
            let expected = self.randomObject()
            return (expected, expectation)
        }

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for (expected, expect) in tasks {
            DispatchQueue.global().async {
                defer { expect.fulfill() }
                do {
                    let encoded = try encoder.encode(expected.enc,
                                                     context: expected.context)
                    let decoded = try decoder.decode(DecObj.self, from: encoded)
                    XCTAssertEqual(decoded, expected)
                } catch {
                    XCTFail("error: \(error)")
                }
            }
        }

        wait(for: tasks.map { $0.1 }, timeout: 5)
    }
    
    private func randomObject() -> DecObj {
        DecObj(
            int: .init(
                int: .random(in: 0..<99999),
                string: UUID().uuidString
            ),
            array: .init(
                array: Array(Int.random(in: 1..<5)..<Int.random(in: 6..<15)),
                date: Date(timeIntervalSince1970: .random(in: 0..<999999))
            ),
            null: .init(double: .random(in: 0..<99999)),
            simpleInt: .random(in: 0..<99999),
            string: UUID().uuidString
        )
    }
}

private struct EncObj: ContextEncodable {
    typealias EncodingContext = (date: Date, int: Int, string: String, double: Double)
    
    let int: EncIntAndStr
    let array: EncArrayAndDate
    let null: EncNullAndDouble
    let string: String
    
    enum CodingKeys: CodingKey {
        case int
        case array
        case null
        case simpleInt
        case string
    }
    
    init(int: EncIntAndStr, array: EncArrayAndDate,
         null: EncNullAndDouble, string: String) {
        self.int = int
        self.array = array
        self.null = null
        self.string = string
    }
    
    func encode(to encoder: Encoder, context: EncodingContext) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(int, forKey: .int,
                             context: context.string)
        try container.encode(array, forKey: .array,
                             context: context.date)
        try container.encode(null, forKey: .null,
                             context: context.double)
        try container.encode(context.int, forKey: .simpleInt)
        try container.encode(string, forKey: .string)
    }
}

private struct EncIntAndStr: ContextEncodable {
    typealias EncodingContext = String
    
    let int: Int
    
    enum CodingKeys: CodingKey {
        case int
        case string
    }
    
    init(int: Int) {
        self.int = int
    }
    
    func encode(to encoder: Encoder, context: EncodingContext) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(int, forKey: .int)
        try container.encode(context, forKey: .string)
    }
}

private struct EncArrayAndDate: ContextEncodable {
    typealias EncodingContext = Date
    
    let array: Array<Int>
    
    init(array: Array<Int>) {
        self.array = array
    }
    
    enum CodingKeys: CodingKey {
        case array
        case date
    }
    
    func encode(to encoder: Encoder, context: EncodingContext) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(array, forKey: .array)
        try container.encode(context, forKey: .date)
    }
}

private struct EncNullAndDouble: ContextEncodable {
    typealias EncodingContext = Double
        
    func encode(to encoder: Encoder, context: EncodingContext) throws {
        var container = encoder.unkeyedContainer()
        try container.encodeNil()
        try container.encode(context)
    }
}

private struct DecObj: Equatable, Decodable {
    let int: DecIntAndStr
    let array: DecArrayAndDate
    let null: DecNullAndDouble
    let simpleInt: Int
    let string: String
    
    init(int: DecIntAndStr, array: DecArrayAndDate,
         null: DecNullAndDouble, simpleInt: Int, string: String)
    {
        self.int = int
        self.array = array
        self.null = null
        self.simpleInt = simpleInt
        self.string = string
    }
    
    var enc: EncObj { EncObj(int: int.enc, array: array.enc,
                             null: null.enc, string: string) }
    
    var context: EncObj.EncodingContext {
        (date: array.context, int: simpleInt,
         string: int.context, double: null.context)
    }
}

private struct DecIntAndStr: Equatable, Decodable {
    let int: Int
    let string: String
    
    init(int: Int, string: String) {
        self.int = int
        self.string = string
    }
    
    var enc: EncIntAndStr { EncIntAndStr(int: int) }
    var context: EncIntAndStr.EncodingContext { string }
}

private struct DecArrayAndDate: Equatable, Decodable {
    let array: Array<Int>
    let date: Date
    
    init(array: Array<Int>, date: Date) {
        self.array = array
        self.date = date
    }
    
    var enc: EncArrayAndDate { EncArrayAndDate(array: array) }
    var context: EncArrayAndDate.EncodingContext { date }
}

private struct DecNullAndDouble: Equatable, Decodable {
    let double: Double
    
    init(double: Double) {
        self.double = double
    }
    
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let nl = try container.decodeNil()
        assert(nl)
        double = try container.decode(Double.self)
    }
    
    var enc: EncNullAndDouble { EncNullAndDouble() }
    var context: EncNullAndDouble.EncodingContext { double }
}
