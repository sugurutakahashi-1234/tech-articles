---
title: "[Swift] struct は deinit を記述できない件"
tags:
  - "Swift"
private: false
updated_at: ''
id: 999f8e3b80205c8aa18b
organization_url_name: null
slide: false
ignorePublish: false
---

# 伝えたいこと

- struct は deinit を記述できない

# 実験

```swift
struct Hoge {
    let moge: Int
    
    deinit { // ❌ Deinitializers may only be declared within a class or actor
        print("deinit: \(type(of: self))")
    }
}
```

エラーメッセージ↓

> Deinitializers may only be declared within a class or actor

だそうです。知らなかった。。。

以上です。
