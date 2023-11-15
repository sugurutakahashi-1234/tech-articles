---
title: '[Swift] 『private extension 内の func』と『extension 内の private func』の差の確認'
tags:
  - Swift
private: false
updated_at: '2023-11-15T20:50:30+09:00'
id: f382c7cd755ff7b5d3e1
organization_url_name: null
slide: false
ignorePublish: false
---

# はじめに

『private extension 内の func』と『extension 内の private func』の挙動の差を確認するための記事になります。

# 問題

問題です。

以下のような class が定義されているとします。

```swift
class Hoge {
    func hogehoge() {
        print("hogehoge")
    }
    
    private func mogemoge() {
        print("mogemoge")
    }
}

private extension Hoge {
    func hugahuga() {
        print("hugahuga")
    }
}

extension Hoge {
    private func piyopiyo() {
        print("piyopiyo")
    }
}
```

## 問題(1): 「class Hoge」の定義と同じファイル内の場合

「class Hoge」の定義と同じファイル内で Hoge クラスの各関数を実行しようとした場合、コンパイルエラーとなるのは、以下の内どれでしょうか？

```swift
// 「class Hoge」の定義と同じファイル内
class Moge {
    init() {
        let hoge = Hoge()
        hoge.hogehoge()
        hoge.mogemoge()
        hoge.hugahuga()
        hoge.piyopiyo()
    }
}
```

## 問題(2): 「class Hoge」の定義と別ファイルの場合

「class Hoge」の定義と別のファイルで Hoge クラスの各関数を実行しようとした場合、コンパイルエラーとなるのは、以下の内どれでしょうか？

```swift
// 「class Hoge」の定義と別ファイル
class Fuga {
    init() {
        let hoge = Hoge()
        hoge.hogehoge()
        hoge.mogemoge()
        hoge.hugahuga()
        hoge.piyopiyo()
    }
}
```

# 答え

## 問題(1): 「class Hoge」の定義と同じファイル内の場合

```swift
// 「class Hoge」の定義と同じファイル内
class Moge {
    init() {
        let hoge = Hoge()
        hoge.hogehoge() // ← OK 🌟
        hoge.mogemoge() // ← コンパイルエラー 🌀
        hoge.hugahuga() // ← OK 🌟
        hoge.piyopiyo() // ← コンパイルエラー 🌀
    }
}
```

`private extension` は同じファイル内にいる場合はアクセス可能なので、`hugahuga()` は実行できます。

## 問題(2): 「class Hoge」の定義と別ファイルの場合

```swift
// 「class Hoge」の定義と別ファイル
class Fuga {
    init() {
        let hoge = Hoge()
        hoge.hogehoge() // ← OK 🌟
        hoge.mogemoge() // ← コンパイルエラー 🌀
        hoge.hugahuga() // ← コンパイルエラー 🌀
        hoge.piyopiyo() // ← コンパイルエラー 🌀
    }
}
```

先ほどと違い、別ファイルにいるため、`hugahuga()` を実行しようとするとコンパイルエラーとなります。

以上になります。
