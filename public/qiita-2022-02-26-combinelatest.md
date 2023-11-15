---
title: '[Swift] [Combine] combineLatest() -> map() は combineLatest() {} で書き直せる'
tags:
  - Swift
private: false
updated_at: '2023-11-15T20:50:31+09:00'
id: 5b19fd94e53181e07fc5
organization_url_name: null
slide: false
ignorePublish: false
---

# 実際にやってみた

以下のサンプルコードをみれば、わかると思います。

## 共通コード

```swift
import Combine

var cancellables = Set<AnyCancellable>()

let pub1 = PassthroughSubject<Int, Never>()
let pub2 = PassthroughSubject<Int, Never>()
let pub3 = PassthroughSubject<Int, Never>()
```

## `combineLatest()` -> `map()` の場合

```swift
pub1
    .combineLatest(pub2)
    .map { $0 * $1 } // map() で処理
    .sink { print("Result: \($0).") }
    .store(in: &cancellables)

pub1.send(2)
pub2.send(3)
// Result: 6.

pub1.send(4)
// Result: 12.
```

## `combineLatest() {}` の場合

```swift
pub1
    .combineLatest(pub2) { $0 * $1 } // 変更
    .sink { print("Result: \($0).") }
    .store(in: &cancellables)

pub1.send(2)
pub2.send(3)
// Result: 6.

pub1.send(4)
// Result: 12.
```

このように `combineLatest()` -> `map()` で書いていた処理は `combineLatest() {}` で書き直せます。

## つなげることも可能

```swift
pub1
    .combineLatest(pub2, pub3) { $0 * $1 * $2 } // 変更
    .sink { print("Result: \($0).") }
    .store(in: &cancellables)

pub1.send(2)
pub2.send(3)
pub3.send(4)
// Result: 24.

pub1.send(5)
// Result: 60.
```


## `zip()` でも同様

```swift
pub1
    .zip(pub2) { $0 * $1 }
    .sink { print("Result: \($0).") }
    .store(in: &cancellables)

pub1.send(2)
pub2.send(3)
// Result: 6.

pub1.send(4)
// zip() は揃わないと出力なし！！
```

## `flatMap()` は以下のようになる

### `combineLatest() {}` を使わない場合

```swift
pub1
    .combineLatest(pub2)
    .flatMap { pub1, pub2 -> AnyPublisher<String, Never> in
        Just("\(pub1)\(pub2)").eraseToAnyPublisher()
    }
    .sink { print("Result: \($0).") }
    .store(in: &cancellables)

pub1.send(2)
pub2.send(3)
// Result: 23.

pub1.send(4)
// Result: 43.
```

### `combineLatest() {}` を使った場合

```swift
pub1
    .combineLatest(pub2) { pub1, pub2 -> AnyPublisher<String, Never> in
        Just("\(pub1)\(pub2)").eraseToAnyPublisher()
    }
    .flatMap { $0 }
    .sink { print("Result: \($0).") }
    .store(in: &cancellables)

pub1.send(2)
pub2.send(3)
// Result: 23.

pub1.send(4)
// Result: 43.
```

結局、`flatMap()` は残るので微妙ですね。

