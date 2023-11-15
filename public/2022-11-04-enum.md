---
title: '[Swift] 連想値を持つ enum に Equatable を適応させた場合の挙動'
tags:
  - Swift
private: false
updated_at: '2023-11-15T20:50:31+09:00'
id: 71969cd8252a47dc132d
organization_url_name: null
slide: false
ignorePublish: false
---

# 伝えたいこと

- 連想値(Associated value)を持つ enum でも `Equatable` に準拠させるだけで `==` 演算子で比較が可能
- 連想値がそもそも `Equatable` に準拠していない場合は、連想値の方を `Equatable` に準拠させるとシンプルに記述できる
- 通常と異なる `==` 演算子を使用するのは控えて、その代わりに関数を用意するのが親切

# サンプルコード

連想値(Associated value)を持つ enum でも `Equatable` に準拠させるだけで、`==` 演算子での比較が可能みたいです。

つまるところ、`func ==(lhs: Self, rhs: Self) -> Bool` の定義は不要のようです。

```swift
enum Hoge: Equatable {
    case moge
    case piyo(Int)
}

let hoge1: Hoge = .moge
let hoge2: Hoge = .piyo(2)
let hoge3: Hoge = .piyo(3)
let hoge4: Hoge = .piyo(2)

print(hoge1 == hoge2) // false
print(hoge2 == hoge3) // false
print(hoge2 == hoge4) // true
```

# （番外編その1）連想値が Equatable に適応準拠していない場合

連想値が Equatable に適応準拠していない場合は、enum に `Equatable` に準拠させるだけでは、`==` 演算子が使用できません。

そのため、以下のように、`func ==(lhs: Self, rhs: Self) -> Bool` の定義が必要になります。

```swift
struct Fuga {
    var fugafuga: Int
}

enum Hoge {
    case moge
    case piyo(Fuga)
}

extension Hoge: Equatable {
    static func == (lhs: Hoge, rhs: Hoge) -> Bool {
        switch (lhs, rhs) {
        case (.moge, .moge):
            return true
        case (.moge, .piyo(_)):
            return false
        case (.piyo(_), .moge):
            return false
        case (.piyo(let lhsFuga), .piyo(let rhsFuga)):
            return lhsFuga.fugafuga == rhsFuga.fugafuga
        }
    }
}

let hoge1: Hoge = .moge
let hoge2: Hoge = .piyo(.init(fugafuga: 2))
let hoge3: Hoge = .piyo(.init(fugafuga: 3))
let hoge4: Hoge = .piyo(.init(fugafuga: 2))

print(hoge1 == hoge2) // false
print(hoge2 == hoge3) // false
print(hoge2 == hoge4) // true
```

いやだったら、`Fuga` に `Equatable` を準拠させれば良いのでは？となりますが、その通りだと思います。

以下、サンプルコードになります。

```swift
struct Fuga: Equatable {
    var fugafuga: Int
}

enum Hoge: Equatable {
    case moge
    case piyo(Fuga)
}

let hoge1: Hoge = .moge
let hoge2: Hoge = .piyo(.init(fugafuga: 2))
let hoge3: Hoge = .piyo(.init(fugafuga: 3))
let hoge4: Hoge = .piyo(.init(fugafuga: 2))

print(hoge1 == hoge2) // false
print(hoge2 == hoge3) // false
print(hoge2 == hoge4) // true
```

はるかにシンプルですね。

上記で問題ないケースであれば、連想値がそもそも `Equatable` に準拠していない場合は、連想値の方を `Equatable` に準拠させるとシンプルに記述できそうです。

# （番外編その2）連想値を無視して列挙した enum があってれば true を返してほしいとき

連想値を無視して列挙した enum があってれば true を返してほしいときもあると思います。

そういうときは以下のように自分で定義しましょう。

```swift
enum Hoge {
    case moge
    case piyo(Int)
}

extension Hoge: Equatable {
    static func == (lhs: Hoge, rhs: Hoge) -> Bool {
        switch (lhs, rhs) {
        case (.moge, .moge):
            return true
        case (.moge, .piyo(_)):
            return false
        case (.piyo(_), .moge):
            return false
        case (.piyo(_), .piyo(_)):
            return true
        }
    }
}

let hoge1: Hoge = .moge
let hoge2: Hoge = .piyo(2)
let hoge3: Hoge = .piyo(3)
let hoge4: Hoge = .piyo(2)

print(hoge1 == hoge2) // false
print(hoge2 == hoge3) // true
print(hoge2 == hoge4) // true
```

上記の書き方だと正直、普通の `==` 演算子と挙動が異なって、混乱してしまう恐れがあります。

個人的には、そのような判定をしたい場合は `==` をオーバーライドするのではなく、以下のように関数を用意してあげた方が、優しいコードな気がします。

```swift
enum Hoge: Equatable {
    case moge
    case piyo(Int)
}

extension Hoge {
    func lazyEqual(_ rhs:Hoge) -> Bool {
        switch (self, rhs) {
        case (.moge, .moge):
            return true
        case (.moge, .piyo(_)):
            return false
        case (.piyo(_), .moge):
            return false
        case (.piyo(_), .piyo(_)):
            return true
        }
    }
}

let hoge1: Hoge = .moge
let hoge2: Hoge = .piyo(2)
let hoge3: Hoge = .piyo(3)
let hoge4: Hoge = .piyo(2)

print(hoge1 == hoge2) // false
print(hoge2 == hoge3) // false
print(hoge2 == hoge4) // true

print(hoge1.lazyEqual(hoge2)) // false
print(hoge2.lazyEqual(hoge3)) // true
print(hoge2.lazyEqual(hoge4)) // true
```

以上になります。
