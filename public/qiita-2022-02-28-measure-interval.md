---
title: "[Swift] [Combine] measureInterval(using:) の出力を Stride 型から秒単位に変換する"
tags:
  - "Swift"
private: false
updated_at: ''
id: 177306189ad7c38796c0
organization_url_name: null
slide: false
ignorePublish: false
---

# `measureInterval(using:)` の出力は `Stride` 型

出力してみるとわかるのですが、 [`measureInterval(using:)`](https://developer.apple.com/documentation/combine/fail/measureinterval(using:options:)) の出力は `Stride` 型になります。

しかも、なぜか、`Scheduler` によって、若干単位が異なります。

```swift
import Combine
import Foundation

var cancellables = Set<AnyCancellable>()
let timerPublisher = Timer.publish(every: 2, on: .main, in: .default)
    .autoconnect()
    .share()

timerPublisher
    .measureInterval(using: DispatchQueue.global(qos: .default))
    .sink { print("DispatchQueue.global: \($0)") }
    .store(in: &cancellables)

timerPublisher
    .measureInterval(using: DispatchQueue.main)
    .sink { print("DispatchQueue.main: \($0)") }
    .store(in: &cancellables)

timerPublisher
    .measureInterval(using: RunLoop.main)
    .sink { print("RunLoop.main: \($0)") }
    .store(in: &cancellables)

// （出力）
// DispatchQueue.main: Stride(_nanoseconds: 2000724683)
// RunLoop.main: Stride(magnitude: 2.0008790493011475)
// DispatchQueue.global: Stride(_nanoseconds: 2001722113)
// DispatchQueue.main: Stride(_nanoseconds: 1999310387)
// RunLoop.main: Stride(magnitude: 1.9990659952163696)
// DispatchQueue.global: Stride(_nanoseconds: 1999024983)
```

`DispatchQueue` は「ナノ秒」で、`RunLoop` は「秒」単位ですね。


# `Stride` → `Double`(秒) に変換する

以下のような、extension を生やしました。

```swift
extension DispatchQueue.SchedulerTimeType.Stride {
    var seconds: Double {
        Double(self.magnitude) / 1_000_000_000
    }
}

extension RunLoop.SchedulerTimeType.Stride {
    var seconds: Double {
        Double(self.magnitude)
    }
}
```

`map()` を使って変換してみました。

```swift
timerPublisher
    .measureInterval(using: DispatchQueue.global(qos: .default))
    .map { $0.seconds }
    .sink { print("DispatchQueue.global: \($0)") }
    .store(in: &cancellables)

timerPublisher
    .measureInterval(using: DispatchQueue.main)
    .map { $0.seconds }
    .sink { print("DispatchQueue.main: \($0)") }
    .store(in: &cancellables)

timerPublisher
    .measureInterval(using: RunLoop.main)
    .map { $0.seconds }
    .sink { print("RunLoop.main: \($0)") }
    .store(in: &cancellables)

// （出力）
// DispatchQueue.global: 2.000364776
// DispatchQueue.main: 2.000371132
// RunLoop.main: 2.000351905822754
// DispatchQueue.global: 1.999870186
// DispatchQueue.main: 1.999699733
// RunLoop.main: 1.9996449947357178
```

全部、秒単位の `Double` で揃いました。

（もっと簡単な方法があれば教えていただきです🙇‍♂️）

以上になります。
