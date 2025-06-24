---
title: "[Swift] [Combine] ストリームはcancel()やsend(completion:)を受け付けた時点で出力を受け付けない"
tags:
  - "Swift"
private: false
updated_at: ''
id: 2cdead5ec940c484f16a
organization_url_name: null
slide: false
ignorePublish: false
---

# この記事でわかること

- Combine ストリームは `cancel()` や `send(completion:)` を受け付けた時点で出力を受け付けない


# 実験(1) `cancel()` の場合

## 前提条件

以下のようのなサンプルコードを用意します。

ポイントとしては、`map()` 処理に遅延を入れているところです。

```swift
import Combine
import Foundation

var cancellables = Set<AnyCancellable>()
let numPublisher: PassthroughSubject<Int, Error> = .init()

numPublisher
    .handleEvents(receiveOutput: {
        print("receiveRequest: \($0)")
    }, receiveCancel: {
        print("receiveCancel")
    })
    .map { num -> Int in
        Thread.sleep(forTimeInterval: 3.0) // 遅延処理
        return num
    }
    .sink { result in
        switch result {
        case .finished:
            print("finished")
        case let .failure(error):
            print("failure: \(error)")
        }
    } receiveValue: { value in
        print("receiveValue: \(value)")
    }
    .store(in: &cancellables)
```

## 実験内容

この状態で、以下を実行してみます。

1. `numPublisher` の出力
2. `cancellables` の `cancel()`
3. `numPublisher` の出力

```swift:実験
// 1. `numPublisher` の出力
numPublisher.send(1)
numPublisher.send(2)

// 2. `cancellables` の `cancel()`
cancellables.map { $0.cancel() }

// 3. `numPublisher` の出力
numPublisher.send(3)
```

## 確認ポイント

`map()` に3秒の遅延処理を入れているため、『2. `cancellables` の `cancel()`』を実行したタイミングでは、まだ、『1. `numPublisher` の出力』 が `receiveValue` まで到達していないとう状況で、『3. `numPublisher` の出力』がどう処理されるのかを確認します。

## 出力結果

出力の結果は以下のようになりました。

```swift:結果
// （出力）
// receiveRequest: 1
// receiveValue: 1
// receiveRequest: 2
// receiveValue: 2
// receiveCancel
↑
`numPublisher.send(3)` は受け付けられていない！！
```

このように「3. `numPublisher` の出力」が受け付けられていないことがわかります。

## このことからわかること

- Combine ストリームは cancel() を受け付けた時点で出力を受け付けない

# 実験(2) `send(completion:)` の場合

`cancel()` ではなく Publisher の `send(completion:)` を行った場合にどうなるかを検証してみます。

## `send(completion: .finished)` の場合

```swift
// 1. `numPublisher` の出力
numPublisher.send(1)
numPublisher.send(2)

// 2. `numPublisher` の `send(completion:)`
numPublisher.send(completion: .finished)

// 3. `numPublisher` の出力
numPublisher.send(3)

// （出力）
// receiveRequest: 1
// receiveValue: 1
// receiveRequest: 2
// receiveValue: 2
// finished
↑
`numPublisher.send(3)` は受け付けられていない！！
```

`cancel()` と同様に「3. `numPublisher` の出力」が受け付けられていないことがわかります。

## `send(completion: .failure())` の場合

```swift
enum TestError: Error {
    case testError
}

// 1. `numPublisher` の出力
numPublisher.send(1)
numPublisher.send(2)

// 2. `numPublisher` の `send(completion:)`
numPublisher.send(completion: .failure(TestError.testError))

// 3. `numPublisher` の出力
numPublisher.send(3)

// （出力）
// receiveRequest: 1
// receiveValue: 1
// receiveRequest: 2
// receiveValue: 2
// failure: testError
↑
`numPublisher.send(3)` は受け付けられていない！！
```

こちらも `cancel()` と同様に「3. `numPublisher` の出力」が受け付けられていないことがわかります。

# まとめ

- Combine ストリームは `cancel()` や `send(completion:)` を受け付けた時点で出力を受け付けない

以上になります。
