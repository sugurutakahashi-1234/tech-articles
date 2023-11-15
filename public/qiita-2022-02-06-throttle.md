---
title: '[Swift] [Combine] throttle() で一定期間出力を無視する'
tags:
  - Swift
  - Combine
private: false
updated_at: '2023-11-15T20:50:30+09:00'
id: 0cef22fdc3991383e51e
organization_url_name: null
slide: false
ignorePublish: false
---

# `throttle(for:scheduler:latest:)`

Combine には [`throttle(for:scheduler:latest:)`](https://developer.apple.com/documentation/combine/fail/throttle(for:scheduler:latest:)) という一定期間の出力を無視してくれる関数が用意されていたので、それを紹介したいと思います。

スロットルはもともと以下のようなものらしいので、イメージにぴったりですね。

> スロットルは、ガソリンエンジンなどの予混合燃焼機関では、エンジンへの吸気（空気あるいは混合気）の流入量を調整し、エンジンの出力を調節する弁である。

[出典: フリー百科事典『ウィキペディア（Wikipedia）』スロットル](https://ja.wikipedia.org/wiki/%E3%82%B9%E3%83%AD%E3%83%83%E3%83%88%E3%83%AB)


## サンプルコード

挙動は以下のサンプルコードを見ていただくのが早いと思います。

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
    .sink {
        print("output: \($0)")
    }
    .store(in: &cancellables)

//output: 2022-02-05 11:44:08 +0000
//output: 2022-02-05 11:44:10 +0000
//output: 2022-02-05 11:44:12 +0000
```

ここに [`throttle(for:scheduler:latest:)`](https://developer.apple.com/documentation/combine/fail/throttle(for:scheduler:latest:)) を間に噛ませていきます。

```swift
timerPublisher
    .throttle(for: .seconds(5), scheduler: DispatchQueue.main, latest: true)
    .sink {
        print("output: \($0)")
    }
    .store(in: &cancellables)

// output: 2022-02-05 12:15:18 +0000
// output: 2022-02-05 12:15:22 +0000
// output: 2022-02-05 12:15:28 +0000
```

出力からは分かりにくいのですが、出力が 5 秒間隔になって、流量がコントロールされていることがわかります。

使い所としては、ボタンの連打など、あまり連続で処理させたくないところで使ってあげるとよさそうです。

以上になります。
