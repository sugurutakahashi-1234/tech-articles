---
title: "【Swift】【Combine】ストリームに reduce() 処理の途中経過を流したい場合 -> scan() を使おう"
emoji: "🔖"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["Swift", "Combine"]
published: true
---

# reduce() の復習

[`reduce()`](https://developer.apple.com/documentation/swift/array/2298686-reduce) は以下のように、配列の数値を合計するときなどで使用されます。

```swift
let sum = [1, 2, 3, 4].reduce(0) { $0 + $1 }
print("sum: \(sum)") // sum: 10

```

この計算の過程を Combine のストリームで出力として流したい時に [`scan()`](https://developer.apple.com/documentation/combine/fail/scan(_:_:)) を使うと簡単に書くことができます。

# scan() を使ってみる

[`scan()`](https://developer.apple.com/documentation/combine/fail/scan(_:_:)) の使い方は [`reduce()`](https://developer.apple.com/documentation/swift/array/2298686-reduce) の使い方とかなり似ています。

以下が例になります。

```swift
var cancellables = Set<AnyCancellable>()

[1, 2, 3, 4].publisher
    .scan(0) { $0 + $1 }
    .sink {
        print("result: \($0)")
    } receiveValue: {
        print("output: \($0)")
    }
    .store(in: &cancellables)

// 出力
// output: 1 ← 0 + 1
// output: 3 ← 1 + 2
// output: 6 ← 3 + 3
// output: 10 ← 6 + 4
// result: finished
```

他に例を挙げると以下のようなこともできます。

```swift
[1, 2, 3, 4].publisher
    .scan([]) { $0 + [$1] }
    .sink {
        print("result: \($0)")
    } receiveValue: {
        print("output: \($0)")
    }
    .store(in: &cancellables)

// 出力
// output: [1]
// output: [1, 2]
// output: [1, 2, 3]
// output: [1, 2, 3, 4]
// result: finished
```

以上になります。