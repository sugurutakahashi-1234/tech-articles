---
title: "[Swift] nil の意味を明確にする方法"
tags:
  - "Swift"
private: false
updated_at: ''
id: 0d6697cc4716d9dbde9b
organization_url_name: null
slide: false
ignorePublish: false
---


# モチベーション

`nil` を乱暴に多用していると `nil` が表す意味が複数に膨れ上がってしまうため、何のために `nil` にしているかを変数から察することができないかと考えました。

# `nil` の意味を明確にする方法

以下のように `Optional` を拡張すると、変数名から `nil` の意味を明確にすることができます。

```swift
extension Optional {
    static var nilForDefault: Wrapped? {
        nil
    }

    static var nilForError: Wrapped? {
        nil
    }
}

// 使い方
var num: Int? = .nilForDefault
var str: String? = .nilForError
```

# 使い方（応用）

`where Wrapped == 型名` で型を絞り込んで、`nil` を定義することもできます。

```swift
extension Optional where Wrapped == Int {
    static var nilForXXXXX: Wrapped? {
        nil
    }
}

var num: Int? = .nilForDefault // nil
var str: String? = .nilForXXXXX // Type 'String' has no member 'nilForXXXXX'
```

# そもそも

`nilForError` などを使うことは間違っていて、Error を throw するように実装していない証拠かもしれません。

以上です。

## 補足（ダメな例）

### ダメな例 その1

以下ではうまくいきません。

```swift
enum Nil {
    static let forDefault: Optional<Any> = nil
}

var num: Int? = Nil.forDefault as! Int // expression failed to parse: error: op.playground:3:5: error: consecutive statements on a line must be separated by ';'
```

そもそも `Nil.forDefault` は `Optional<Any>` 型であり、`Optional<Int>` ではないので、`as!` or `as?` で型を判定しなければならなく、うまくいきません。

### ダメな例 その2

`Optional<Any>` でダメなら、型を指定すればよいという考え方です。

```swift
struct Nil {
    static let forDefault: Optional<Int> = nil
}

var num: Int? = Nil.forDefault // OK
var str: String? = Nil.forDefault // NG: Cannot convert value of type 'Optional<Int>' to specified type 'String?'
```

`as!` or `as?` でキャストする必要はなくなりましたが、すべての型において、いちいち定義しなければならないので、使い勝手が悪いです。

### ダメな例 その3

`static` で生やさない場合の例になります。

```swift
extension Optional {
    var nilForDefault: Wrapped? {
        nil
    }
}

var num: Int? = .nilForDefault // ← これはできない

// これならできるが、やりたいことではない
num = 0
num.nilForDefault // nil
```

一度インスタンスを生成しないと、使えません。
用途が異なります。

以上、補足でした。
