---
title: "【Swift, Combine】複数条件を監視するなら combineLatest, filter, first の組み合わせがおすすめ"
emoji: "🔖"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["Swift", "Combine"]
published: true
---

# この記事で伝えたいこと

- Publisher は適当な単位で分割した方が見通しがよい（長くなりすぎても分割しすぎても読みにくい）
- 条件判定の Publisher は Output を `Bool` にしておくと扱いやすい
- `combineLatest()` のあとのタプルの見通しが悪いので、早めに `map()` して出力を1つにしたほうがよい
- `filter()` 後に `first()` することで、条件が揃った後すぐに completion ブロックに飛ばすことができる
- Error が発生する処理の場合は、条件監視とは別に、エラーハンドリング専用の Publisher の監視をさせたほうが見通しがよい ＝ Publisher の subscribe も適当な単位で分割した方が見通しがよい

# やりたいこと

今回やりたいことは、複数の Publisher のすべての出力がある条件を満たしている場合に、処理を実行させるような Combine 処理を記述することになります。

どんなユースケースかというと、例えば、アプリの初期設定の入力フォームで (1)年齢、(2)名前、(3)利用規約同意のチェックボックスがすべて埋まった瞬間に、自動遷移する画面などで使うイメージです。

# サンプルコード

## (1) Publisher を用意する

それぞれに相当する Publisher を用意します。
今回は `PassthroughSubject` でも `CurrentValueSubject` でもどちらでも良いと思います。

この段階での Output の型は自由で構いません。

```swift
let publisherA: PassthroughSubject<Int, Never> = .init() // ex) 年齢
let publisherB: PassthroughSubject<String, Never> = .init() // ex) 名前
let publisherC: PassthroughSubject<Bool, Never> = .init() // ex) 利用規約同意のチェックボックス
```

## (2) 判定ロジックを通した Bool 値の AnyPublisher を用意する

publisherA、publisherB、publisherC についての判定処理を `map()` で行い Output を `Bool` に変換した AnyPublisher を用意します。

```swift
let checkPublisherA: AnyPublisher<Bool, Never> = publisherA
    .map { $0 != 0 } // 判定ロジック
    .eraseToAnyPublisher()

let checkPublisherB: AnyPublisher<Bool, Never> = publisherB
    .map { $0 != "" } // 判定ロジック
    .eraseToAnyPublisher()

let checkPublisherC: AnyPublisher<Bool, Never> = publisherC
    .map { $0 } // 判定ロジック
    .eraseToAnyPublisher()
```

## (3) `combineLatest()` でつないで `map()` でまとめる

`combineLatest()` で checkPublisherA、checkPublisherB、checkPublisherC をつないで、`map()` によって Output をひとつの `Bool` とした AnyPublisher にまとめます。

```swift
let allCheckPublisher: AnyPublisher<Bool, Never> = checkPublisherA
    .combineLatest(checkPublisherB, checkPublisherC)
    .map { checkA, checkB, checkC in
        print("checkA: \(checkA), checkB: \(checkB), checkC: \(checkC)")
        return checkA && checkB && checkC
    }
    .eraseToAnyPublisher()
```

## (4) subscribe する

ひとつの `Bool` にまとめた AnyPublisher を subscribe して、`filter()` 後に `first()` することで、条件が揃った後すぐに completion ブロックに飛ばすことができます。

```swift
var cancellable = allCheckPublisher
    .filter { $0 }
    .first() // 一度 true になった瞬間に completion してほしい場合は first() をつける
    .sink { completion in
        switch completion {
        case .finished:
            print("completion: \(completion)")
            // ここですべての条件が揃った場合に行いたい処理を実行する
        case let .failure(error):
            print("error: \(error)")
        }
    } receiveValue: { print("output: \($0)") }
```

## (5) 実際に動かしてみる

適当に元の Publisher を出力すると、条件が揃った時に初めて completion することが確認できます。

```swift
publisherA.send(1)
publisherB.send("")
publisherC.send(false) // checkA: true, checkB: false, checkC: false

publisherB.send("a") // checkA: true, checkB: true, checkC: false
publisherC.send(true) // checkA: true, checkB: true, checkC: true

// output: (true, true, true) ← filter を通過して receiveValue へ
// completion: finished ← first()によって completion へ
```

## (6) 一連の処理をまとめて記述した場合

全部まとめると以下のような記述になります。

```swift
let publisherA: PassthroughSubject<Int, Never> = .init()
let publisherB: PassthroughSubject<String, Never> = .init()
let publisherC: PassthroughSubject<Bool, Never> = .init()

let checkPublisherA: AnyPublisher<Bool, Never> = publisherA
    .map { $0 != 0 }
    .eraseToAnyPublisher()

let checkPublisherB: AnyPublisher<Bool, Never> = publisherB
    .map { $0 != "" }
    .eraseToAnyPublisher()

let checkPublisherC: AnyPublisher<Bool, Never> = publisherC
    .map { $0 }
    .eraseToAnyPublisher()

let allCheckPublisher: AnyPublisher<Bool, Never> = checkPublisherA
    .combineLatest(checkPublisherB, checkPublisherC)
    .map { checkA, checkB, checkC in
        print("checkA: \(checkA), checkB: \(checkB), checkC: \(checkC)")
        return checkA && checkB && checkC
    }
    .eraseToAnyPublisher()

var cancellable = allCheckPublisher
    .filter { $0 }
    .first() // 一度 true になった瞬間に completion してほしい場合は first() をつける
    .sink { completion in
        switch completion {
        case .finished:
            print("completion: \(completion)")
            // ここですべての条件が揃った場合に行いたい処理を実行する
        case let .failure(error):
            print("error: \(error)")
        }
    } receiveValue: { print("output: \($0)") }
```

分割しすぎてちょっと読みづらいですね。

## (7) Publisher を分割せずに書いた場合

個人的な意見として、`combineLatest()` など、Publisher を組み合わせる場合は Publisher をなるべく分割した方が読みやすいと思っています。

分割した Publisher の変数名から何をしたいのかが察しやすいです。

ただ、今回のように判定条件が単純であれば、Publisher を以下のように分割せずに書き切ったほうが見やすいかもしれません。

```swift
let publisherA: PassthroughSubject<Int, Never> = .init()
let publisherB: PassthroughSubject<String, Never> = .init()
let publisherC: PassthroughSubject<Bool, Never> = .init()

var cancellable = publisherA
    .combineLatest(publisherB, publisherC)
    .map { a, b, c in
        a != 0 && b != "" && c
    }
    .filter { $0 }
    .first()
    .sink { completion in
        switch completion {
        case .finished:
            print("completion: \(completion)")
        case let .failure(error):
            print("error: \(error)")
        }
    } receiveValue: { print("output: \($0)") }
```

Publisher の分割単位はケースバイケースですね。

# (8) Publisher を分割せずに書くことによる弊害

例えば publisherB に Error が発生する可能性がある場合は、`combineLatest()` の制約上、Failure の型を合わせないといけないため、コンパイルエラーとなってしまいます。


```swift
let publisherA: PassthroughSubject<Int, Never> = .init()
let publisherB: PassthroughSubject<String, Error> = .init() // Errorの発生の可能性
let publisherC: PassthroughSubject<Bool, Never> = .init()

// 以下は  コンパイルエラーとなってしまう。
var cancellable = publisherA // Instance method 'combineLatest' requires the types 'Never' and 'Error' be equivalent
    .combineLatest(publisherB, publisherC)
    .map { a, b, c in
        a != 0 && b != "" && c
    }
    .filter { $0 }
    .first()
    .sink { completion in
        switch completion {
        case .finished:
            print("completion: \(completion)")
        case let .failure(error):
            print("error: \(error)")
        }
    } receiveValue: { print("output: \($0)") }
```

このようなときの修正案をいくつか挙げたいと思います。

### 修正案1: Failure の型を Error に統一する

Failure が Never の publisherA、publisherC に `setFailureType(to: Error.self)` して、Error 型に揃えることができます。

```swift
var cancellable = publisherA.setFailureType(to: Error.self).eraseToAnyPublisher()
    .combineLatest(publisherB, publisherC.setFailureType(to: Error.self).eraseToAnyPublisher())
    .map { a, b, c in
        a != 0 && b != "" && c
    }
    .filter { $0 }
    .first()
    .sink { completion in
        switch completion {
        case .finished:
            print("completion: \(completion)")
        case let .failure(error):
            print("error: \(error)")
        }
    } receiveValue: { print("output: \($0)") }
```

とても見づらいですね。。。

### 修正案2: Failure の型を Never に統一する

`replaceError(with:)` で Failure を Never に変換することができます。

```swift
var cancellable = publisherA
    .combineLatest(publisherB.replaceError(with: ""), publisherC) // replaceError で Never にする
    .map { a, b, c in
        a != 0 && b != "" && c
    }
    .filter { $0 }
    .first()
    .sink { completion in
        switch completion {
        case .finished:
            print("completion: \(completion)")
        case let .failure(error):
            print("error: \(error)")
        }
    } receiveValue: { print("output: \($0)") }
```

一見、いい感じですが、publisherB のエラー発生時に空文字に変換することが `b != ""` の結果を `false` にするという暗黙的実装が含まれてしまいます。

### 修正案3: Failure の型を Never にした Publisher を用意する

つまり、Publisher の分割案です。

```swift
let checkPublisherA: AnyPublisher<Bool, Never> = publisherA
    .map { $0 != 0 }
    .eraseToAnyPublisher()

let checkPublisherB: AnyPublisher<Bool, Never> = publisherB
    .map { $0 != "" }
    .replaceError(with: false) // replaceError で Neverにする
    .eraseToAnyPublisher()

let checkPublisherC: AnyPublisher<Bool, Never> = publisherC
    .map { $0 }
    .eraseToAnyPublisher()

var cancellable = checkPublisherA
    .combineLatest(checkPublisherB, checkPublisherC)
    .map { $0 && $1 && $2}
    .filter { $0 }
    .first()
    .sink { completion in
        switch completion {
        case .finished:
            print("completion: \(completion)")
        case let .failure(error):
            print("error: \(error)")
        }
    } receiveValue: { print("output: \($0)") }
```

これであれば、条件判定の checkPublisherB について、publisherB が Error となったときに、`false` を出力するということがわかりやすいですね。

また、必要に応じて、publisherB を単独で subscribe することによって、エラーハンドリングすることも可能です。

```swift
// publisherBのエラーハンドリング用のsubscribe
publisherB
    .sink { completion in
        if case let .failure(error) = completion {
            print("publisherB error: \(error)")
        }
    } receiveValue: { _ in }
    .store(in: &cancellables)
```

余談になりますが、条件判定用の subscribe 側で publisherB のエラーハンドリングを行おうことはおすすめしません。

それを行おうとするとエラー検知用の AnyPublisher を用意して、それを　`zip()` でつなぐようなことをしなければならなくなり、Combine 処理を複雑にすることにつながります。

Publisher もそうですが、その subscribe も目的の用途に合わせて、それぞれ分割して用意してあげると見通しがよくなります。

# 結論

- Publisher は適当な単位で分割した方が見通しがよい（長くなりすぎても分割しすぎても読みにくい）
- 条件判定の Publisher は Output を `Bool` にしておくと扱いやすい
- `combineLatest()` のあとのタプルの見通しが悪いので、早めに `map()` して出力を1つにしたほうがよい
- `filter()` 後に `first()` することで、条件が揃った後すぐに completion ブロックに飛ばすことができる
- Error が発生する処理の場合は、条件監視とは別に、エラーハンドリング専用の Publisher の監視をさせたほうが見通しがよい ＝ Publisher の subscribe も適当な単位で分割した方が見通しがよい

以上になります。