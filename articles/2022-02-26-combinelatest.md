---
title: "[Swift] [Combine] combineLatest() -> map() は combineLatest() {} で書き直せる件"
emoji: "🌾"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["Swift"]
published: true
---

# 実際にやってみた

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

以上になります。