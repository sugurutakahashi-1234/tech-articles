---
title: "[Swift] [Combine] prefix(untilOutputFrom:)で他のPublisherの出力を条件に完了させる"
tags:
  - "Swift"
  - "Combine"
private: false
updated_at: ''
id: 4a9c10ae0121b750153b
organization_url_name: null
slide: false
ignorePublish: false
---

# `.prefix(untilOutputFrom:)`

Combine には [`.prefix(untilOutputFrom:)`](https://developer.apple.com/documentation/combine/just/prefix(untiloutputfrom:)) という他の Publisher の出力を条件に、そのストリームの出力を止めて完了させるという、かなりマニアックな関数が用意されていたので紹介したいと思います。

## サンプルコード

挙動は以下のサンプルコードを見ていただくのが早いと思います。

```swift
var cancellables = Set<AnyCancellable>()

let firstPub: PassthroughSubject<Int, Never> = .init()
let secondPub: PassthroughSubject<String, Never> = .init()

firstPub
    .prefix(untilOutputFrom: secondPub)
    .sink {
        print("firstPub result: \($0)")
    } receiveValue: {
        print("firstPub output: \($0)")
    }
    .store(in: &cancellables)

secondPub
    .sink {
        print("secondPub result: \($0)")
    } receiveValue: {
        print("secondPub output: \($0)")
    }
    .store(in: &cancellables)

firstPub.send(1)
firstPub.send(2)

secondPub.send("a")

firstPub.send(3) // すでに secondPub が出力されたので無視される
firstPub.send(4) // すでに secondPub が出力されたので無視される

secondPub.send("b")

// 出力
// firstPub output: 1
// firstPub output: 2
// secondPub output: a
// firstPub result: finished ← secondPub から出力があった瞬間に完了する
// secondPub output: b
```

正直、これを使いそうな場面がぱっとは思いつきませんが、何かの出力をきっかけに完了させたいストリームがある場合にはもってこいだと思います。

## 注意点

`secondPub` を出力ではなく、完了させた場合はストリームは止まりません。


```swift
firstPub.send(1)
firstPub.send(2)

secondPub.send(completion: .finished) // 出力ではなく、完了させてみる

firstPub.send(3)
firstPub.send(4)

// 出力
// firstPub output: 1
// firstPub output: 2
// secondPub result: finished
// firstPub output: 3 ← 出力ではなく、完了してしまうとストリームは止まらない
// firstPub output: 4 ← 出力ではなく、完了してしまうとストリームは止まらない
```

これは `secondPub.send(completion: .finished)` だけではなく、 `secondPub.send(completion: .failure(Error))` とした場合も同様です。

では、出力条件ではなく、完了条件でストリームを止める `.prefix(untilCompletionFrom:)` みたいなものはないのかと探しましたが、ありませんでした。。。

今のところ、完了条件を伝搬させるには [`zip(_:)`](https://developer.apple.com/documentation/combine/publisher/zip(_:)) を使っていくしかなさそうです。

 [`zip(_:)`](https://developer.apple.com/documentation/combine/publisher/zip(_:)) を用いて、完了を伝播させた場合の細かい挙動については、以下の記事でまとめたので気になる方は参考にしてください。

- [[Swift] [Combine] zipの完了条件あれこれ](https://zenn.dev/ikuraikura/articles/2021-12-25-combine-zip)

ちなみに [`combineLatest(_:)`](https://developer.apple.com/documentation/combine/publisher/combinelatest(_:)) は連結した両方の Publisher が完了しない限り完了しないので注意してください。


# 補足 `.drop(untilOutputFrom:)` というものもある

[`.prefix(untilOutputFrom:)`](https://developer.apple.com/documentation/combine/just/prefix(untiloutputfrom:)) の逆で、他の Publisher の出力を条件に出力を開始する [`.drop(untilOutputFrom:)`](https://developer.apple.com/documentation/combine/fail/drop(untiloutputfrom:)) というものがあります。

サンプルコードは以下になります。

```swift
var cancellables = Set<AnyCancellable>()

let firstPub: PassthroughSubject<Int, Never> = .init()
let secondPub: PassthroughSubject<String, Never> = .init()

firstPub
    .drop(untilOutputFrom: secondPub)
    .sink {
        print("firstPub result: \($0)")
    } receiveValue: {
        print("firstPub output: \($0)")
    }
    .store(in: &cancellables)

secondPub
    .sink {
        print("secondPub result: \($0)")
    } receiveValue: {
        print("secondPub output: \($0)")
    }
    .store(in: &cancellables)


firstPub.send(1) // secondPub が出力されていないので無視される
firstPub.send(2) // secondPub が出力されていないので無視される

secondPub.send("a")

firstPub.send(3) // secondPub が出力されたので出力が開始される
firstPub.send(4) // secondPub が出力されたので出力が開始され

secondPub.send("b")

// 出力
// secondPub output: a
// firstPub output: 3
// firstPub output: 4
// secondPub output: b
```

正直、[`combineLatest(_:)`](https://developer.apple.com/documentation/combine/publisher/combinelatest(_:)) でも表現できなくないですが、その出力のタプルの片方を無視している場合などは [`.drop(untilOutputFrom:)`](https://developer.apple.com/documentation/combine/fail/drop(untiloutputfrom:)) で書いてあげるのが適切かもしれません。
