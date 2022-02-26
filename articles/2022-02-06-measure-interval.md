---
title: "[Swift] [Combine] measureInterval(using:)を使って出力の間隔を取得する"
emoji: "🌾"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["Swift", "Combine"]
published: true
---

# `measureInterval(using:) `

Combine には [`measureInterval(using:)`](https://developer.apple.com/documentation/combine/fail/measureinterval(using:options:)) という Publisher の出力の間隔を取得することができる関数が用意されているのでそれを紹介してみたいと思います。

## サンプルコード

挙動はサンプルコードを見ていただくのが早いと思います。

まずは以下のような一定間隔で出力してくれる Publisher を用意します。

```swift
import Combine
import Foundation

var cancellables = Set<AnyCancellable>()
let timerPublisher = Timer.publish(every: 2, on: .main, in: .default)
    .autoconnect()
    .share()
```

適当に subscribe すると以下のような出力になります。

```swift
timerPublisher
    .sink { output in
        print("timerPublisher: \(output)")
    }
    .store(in: &cancellables)

// timerPublisher: 2022-02-05 11:14:17 +0000
// timerPublisher: 2022-02-05 11:14:19 +0000
// timerPublisher: 2022-02-05 11:14:21 +0000
```

ここで、[`measureInterval(using:)`](https://developer.apple.com/documentation/combine/fail/measureinterval(using:options:)) を間に噛ませると以下のようになります。

```swift
timerPublisher
    .measureInterval(using: RunLoop.main)
    .sink { output in
        print("measureInterval: \(output)")
    }
    .store(in: &cancellables)

// measureInterval: Stride(magnitude: 2.0009289979934692)
// measureInterval: Stride(magnitude: 1.9993009567260742)
// measureInterval: Stride(magnitude: 1.9998070001602173)
```

[`measureInterval(using:)`](https://developer.apple.com/documentation/combine/fail/measureinterval(using:options:)) を間に噛ませることで、`時刻` から `時間間隔` に変更されていることがわかります。


```swift
timerPublisher
    .measureInterval(using: RunLoop.main)
    .sink { output in
        print("measureInterval: \(output)")
    }
    .store(in: &cancellables)

// measureInterval: Stride(magnitude: 0.20106804370880127)
// measureInterval: Stride(magnitude: 0.1994309425354004)
// measureInterval: Stride(magnitude: 0.19979500770568848)

```

さらに [`collect()`](https://developer.apple.com/documentation/combine/fail/collect(_:)) を間に噛ませて、ちょっとした関数を当ててあげるだけで、出力の間隔の平均を表すこともできます。

```swift
func averageInterval(strides: [RunLoop.SchedulerTimeType.Stride]) -> Double {
    let sum = strides.map { $0.timeInterval }.reduce(0, +)
    return Double(sum) / Double(intervalValues.count)
}

timerPublisher
    .measureInterval(using: RunLoop.main)
    .collect(10)
    .map { averageInterval(strides: $0) }
    .sink { output in
        print("output average interval(s): \(output)")
    }
    .store(in: &cancellables)

// output average interval(s): 2.0000609040260313
```

以上になります。