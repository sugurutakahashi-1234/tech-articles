---
title: '[Swift] [Combine] removeDuplicates で nil を含む場合の compactMap の位置について'
tags:
  - Swift
private: false
updated_at: '2023-11-15T20:50:30+09:00'
id: febd26ae7f3cc37c3e4b
organization_url_name: null
slide: false
ignorePublish: false
---

# はじめに

`removeDuplicates` で `nil` を含む配列を扱うときの `compactMap` の位置による挙動の違いというかなりマニアックな記事になります。

# removeDuplicates の基本的な挙動

`removeDuplicates` の基本的な挙動は以下の通りです。

```swift
import Combine

let nums: [Int] = [0, 0, 0, 0, 1, 2, 2, 3, 3, 3, 4, 4, 4, 4, 0]

let cancellable = nums.publisher
    .removeDuplicates()
    .sink {
        print("\($0)") // 0 1 2 3 4 0
    }
```

一つ前と連続してきた出力がきた場合に、その出力をなかったことにします。

# compactMap の位置による挙動の違い

`compactMap` の位置による挙動の違いは以下の通り。

```swift
import Combine

let nums: [Int?] = [0, nil, 0, nil, nil, 1, 2]

// removeDuplicates より先に compactMap する
let cancellableA = nums.publisher
    .compactMap { $0 } // [0, 0, 1, 2]
    .removeDuplicates() // [0, 1, 2]
    .sink {
        print("\($0)") // 0 1 2
    }

// removeDuplicates の後に compactMap する
let cancellableB = nums.publisher
    .removeDuplicates() // [0, nil, 0, nil, 1, 2]
    .compactMap { $0 } // [0, 0, 1, 2] 
    .sink {
        print("\($0)") // 0 0 1 2
    }
```

どちらが良いということではないですが、知っておかないと意図しない挙動が起こりかねないので、`compactMap` の位置には気をつけてましょう（戒め）
