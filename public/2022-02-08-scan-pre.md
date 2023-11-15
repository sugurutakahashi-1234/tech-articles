---
title: '[Swift] [Combine] didSetのoldValueに相当する値をCombineのストリームで扱う方法'
tags:
  - Swift
  - Combine
private: false
updated_at: '2023-11-15T20:50:31+09:00'
id: 104c602f64fab01e93a8
organization_url_name: null
slide: false
ignorePublish: false
---

# 結論

- 初期値を設定したくない場合 -> `zip()` と `dropFirst()` を使う
- 初期値を設定したい場合 ->  `scan()` を使う

一般化した Publisher の extension も紹介しますが、正直、混乱の元なので個人的には使わないほうがいい気がしました。

# サンプルコード

## 初期値を設定したくない場合

### zip()とdropFirst()を使う

```swift
var cancellables = Set<AnyCancellable>()
let numPublisher: PassthroughSubject<Int, Never> = .init()

numPublisher
    .zip(numPublisher.dropFirst())
    .sink { previous, current in
        print("previous: \(previous), current: \(current)")
    }
    .store(in: &cancellables)

numPublisher.send(1) // 出力なし
numPublisher.send(2) // previous: 1, current: 2
numPublisher.send(3) // previous: 2, current: 3
```

### 初期値を設定したくない場合の一般化

```swift
// 一般化
extension Publisher {
    func withPrevious() -> AnyPublisher<(previous: Output, current: Output), Failure> {
        zip(self.dropFirst())
        .map { previous, current -> (previous: Output, current: Output) in (previous, current) }
        .eraseToAnyPublisher()
    }
}

// 使い方
numPublisher
    .withPrevious()
    .sink { previous, current in
        print("previous: \(previous), current: \(current)")
    }
    .store(in: &cancellables)

numPublisher.send(1) // 出力なし
numPublisher.send(2) // previous: 1, current: 2
numPublisher.send(3) // previous: 2, current: 3
```

## 初期値を設定したい場合

### scan()を使う

```swift
var cancellables = Set<AnyCancellable>()
let numPublisher: PassthroughSubject<Int, Never> = .init()

numPublisher
    .scan((0, 0)) { ($0.1, $1) }
    .sink { previous, current in
        print("previous: \(previous), current: \(current)")
    }
    .store(in: &cancellables)

numPublisher.send(1) // previous: 0, current: 1
numPublisher.send(2) // previous: 1, current: 2
numPublisher.send(3) // previous: 2, current: 3
```

### 初期値を設定したい場合の一般化

```swift
// 一般化
extension Publisher {
    func withPrevious(initialPreviousValue: Output) -> AnyPublisher<(previous: Output, current: Output), Failure> {
        scan((initialPreviousValue, initialPreviousValue)) { ($0.1, $1) }.eraseToAnyPublisher()
    }
}

// 使い方
numPublisher
    .withPrevious(initialPreviousValue: 0)
    .sink { previous, current in
        print("previous: \(previous), current: \(current)")
    }
    .store(in: &cancellables)

numPublisher.send(1) // previous: 0, current: 1
numPublisher.send(2) // previous: 1, current: 2
numPublisher.send(3) // previous: 2, current: 3
```

本編は以上になります。

# 以降、結論に至るまでのメモ書きになります

結論に至るまでの過程で、いろいろと検証して勉強になったので、そのメモ書きを残したいと思います。

## 本記事を投稿しようと思った動機

まず、以下のような Publisher とそれを subscribe する処理を用意します。

```swift
var cancellables = Set<AnyCancellable>()
let numPublisher: PassthroughSubject<Int, Never> = .init()

numPublisher
    .sink { print("receiveValue: \($0)") }
    .store(in: &cancellables)

numPublisher.send(1) // receiveValue: 1
numPublisher.send(2) // receiveValue: 2
numPublisher.send(3) // receiveValue: 3
```
このときに `sink()` の `receiveValue` で いわゆる `didSet` の `oldValue` に相当する値を用いて処理したくなったのが、本記事を投稿しようと思った動機になります。

そこで、「Combine didSet oldValue」で検索すると以下の StackOverflow の記事がヒットして、それを参考にいろいろと検証しました。


- [Combine previous value using Combine - StackOverflow](https://stackoverflow.com/questions/63926305/combine-previous-value-using-combine)

## 初期値を設定したくない場合の一般化の際に `map()` でタプルの変数名を定義した背景

まず、以下のように `sink()` の `receiveValue` のブロックにおいて、どのように Output にアクセスするのが読みやすいのかを検討しました。

### その1： `$index` でのアクセス

```swift
numPublisher
    .scan((0, 0)) { ($0.1, $1) }
    .sink { print("previous: \($0), current: \($1)") }
    .store(in: &cancellables)
```

記述量も少なくシンプルですが初見殺しです。

### その2： subscribe 側でタプルの変数名をそれぞれ定義する

subscribe 側でタプルの変数名を定義することもできます。

```swift
numPublisher
    .scan((0, 0)) { ($0.1, $1) }
    .sink { previous, current in // タプルの変数名を定義
        print("previous: \(previous), current: \(current)")
    }
    .store(in: &cancellables)
```

わかりやすいです。
一般化しない場合はこれがいいと思います。

### その3： subscribe 側で変数名を定義して、タプルの index でそれぞれアクセスする

Output の変数名を定義するとタプルの Index でアクセスすることが可能になります。

```swift
numPublisher
    .scan((0, 0)) { ($0.1, $1) }
    .sink { output in
        print("previous: \(output.0), current: \(output.1)")
    }
    .store(in: &cancellables)
```

ちょっとわかりにくいですね。

### その4： structを定義する

```swift
struct NumPublisherOutput {
    let previous: Int
    let current: Int
}

numPublisher
    .scan((0, 0)) { ($0.1, $1) }
    .map { previous, current -> NumPublisherOutput in
        NumPublisherOutput(previous: previous, current: current)
    }
    .sink { output in
        print("previous: \(output.previous), current: \(output.current)")
    }
    .store(in: &cancellables)
```

ちょっとしんどいですね。
今回の場合はあまりお勧めしません。

### その5： 事前に map() でタプルの変数名を定義する

`map()` でタプルの変数名を定義します。

```swift
numPublisher
    .scan((0, 0)) { ($0.1, $1) }
    .map { previous, current -> (previous: Int, current: Int) in (previous, current) }
    .sink { output in
        // タプルの変数名を定義することでタプルでのアクセスがわかりやすくなる
        print("previous: \(output.previous), current: \(output.current)")
    }
    .store(in: &cancellables)
```

この場合、**その3** のようにタプルの index を気にする必要はありません。

さらに、これの良いところは、**その2**のように subscribe 側でタプルの変数名をそれぞれ定義することもできます。

```swift
numPublisher
    .scan((0, 0)) { ($0.1, $1) }
    .map { previous, current -> (previous: Int, current: Int) in (previous, current) }
    .sink { previous, current in // ここで変数名の定義も可能
        print("previous: \(previous), current: \(current)")
    }
    .store(in: &cancellables)
```

どっちでもいけるので便利ですね。

そのため、今回、一般化した際には、**その5** のように変数名の定義したタプルを返してあげることにしました。

## 初期値を設定したくない場合 に `scan()` と `dropFirst()` ではなく `zip()` と `dropFirst()` を使うことになった背景

### 案1： `scan()` と `dropFirst()` を使う（`self.init()` 編）

はじめは、以下のような `scan()` と `dropFirst()` の組み合わせを考えていました。

```swift
numPublisher
    .scan((0, 0)) { ($0.1, $1) }
    .dropFirst() // dropFirst() で初期値を無視する
    .sink { previous, current in
        print("previous: \(previous), current: \(current)")
    }
    .store(in: &cancellables)

numPublisher.send(1) // ← dropFirst() によって出力されない
numPublisher.send(2) // previous: 1, current: 2
numPublisher.send(3) // previous: 2, current: 3
```

ただし、この方法だと使用しない初期値（今回の場合は `0`）を定義しなければならないという問題点がありました。

それを回避する方法として、`0` と具体値を記述するのではなく、`Int()` と書き直すことを考えました。

```swift
numPublisher
    .scan((Int(), Int())) { ($0.1, $1) } // 0 ではなく、`Int()` と書き直す
    .dropFirst()
    .sink { previous, current in
        print("previous: \(previous), current: \(current)")
    }
    .store(in: &cancellables)
```

しかし、これを一般化しようと思い、以下の extension を記述したところ「Type 'Self.Output' has no member 'init'」のコンパイルエラーとなってしまいました。

```swift
extension Publisher {
    //  以下はコンパイルエラーとなってしまう
    func withPrevious() -> AnyPublisher<(previous: Output, current: Output), Failure> {
        scan((Output(), Output())) { ($0.1, $1) } // compile error: Type 'Self.Output' has no member 'init'
        .dropFirst()
        .eraseToAnyPublisher()
    }
}
```

これを打破する方法が思いつかず、この方法は断念しました。

（もし打開する方法があれば教えていただきたいです＞＜）

### 案2： `scan()` と `dropFirst()` を使う（`Optional<(Output?, Output)>.none` 編）

`scan()`を参考にした StackOverflow の記事に `Optional<(Output?, Output)>.none` を使う方法が書いてあったので、それを使えば初期値を設定しなくても記述できることがわかりました。

- [Combine previous value using Combine - StackOverflow](https://stackoverflow.com/questions/63926305/combine-previous-value-using-combine)

それが以下のコードになります。

```swift
numPublisher
    .scan(Optional<(Int?, Int)>.none) { ($0?.1, $1) }
    .compactMap { $0 }
    .compactMap { previous, current -> (previous: Int, current: Int)? in
        guard let previous = previous else { return nil }
        return (previous, current)
    }
    .sink { output in
        print("previous: \(output.previous), current: \(output.current)")
    }
    .store(in: &cancellables)

numPublisher.send(1) // ← compactMap()によって出力されない
numPublisher.send(2) // previous: 1, current: 2
numPublisher.send(3) // previous: 2, current: 3
```

どうですかね？
ちょっと読むのが大変ですよね。

ただ、一般化することには成功しました。

```swift
extension Publisher {
    func withPrevious() -> AnyPublisher<(previous: Output, current: Output), Failure> {
        scan(Optional<(Output?, Output)>.none) { ($0?.1, $1) }
        .compactMap { $0 }
        .compactMap { previous, current in
            guard let previous = previous else { return nil }
            return (previous, current)
        }
        .eraseToAnyPublisher()
    }
}
```

ですが、ぱっと見では何をやっているのかわからなくて、第三者が書いたコードだと考えると使うのをためらいます笑

そこで、もっといい方法がないかと考えたところ、以下の案がよさそうなことがわかりました。

### 案3：`zip()` と `dropFirst()` を使う

とてもスマートですね。

```swift
numPublisher
    .zip(numPublisher.dropFirst())
    .sink { previous, current in
        print("previous: \(previous), current: \(current)")
    }
    .store(in: &cancellables)

numPublisher.send(1) // 出力なし
numPublisher.send(2) // previous: 1, current: 2
numPublisher.send(3) // previous: 2, current: 3
```

`dropFirst()` 側の方が、`previous` ではなく、`current` になるのは直感に反するかもしれませんが、`zip()` は両方の組み合わせが揃ったときに出力されるので、ゆっくり考えれば理解できると思います。

一般化もできました。

```swift
extension Publisher {
    func withPrevious() -> AnyPublisher<(previous: Output, current: Output), Failure> {
        zip(self.dropFirst())
        .map { previous, current -> (previous: Output, current: Output) in (previous, current) }
        .eraseToAnyPublisher()
    }
}
```

こういった背景で、`zip()` と `dropFirst()` を使うことになりました。

メモ書きは以上になります。
