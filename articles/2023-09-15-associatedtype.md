---
title: "[Swift] associatedtype の実装例"
emoji: "🕊"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["Swift"]
published: true
---

# associatedtype の実装例

まず、以下のような2つのプロトコル `MogeProtocol` と `FugaProtocol` を定義します。

```swift:protocol
protocol MogeProtocol {
    var mogemoge: String { get }
}

protocol FugaProtocol {
    var fugafuga: String { get }
}
```

次に、これらの2つのプロトコルを組み合わせて使用する新しいプロトコル `HogeProtocol` を定義します。この時、`associatedtype` を使用して、具体的な型を後から指定できるようにします。

```swift
protocol HogeProtocol {
    associatedtype MogeFugaType: MogeProtocol, FugaProtocol
    
    var mogeFuga: MogeFugaType { get }
    
    func piyopiyo(mogeFuga: MogeFugaType)
}
```

`Hoge` という構造体を定義し、`HogeProtocol` を採用させることで、具体的な型を指定します。

```swift:struct
// 複数のプロトコルを適応させる場合は & でつなぐ
struct Hoge<T: MogeProtocol & FugaProtocol>: HogeProtocol {
    typealias MogeFugaType = T
    
    let mogeFuga: MogeFugaType
    
    init(mogeFuga: MogeFugaType) {
        self.mogeFuga = mogeFuga
        print(mogeFuga)
    }
    
    func piyopiyo(mogeFuga: MogeFugaType) {
        print(mogeFuga)
    }
}
```

最後に、`MogeProtocol` と `FugaProtocol` を採用する構造体 `MogeFuga` を定義し、実際に`Hoge` で使用します。

```swift:
struct MogeFuga: MogeProtocol, FugaProtocol {
    let mogemoge: String
    let fugafuga: String
}

let hoge: Hoge<MogeFuga> = .init(mogeFuga: .init(mogemoge: "a", fugafuga: "b"))
// MogeFuga(mogemoge: "a", fugafuga: "b")

hoge.piyopiyo(mogeFuga: .init(mogemoge: "c", fugafuga: "d"))
// MogeFuga(mogemoge: "c", fugafuga: "d")
```

# まとめ

Swift の `associatedtype` は非常に強力な機能で、プロトコルの柔軟性を向上させます。具体的な型を指定せずにプロトコルを定義し、後からその型を具体的に指定することが可能です。これにより、より汎用的なコードを書くことができます。