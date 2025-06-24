---
title: "[Swift] [Combine] 1つの Publisher を共有したいときは share() を使おう！"
tags:
  - "Swift"
private: false
updated_at: ''
id: 4c5768538bbb26a65ff8
organization_url_name: null
slide: false
ignorePublish: false
---

# 伝えたいこと

- 1つの Publisher を  `share()` せずに共有した場合は subscribe した数だけ重複して処理が走ってしまうので、`share()` をすることによって、それを防ぐことができる

[この記事の続編↓]

- [[Swift] [Combine] 安易に share() した Publisher を subscribe すると出力を逃してしまう件](https://zenn.dev/ikuraikura/articles/2022-02-20-share)

# 前提条件

以下のような `AnyPublisher` を用意します。

```swift
import Combine

var cancellables: Set<AnyCancellable> = []
let numPublisher: PassthroughSubject<Int, Never> = .init()

let 親Publisher: AnyPublisher<Int, Never>
let 子1Publisher: AnyPublisher<Int, Never>
let 子2Publisher: AnyPublisher<Int, Never>
let 孫1_1Publisher: AnyPublisher<Int, Never>
let 孫1_2Publisher: AnyPublisher<Int, Never>
```

以下のような関係で Publisher を共有していきます。

```yaml
- numPublisher
  - 親
    - 子1
      - 孫1_1 ←
      - 孫1_2 ←
    - 子2 ←
```

そして、`←` のついている Publisher を subscribe して `numPublisher` を `send()` したときの挙動を確認します。

## share() を使わない場合

```swift
親Publisher = numPublisher
    .map {
        print("「親」を通過しました")
        return $0
    }
    .eraseToAnyPublisher()

子1Publisher = 親Publisher
    .map {
        print("「子1」を通過しました")
        return $0
    }
    .eraseToAnyPublisher()

子2Publisher = 親Publisher
    .map {
        print("「子2」を通過しました")
        return $0
    }
    .eraseToAnyPublisher()

孫1_1Publisher = 子1Publisher
    .map {
        print("「孫1_1」を通過しました")
        return $0
    }
    .eraseToAnyPublisher()

孫1_2Publisher = 子1Publisher
    .map {
        print("「孫1_2」を通過しました")
        return $0
    }
    .eraseToAnyPublisher()

// 以下、subscribe の処理
子2Publisher
    .sink { print("子2Publisher receive: \($0)")}
    .store(in: &cancellables)

孫1_1Publisher
    .sink { print("孫1_1Publisher receive: \($0)")}
    .store(in: &cancellables)

孫1_2Publisher
    .sink { print("孫1_2Publisher receive: \($0)")}
    .store(in: &cancellables)
```

この状態で `numPublisher` を `send()` してみます。

```swift
numPublisher.send(1)

// （出力）
// 「親」を通過しました
// 「子1」を通過しました
// 「孫1_1」を通過しました
// 孫1_1Publisher receive: 1
// 「親」を通過しました ← 余計
// 「子1」を通過しました ← 余計
// 「孫1_2」を通過しました
// 孫1_2Publisher receive: 1
// 「親」を通過しました ← 余計
// 「子2」を通過しました
// 子2Publisher receive: 1
```

以下のように subscribe した数だけ処理が重複して走っていることがわかります。

- 親：3回 ← 余計に 2 回通過
- 子1：2回 ← 余計に 1 回通過
- 子2：1回
- 孫1_1：1回
- 孫1_2：1回

今回のように `print()` で値を出力していれば、このことに気がつくのですが、そうでもしない限り、なかなか気づきづらい罠になります。

## share() を使う場合

共有される 「親Publisher」 と 「子1Publisher」 を `share()` した変数を新たに作成して、それを subscribe していきます。

```swift
親Publisher = numPublisher
    .map {
        print("「親」を通過しました")
        return $0
    }
    .eraseToAnyPublisher()

// share() した Publisher を作成
let shared親Publisher = 親Publisher.share()

子1Publisher = shared親Publisher
    .map {
        print("「子1」を通過しました")
        return $0
    }
    .eraseToAnyPublisher()

子2Publisher = shared親Publisher
    .map {
        print("「子2」を通過しました")
        return $0
    }
    .eraseToAnyPublisher()

// share() した Publisher を作成
let shared子1Publisher = 子1Publisher.share()

孫1_1Publisher = shared子1Publisher
    .map {
        print("「孫1_1」を通過しました")
        return $0
    }
    .eraseToAnyPublisher()

孫1_2Publisher = shared子1Publisher
    .map {
        print("「孫1_2」を通過しました")
        return $0
    }
    .eraseToAnyPublisher()
```


この状態で `numPublisher` を `send()` します。

```swift
numPublisher.send(1)

// （出力）
// 「親」を通過しました
// 「子1」を通過しました
// 「孫1_2」を通過しました
// 孫1_2Publisher receive: 1
// 「孫1_1」を通過しました
// 孫1_1Publisher receive: 1
// 「子2」を通過しました
// 子2Publisher receive: 1
```
出力がスッキリしましたね。

以下のように `share()` をつけると出力の回数が全て １ 回になったことがわかります。

- 親：1回
- 子1：1回
- 子2：1回
- 孫1_1：1回
- 孫1_2：1回


### これでもいける

`share()` した Publisher の変数をわざわざ用意するのが面倒な時は、`eraseToAnyPublisher()` の前に `share()`  を追加するだけで同様の挙動になります。

そのときは `share()` されていることがわかるような変数名にすることをお勧めします。

```swift
shared親Publisher = numPublisher
    .map {
        print("「親」を通過しました")
        return $0
    }
    .share() // 追加
    .eraseToAnyPublisher()

shared子1Publisher = 親Publisher
    .map {
        print("「子1」を通過しました")
        return $0
    }
    .share() // 追加
    .eraseToAnyPublisher()
```

# 結論

- 1つの Publisher を  `share()` せずに共有した場合は subscribe した数だけ重複して処理が走ってしまうので、`share()` をすることによって、それを防ぐことができる

[この記事の続編として、`share()` を使う際の注意点を紹介しております。]

- [[Swift] [Combine] 安易に share() した Publisher を subscribe すると出力を逃してしまう件](https://zenn.dev/ikuraikura/articles/2022-02-20-share)

以上になります。

# 参考

- [【Swift】Combineで一つのPublisherの出力結果を共有するメソッドやクラスの違い(share, multicast, Future)](https://qiita.com/shiz/items/f089c93bdebfaef2196f)
