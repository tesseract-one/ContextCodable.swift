# ContextCodable.swift

![🐧 linux: ready](https://img.shields.io/badge/%F0%9F%90%A7%20linux-ready-red.svg)
[![GitHub license](https://img.shields.io/badge/license-Apache%202.0-lightgrey.svg)](https://raw.githubusercontent.com/tesseract-one/ContextCodable.swift/main/LICENSE)
[![Build Status](https://github.com/tesseract-one/ContextCodable.swift/workflows/Build%20%26%20Tests/badge.svg?branch=main)](https://github.com/tesseract-one/ContextCodable.swift/actions?query=workflow%3ABuild%20%26%20Tests+branch%3Amain)
[![GitHub release](https://img.shields.io/github/release/tesseract-one/ContextCodable.swift.svg)](https://github.com/tesseract-one/ContextCodable.swift/releases)
[![SPM compatible](https://img.shields.io/badge/SwiftPM-Compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![CocoaPods version](https://img.shields.io/cocoapods/v/ContextCodable.swift.svg)](https://cocoapods.org/pods/ContextCodable.swift)
![Platform OS X | iOS | tvOS | watchOS | Linux](https://img.shields.io/badge/platform-Linux%20%7C%20OS%20X%20%7C%20iOS%20%7C%20tvOS%20%7C%20watchOS-orange.svg)

### Backport of CodableWithConfiguration to old OS versions and Linux

## Why?

Apple added type of `Codable` - `CodableWithConfiguration` which allows to provide context for encoding and decoding.

But this protocols are available only from macOS 12, and `JSONEncoder` and `JSONDecoder` support added only in macOS 15. Linux does not support them at all.

So we created this library, which enables this API on old Swift and platforms. It has some speed drawbacks, but it works!

## Getting started

### Installation

#### [Package Manager](https://swift.org/package-manager/)

Add the following dependency to your [Package.swift](https://github.com/apple/swift-package-manager/blob/master/Documentation/Usage.md#define-dependencies):

```swift
.package(url: "https://github.com/tesseract-one/ContextCodable.swift.git", from: "0.1.0")
```

Run `swift build` and build your app.

#### [CocoaPods](http://cocoapods.org/)

Add the following to your [Podfile](http://guides.cocoapods.org/using/the-podfile.html):

```rb
pod 'ContextCodable.swift', '~> 0.1.0'
```

Then run `pod install`

### Examples

#### Encoding
```swift
import Foundation
import ContextCodable

struct SomeEncodable: ContextEncodable {
  typealias EncodingContext = (top: String, internal: Date)

  let internal: Internal

  struct Internal: ContextEncodable {
    typealias EncodingContext = Date

    let value: Bool

    func encode(to encoder: Encoder, context: EncodingContext) throws {
      var container = encoder.unkeyedContainer()
      try container.encode(value)
      try container.encode(context)
    }
  }

  enum CodingKeys: CodingKey {
    case `internal`
    case context
  }

  func encode(to encoder: Encoder, context: EncodingContext) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(self.internal, forKey: .internal, context: context.internal)
    try container.encode(context.top, forKey: .context)
  }
}

let value = SomeEncodable(internal: SomeEncodable.Internal(value: true))
let encoded = try JSONEncoder().encode(value, context: (top: "Test", internal: Date()))
print(String(data: encoded, encoding: .utf8)!)
```

#### Decoding
```swift
import Foundation
import ContextCodable

struct SomeDecodable: ContextDecodable {
  typealias DecodingContext = (top: String, internal: Date)

  let internal: Internal
  let top: String

  struct Internal: ContextDecodable {
    typealias DecodingContext = Date

    let value: Bool
    let date: Date

    init(from decoder: Decoder, context: DecodingContext) throws {
      var container = try decoder.unkeyedContainer()
      value = try container.decode(Bool.self)
      date = context
    }
  }

  enum CodingKeys: CodingKey {
    case `internal`
    case context
  }

  init(from decoder: Decoder, context: DecodingContext) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.internal = try decoder.decode(Internal.self, forKey: .internal, context: context.internal)
    self.top = context.top
  }
}

let json = Data("{\"internal\": [true]}".utf8)
let decoded = try JSONDecoder().decode(SomeDecodable.self, from: json, context: (top: "Test", internal: Date()))
print(decoded)
```

## Author

 - [Tesseract Systems, Inc.](mailto:info@tesseract.one)
   ([@tesseract_one](https://twitter.com/tesseract_one))

## License

ContextCodable.swift is available under the Apache 2.0 license. See [the LICENSE file](./LICENSE) for more information.
