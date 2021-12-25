---
title: "【Swift】throws 関数の中で throws 関数を呼び出したときの挙動【エラー処理】"
emoji: "🔖"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["Swift"]
published: true
---
# 概要

タイトルのとおりです。

サンプルを見ればわかると思います。

いろいろ探したのですが、このケースについて解説している記事がなかったので、Playground で実際にコーディングして挙動をまとめてみました。

環境は Xcode 12.5.1 になります。

## 基本編

### サンプル

```swift
import Foundation

enum TestError: Error {
    case largeError
    case smallError
    case sixError
}

func methodA(num: Int) throws -> Int {
    if num > 8 {
        throw TestError.largeError
    }
    return num
}

func methodB(num: Int) throws -> Int {
    if num < 4 {
        throw TestError.smallError
    }
    return num
}


func methodC(num: Int) throws -> Int {
    let _ = try methodA(num: num) // throws 関数のなかで throws 関数を呼び出す ← こいつ
    let _ = try methodB(num: num) // throws 関数のなかで throws 関数を呼び出す ← こいつ
    if num == 6 {
        throw TestError.sixError
    }
    return num
}

func methodD(num: Int) {
    do {
        let c = try methodC(num: num) // 通常の関数のなかで throws 関数を呼び出す ← いつもの
        print(c)
    } catch {
        print(error)
    }
}
```

### このときの挙動

```swift
methodD(num: 9) // largeError
methodD(num: 3) // smallError
methodD(num: 6) // sixError
methodD(num: 7) // 7
```

### ポイント

- methodC で methodA や methodB のエラーを methodC 内で `throw` しなくても methodD 側までエラーを飛ばしてくれる
- methodC で methodA や methodB の `do-catch` は記述しなくてもコンパイルエラーにならない
- ただし、methodA や　methodB の前に `try` はつけないとコンパイルエラーとなる
- methodC ならではのエラーを飛ばす場合は、普通に `throw` すればよい（`throw TestError.sixError` のところ）
- `rethrows` はクロージャーで発生したエラーに関するハンドリングをいい感じにするやつなので、これとはあんまり関係ない（[rethrows のわかりやすい記事](https://swift.codelly.dev/guide/%E3%82%A8%E3%83%A9%E3%83%BC%E5%87%A6%E7%90%86/#rethrows)）


## 応用編

methodA や methodB も methodC 内で `do-catch` で囲むことで、別のエラーとして `throw` することが可能です。

### サンプル

```swift
import Foundation

enum TestError: Error {
    case largeError
    case smallError
    case sixError
    case wrapError // ← 追加
}

func methodA(num: Int) throws -> Int {
    if num > 8 {
        throw TestError.largeError
    }
    return num
}

func methodB(num: Int) throws -> Int {
    if num < 4 {
        throw TestError.smallError
    }
    return num
}

func methodC(num: Int) throws -> Int {
    let _ = try methodA(num: num)
    do {
        let _ = try methodB(num: num) // methodB を do-catch で囲む
    } catch {
        throw TestError.wrapError // methodB のエラーを wrapError に変換
    }
    if num == 6 {
        throw TestError.sixError
    }
    return num
}

func methodD(num: Int) {
    do {
        let c = try methodC(num: num)
        print(c)
    } catch {
        print(error)
    }
}
```

### このときの挙動

```swift
methodD(num: 9) // largeError
methodD(num: 3) // wrapError ← smallError から変更されている
methodD(num: 6) // sixError
methodD(num: 7) // 7
```

### ポイント

- methodA や methodB も methodC 内で `do-catch` で囲むことで、別のエラーとして `throw` することが可能（＝ エラーの置き換えが可能）

# まとめ

記事を探すよりも Playground でコーディングしたほうが早いこともある
