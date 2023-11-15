---
title: '[Swift] JSONSerialization を使って辞書型に変換すると数値や Bool 値の型が勝手に変更されてしまう件'
tags:
  - Swift
private: false
updated_at: '2023-11-15T20:50:31+09:00'
id: ba2af8d7eb5363360404
organization_url_name: null
slide: false
ignorePublish: false
---

環境: Xcode 14.2

# JSONSerialization による型の変化について

Swift における `JSONSerialization` の挙動は、特定のシナリオで変数の型を変更することがあります。具体的には、`Double` や` Float` の小数部が `.0` の場合、それは整数としてシリアライズされます。また、Boolは `1`（`true`）または `0`（`false`）としてシリアライズされることがあります。

## なぜこのような挙動が発生するのか

JSON は、Swift とは異なり、静的型付けを持たないデータ形式です。このため、`JSONSerialization` はデータを最もシンプルな形式に変換しようとします。例えば、`2.0` は `2` として、`true` は `1` として表現されます。

## 解決策

`JSONSerialization` の代わりに、直接辞書への変換を行う方法を採用することで、型の変更問題を回避できます。この記事では、`Mirror` を使った方法を紹介しています。

## Struct → Dictionary の変換の記述

```swift
extension Encodable {
    func asDictionary(keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy) throws -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = keyEncodingStrategy

        do {
            let data = try encoder.encode(self)
            guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                throw EncodingError.invalidValue(self, EncodingError.Context(codingPath: [], debugDescription: "Couldn't convert to [String: Any] dictionary"))
            }
            return jsonObject
        } catch {
            throw error
        }
    }
}
```

## Dictionary -> Struct の変換の記述

```swift
extension Decodable {
    init(from dictionary: [String: Any], keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy) throws {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = keyDecodingStrategy

        let data = try JSONSerialization.data(withJSONObject: dictionary, options: [])
        let decodedObject = try decoder.decode(Self.self, from: data)
        self = decodedObject
    }
}
```

## サンプルの定義

```swift
struct Sample: Codable {
    let sampleInt: Int
    let sampleString: String
    let sampleDouble: Double
    let sampleFloat: Float
    let sampleBool: Bool
    let sampleDate: Date
    let sampleStruct: SampleStruct
    let sampleEnum: SampleEnum
}

struct SampleStruct: Codable {
    let hogeProperty: Int
}

enum SampleEnum: Codable {
    case hogeCase
}
```

## Struct -> Dictionary の変換

```swift
let sample = Sample(sampleInt: 1, sampleString: "a", sampleDouble: 2.0, sampleFloat: 3.0, sampleBool: true, sampleDate: Date(), sampleStruct: SampleStruct(hogeProperty: 4), sampleEnum: .hogeCase)

do {
    let dict1 = try sample.asDictionary(keyEncodingStrategy: .useDefaultKeys)
    let dict2 = try sample.asDictionary(keyEncodingStrategy: .convertToSnakeCase)
    print(dict1)
    print(dict2)
} catch {
    print("\(error)")
}
```

## .useDefaultKeys で変換した Dictionary の出力

```swift:dict1
[
    "sampleInt": 1,
    "sampleString": "a",
    "sampleDouble": 2, // Double(2.0) が勝手に Int(2) に丸め込まれる
    "sampleFloat": 3, // Double(3.0) が勝手に Int(3) に丸め込まれる
    "sampleBool": 1, // Bool(true) が勝手に Int(1) に丸め込まれる
    "sampleDate": 713534174.328627,
    "sampleStruct": [
        "hogeProperty": 4
    ],
    "sampleEnum": [
        "hogeCase": {}
    ]
]
```

## .convertToSnakeCase で変換した Dictionary の出力

```swift:dict2
[
    "sample_int": 1,
    "sample_string": "a",
    "sample_double": 2, // Double(2.0) が勝手に Int(2) に丸め込まれる
    "sample_float": 3, // Double(3.0) が勝手に Int(3) に丸め込まれる
    "sample_bool": 1, // Bool(true) が勝手に Int(1) に丸め込まれる
    "sample_date": 713534174.328627,
    "sample_struct": [
        "hoge_property": 4
    ],
    "sample_enum": [
        "hoge_case": {}
    ]
]
```

## Dictionary -> Struct の変換

```swift
let sample = Sample(sampleInt: 1, sampleString: "a", sampleDouble: 2.0, sampleFloat: 3.0, sampleBool: true, sampleDate: Date(), sampleStruct: SampleStruct(hogeProperty: 4), sampleEnum: .hogeCase)

do {
    let dict1 = try sample.asDictionary(keyEncodingStrategy: .useDefaultKeys)
    let dict2 = try sample.asDictionary(keyEncodingStrategy: .convertToSnakeCase)

    // 以下はどちらも同じ出力になる（ Encodable & Decodable の Struct -> Dictionary -> Struct の変換がうまくいっている）
    print(try Sample(from: dict1, keyDecodingStrategy: .useDefaultKeys))
    print(try Sample(from: dict2, keyDecodingStrategy: .convertFromSnakeCase))
} catch {
    print("\(error)")
}
```

## Dictionary -> Struct の変換（エラーの検証）

```swift
let sample = Sample(sampleInt: 1, sampleString: "a", sampleDouble: 2.0, sampleFloat: 3.0, sampleBool: true, sampleDate: Date(), sampleStruct: SampleStruct(hogeProperty: 4), sampleEnum: .hogeCase)

do {
    let dict1 = try sample.asDictionary(keyEncodingStrategy: .useDefaultKeys)
    let dict2 = try sample.asDictionary(keyEncodingStrategy: .convertToSnakeCase)

    // わざと、asDictionary で指定した KeyDecodingStrategy と異なる値を指定してみる
    print(try Sample(from: dict1, keyDecodingStrategy: .convertFromSnakeCase)) // ← なぜかエラーにならない
    print(try Sample(from: dict2, keyDecodingStrategy: .useDefaultKeys)) // ← エラーになる
} catch {
    print("\(error)")
}
```

## Codable や JSONSerialization を使わないで Dictionary にする方法

`Mirror` を使うことで型をなるべく残した状態で辞書型に変換できます。

```swift
public enum CaseFormat {
    case original
    case snakeCase
}

public protocol ConvertibleToDictionary {
    func asDictionary(caseFormat: CaseFormat) -> [String: Any]
}

public extension ConvertibleToDictionary {
    func asDictionary(caseFormat: CaseFormat = .original) -> [String: Any] {
        let mirror = Mirror(reflecting: self)
        var dictionary: [String: Any] = [:]

        mirror.children.forEach { child in
            guard let keyName = child.label else { return }

            switch caseFormat {
            case .original:
                dictionary[keyName] = child.value
            case .snakeCase:
                dictionary[keyName.toSnakeCase] = child.value
            }
        }

        return dictionary
    }
}

extension String {
    var toSnakeCase: String {
        let snakeCased = unicodeScalars.reduce("") { result, scalar in
            if CharacterSet.uppercaseLetters.contains(scalar) {
                return "\(result)_\(Character(scalar))"
            } else {
                return result + String(scalar)
            }
        }.lowercased()

        if snakeCased.hasPrefix("_") {
            return String(snakeCased.dropFirst())
        } else {
            return snakeCased
        }
    }
}

let sample = Sample(sampleInt: 1, sampleString: "a", sampleDouble: 2.0, sampleFloat: 3.0, sampleBool: true, sampleDate: Date(), sampleStruct: SampleStruct(hogeProperty: 4), sampleEnum: .hogeCase)

let dict1 = sample.asDictionary(caseFormat: .original)
let dict2 = sample.asDictionary(caseFormat: .snakeCase)

print(dict1)
print(dict2)
```

## .original で変換した Dictionary

```swift:dict1
[
    "sampleInt": 1,
    "sampleString": "a",
    "sampleDouble": 2.0,
    "sampleFloat": 3.0,
    "sampleBool": true,
    "sampleDate": "2023-08-12 12:48:45 +0000",
    "sampleStruct": "SampleStruct(hogeProperty: 4)",
    "sampleEnum": "SampleEnum.hogeCase"
]
```

## .snakeCase で変換した Dictionary

```swift:dict2
[
    "sample_int": 1,
    "sample_string": "a",
    "sample_double": 2.0,
    "sample_float": 3.0,
    "sample_bool": true,
    "sample_date": "2023-08-12 12:48:45 +0000",
    "sample_struct": "SampleStruct(hogeProperty: 4)",
    "sample_enum": "SampleEnum.hogeCase"
]
```

## そもそもなぜこのようなことをやりたいのか？

Protocol Buffers の [`google.protobuf.Value`](https://github.com/protocolbuffers/protobuf/blob/main/src/google/protobuf/struct.proto#L62) で扱える型 は `NullValue`, `double`, `string`, `bool`, `Struct`, `ListValue` のみで、`map<string, google.protobuf.Value>` に Swift の Struct を辞書型に変換するときに使うことが目的でした。

そして、以下のような処理を書く際に `JSONSerialization` を使うと型情報が失われてしまい、思ったような変換をしてくれなかったので、`Mirror` で書くことになりました。

```swift
import Foundation
import SwiftProtobuf

var toProtoBufValueDictionary: [String: Google_Protobuf_Value] {
    asDictionary(caseFormat: .snakeCase).mapValues { value in
        var protoValue = Google_Protobuf_Value()
        switch value {
        case let intValue as Int:
            protoValue.numberValue = Double(intValue)
        case let doubleValue as Double:
            protoValue.numberValue = doubleValue
        case let floatValue as Float:
            protoValue.numberValue = Double(floatValue)
        case let stringValue as String:
            protoValue.stringValue = stringValue
        case let dateValue as Date:
            protoValue.stringValue = ISO8601DateFormatter.sharedWithFractionalSeconds.string(from: dateValue)
        case let boolValue as Bool:
            protoValue.boolValue = boolValue
        default:
            assertionFailure("Unexpected type encountered while converting to Google_Protobuf_Value")
        }
        return protoValue
    }
}

extension ISO8601DateFormatter {
    static let sharedWithFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone.current
        return formatter
    }()
}
```

# まとめ

`JSONSerialization` は型の変更を引き起こす可能性があるため、直接辞書変換を行うアプローチも検討したほうがいいかもしれません。
