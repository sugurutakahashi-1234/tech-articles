---
title: "【Swift】【Combine】zipの完了条件あれこれ"
emoji: "🔖"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["Swift","Combine"]
published: true
---

# はじめに

`Combine` で `zip` を使うとき、いつも完了条件があやふやなので挙動をまとめてみました。

# 結論

先に結論を述べますと `zip` の完了条件は以下の通りです。

- 両方が完了する必要はない
- 片方が完了をした段階で、値が揃っていれば完了する
- 値が揃っていない状態で、片方が完了した場合、値が揃うまで待ち、揃った段階で完了する


# zip の基本的な挙動

今回は例としてして、以下のような `ziped` という publisher を使って実験したいと思います。

```swift
import Combine

var cancellables: Set<AnyCancellable> = []

let subject1 = PassthroughSubject<Void, Error>()
let subject2 = PassthroughSubject<Void, Error>()
let zipped = subject1.zip(subject2)
```

## 基本動作 - 値を出力するとき

```swift
zipped
    .sink { result in
        switch result {
        case .finished:
            print("finished")
        case .failure(let error):
            print("failure error: \(error)")
        }
    } receiveValue: { _ in
        print("receiveValue")
    }
    .store(in: &cancellables)

subject1.send(())
subject1.send(())
subject2.send(()) // receiveValue
subject2.send(()) // receiveValue
```

`zip` は値が揃った時にはじめて出力します。

## 基本動作 - 完了させるとき

そしてこのときに `zipped` のストリームを完了させようと思うと、以下の 2 行を追加するのが直感的です。

```swift
subject1.send(completion: .finished)
subject2.send(completion: .finished)
```

もちろん上記のコードで完了はするのですが、実は `subject1.send(completion: .finished)` の段階でストリームは完了していることがわかりました。

```swift
subject1.send(completion: .finished) // どうもこのタイミングで finished となる
subject2.send(completion: .finished) // こちらはいらない説？
```

このあたりの挙動を整理するためにいろいろと実験させてみたというのがこの記事になります。

# 実験その1 - 片方のみを出力なしで完了させたとき

```swift
let subject1 = PassthroughSubject<Void, Error>()
let subject2 = PassthroughSubject<Void, Error>()
let zipped = subject1.zip(subject2)

zipped
    .sink { result in
        switch result {
        case .finished:
            print("finished")
        case .failure(let error):
            print("failure error: \(error)")
        }
    } receiveValue: { _ in
        print("receiveValue")
    }
    .store(in: &cancellables)

subject1.send(completion: .finished) // finished
```

- 出力がなくても完了する
- 片方だけが完了すれば `zipped` も完了する


# 実験その2 - 片方のみ出力&完了させたとき

```swift
let subject1 = PassthroughSubject<Void, Error>()
let subject2 = PassthroughSubject<Void, Error>()
let zipped = subject1.zip(subject2)

zipped
    .sink { result in
        switch result {
        case .finished:
            print("finished")
        case .failure(let error):
            print("failure error: \(error)")
        }
    } receiveValue: { _ in
        print("receiveValue")
    }
    .store(in: &cancellables)

subject1.send(())
subject1.send(completion: .finished)

// zippedは出力されない
// zippedは完了されない
```

- 値が揃わないので `zipped` は出力されない ← 当たり前の挙動
- 値が揃っていないので完了されない

# 実験その3 - 両方で出力後、片方を完了させたとき

```swift
let subject1 = PassthroughSubject<Void, Error>()
let subject2 = PassthroughSubject<Void, Error>()
let zipped = subject1.zip(subject2)

zipped
    .sink { result in
        switch result {
        case .finished:
            print("finished")
        case .failure(let error):
            print("failure error: \(error)")
        }
    } receiveValue: { _ in
        print("receiveValue")
    }
    .store(in: &cancellables)

subject1.send(())
subject2.send(()) // receiveValue
subject1.send(completion: .finished) // finished
```

- `subject2` は完了させる必要はない

## 実験その4 - 片方のみ出力&完了させ、もう片方を出力したとき

```swift
let subject1 = PassthroughSubject<Void, Error>()
let subject2 = PassthroughSubject<Void, Error>()
let zipped = subject1.zip(subject2)

zipped
    .sink { result in
        switch result {
        case .finished:
            print("finished")
        case .failure(let error):
            print("failure error: \(error)")
        }
    } receiveValue: { _ in
        print("receiveValue")
    }
    .store(in: &cancellables)

subject1.send(())
subject1.send(completion: .finished)

subject2.send(())
// receiveValue
// finished
```

- 値が揃った瞬間に `zipped` が出力する&完了する
- `subject2` は完了させる必要はない

# 実験からわかったこと

- 両方が完了する必要はない
- 片方が完了をした段階で、値が揃っていれば完了する
- 値が揃っていない状態で、片方が完了した場合、値が揃うまで待ち、揃った段階で完了する

# 応用編

## 問題

以下の場合、A から H のどこで `"receiveValue"` と `"finished"` するでしょうか？

```swift
let subject1 = PassthroughSubject<Void, Error>()
let subject2 = PassthroughSubject<Void, Error>()
let zipped = subject1.zip(subject2)

zipped
    .sink { result in
        switch result {
        case .finished:
            print("finished")
        case .failure(let error):
            print("failure error: \(error)")
        }
    } receiveValue: { _ in
        print("receiveValue")
    }
    .store(in: &cancellables)

subject1.send(()) // A
subject1.send(()) // B
subject1.send(completion: .finished) // C
subject1.send(()) // D
subject2.send(()) // E
subject2.send(()) // F
subject2.send(()) // G
subject2.send(completion: .finished) // H

```

## 答え

```swift
subject1.send(())
subject1.send(())
subject1.send(completion: .finished)
subject1.send(())
subject2.send(()) // receiveValue
subject2.send(()) // receiveValue, finished
subject2.send(())
subject2.send(completion: .finished)
```
解説は以下の通りです。

```swift
subject1.send(())
subject1.send(())
subject1.send(completion: .finished) // subject1 は完了しているが、2つの値が揃っていない状態
subject1.send(()) // ← すでに subject1 が finished しているので意味ない
subject2.send(()) // 値の1つめが揃うので receiveValue
subject2.send(()) // 値の2つめが揃ったので receiveValue、そしてすべて揃い切ったので finished となる
subject2.send(()) // ← すでに zipped が finished しているので意味ない
subject2.send(completion: .finished) // ← すでに zipped が finished しているので意味ない
```

以上になります。